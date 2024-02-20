# BH


## What's BH?


## Amount stolen
**$1.27M USD**

October 11,2023

## Vulnerability

Price manipulation


## Analysis



### Exploited code

```solidity
   code here
```

# proof of concept (PoC) 

Before the exploitation, the liquidity removal ratio was 1 `$USDT` to 100 `$BH` tokens.


![bh Image](../images/bh/BH2.drawio.png)

The attacker flash loaned a humongous amount of `$USDT` tokens from multiple sources.

![bh Image](../images/bh/BH1.drawio.png)

Following a successful flash loan:
- the attacker Swapped 10 million `$USDT` for WBNB from WBNB_BUSDT;
- the attacker Flashloaned an additional 15 million `$USDT from BUSDT_USDC`
- the attacker Swapped(15 million `$USDT` for `BH` causing the liquidity removal ratio to change in favor of the attacker.

![bh Image](../images/bh/BH3.drawio.png)





**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
