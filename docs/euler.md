Euler

## What's [Title]?


## Amount stolen



## Vulnerability



## Analysis



### Exploited code

```solidity
   code here
```

# proof of concept (PoC) 
![euler Image](../images/euler/euler.png)

## Stage 1

| Variable      | Calculation                               |
|---------------|-------------------------------------------|
| `x`           | 10,000,000                                |
| `flashAmount` | x * 3                                   |
| `mintAmount`  | x * 2 * 10                              |
| `donateAmount`| x * 10                                  |
| `maxWithdraw` | (x * 3 * 9 * 2) / 10 - x                |


`takeFlashLoan(provider, address(token), flashAmount * 10 ** token.decimals());`



  [*] Attacking DAI...
  
  [*] Euler balance before exploit: 8904507 DAI
  
  [*] Borrowing 30000000 DAI

![euler Image](../images/euler/euler2.png)

## Stage 2

In this stage we create the violator contract and transfer money to Violator contract by using the `transfer` function with the parameters given before.
Afterwards we can call the `violator` function of the contract to make our first `deposit` of 2/3 of our flashloaned amount and send 20 million to the pool to receive 19.5M eDAI from Euler

![euler Image](../images/euler/euler3.png)

## Stage 3

We will mind 10 times the amount of our deposited amount using `mint()`, an equivalent of 195.6M eDAI and 200M dDAI from euler

![euler Image](../images/euler/euler4.png)

## Stage 4

We will repay part of the debt using the remaining 1/3 of funds using `repay()', an equivalent of 10M DAI, Euler will burn 10M dDai


![euler Image](../images/euler/euler5.png)

## Stage 5

When we donate the 10 tunes the amnount of our repaid funds to `donateToReserves()`, an equivalant of 100M eDAI to euler it will leave our health facor below 1.

![euler Image](../images/euler/euler6.png)

## Stage 6

![euler Image](../images/euler/euler7.png)

![euler Image](../images/euler/euler8.png)




**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
