# Umbrella


## What's Umbrella?


## Amount stolen
**$700k USD**



## Vulnerability
Underflow


## Analysis



### Exploited code

```solidity
      function _withdraw(uint256 amount, address user, address recipient) internal nonReentrant updateReward(user) {
        require(amount != 0, "Cannot withdraw 0");

        // not using safe math, because there is no way to overflow if stake tokens not overflow
        _totalSupply = _totalSupply - amount;
        _balances[user] = _balances[user] - amount;   //<---- underflow here.
      }
```

# proof of concept (PoC) 




# Solution

The method `_withdraw` should check wether the user has enough balance, and/or to prevent underflow it can use the `safe math` library using `.sub` instead of a `-` sign

```solidity
  function _withdraw(uint256 amount, address user, address recipient) internal nonReentrant {
        require(amount != 0, "Cannot withdraw 0");
        require(_balances[user] >= amount, "Insufficient balance for withdrawal");

        // Use safe math to prevent underflow
        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);
    }

```


# Summary

Underflows are extremely common in smart contracts and they should be prevented by the safemath library 
especially in methods involving transactions, to safeguard against underflows. While it may introduce 
additional gas costs, the security benefits far outweigh the risks associated with potential vulnerabilities 

![euler Image](../images/euler/euler.png)


**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
