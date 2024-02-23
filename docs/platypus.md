# Platypus Finance


## What's Platypus Finance?
Platypus Finance is a single-sided Automatic Market Maker (AMM) for stablecoins built on the Avalanche network that is designed to optimize capital efficiency

## Amount stolen
**$8.5 Million USD **

February 16, 2023  


## Vulnerability



## Analysis

The `emergencyWithdraw` function in the `MasterPlatypus` contract allows a user to withdraw
their LP tokens from a given pool without caring about rewards.

```solidity
     function emergencyWithdraw(uint256 _pid) public nonReentrant {
       PoolInfo storage pool = poolInfo[_pid];
       UserInfo storage user = userInfo[_pid][msg.sender];


       if (address(platypusTreasure) != address(0x00)) {
           (bool isSolvent, ) = platypusTreasure.isSolvent(msg.sender, address(poolInfo[_pid].lpToken), true);
           require(isSolvent, 'remaining amount exceeds collateral factor');
       }


       // reset rewarder before we update lpSupply and sumOfFactors
       IBoostedMultiRewarder rewarder = pool.rewarder;
       if (address(rewarder) != address(0)) {
           rewarder.onPtpReward(msg.sender, user.amount, 0, user.factor, 0);
       }


       // SafeERC20 is not needed as Asset will revert if transfer fails
       pool.lpToken.transfer(address(msg.sender), user.amount);


       // update non-dialuting factor
       pool.sumOfFactors -= user.factor;


       user.amount = 0;
       user.factor = 0;
       user.rewardDebt = 0;


       emit EmergencyWithdraw(msg.sender, _pid, user.amount);
   }
```

The only check done by this function is whether the user is solvent or not, 
using `PlatypusTreasure.isSolvent`. That function uses an internal function called `_isSolvent`. 


```solidity
    function _isSolvent(
       address _user,
       ERC20 _token,
       bool _open
   ) internal view returns (bool solvent, uint256 debtAmount) {
       uint256 debtShare = userPositions[_token][_user].debtShare;


       // fast path
       if (debtShare == 0) return (true, 0);


       // totalDebtShare > 0 as debtShare is non-zero
       debtAmount = (debtShare * (
      totalDebtAmount + _interestSinceLastAccrue())) / totalDebtShare;
      solvent = debtAmount <= (
             _open ? _borrowLimitUSP(_user, _token) : _liquidateLimitUSP(_user, _token));
   }
```

The underlying mechanism of this check involves the utilization of an internal function 
named `_isSolvent`. The boolean variable returned by this function is true when the user's debt is less than or equal to its USP borrow limit. 
Essentially, a user is considered solvent if their collateral is sufficient to cover their debt. It's crucial to note that withdrawing collateral 
must not result in any outstanding debt. The `emergencyWithdraw` function allows users with debt to withdraw all collateral 
LP tokens without settling the previously borrowed USP associated with that collateral, thereby leaving the protocol in a state of indebtedness.

In many decentralized finance (DeFi) protocols, it is typical for a liquidity pool to automatically repay 
a user's debt when they withdraw their funds. This mechanism ensures that users cannot withdraw their collateral without
settling any outstanding debt they might have incurred while using the protocol.


# proof of concept (PoC) 

![euler Image](../images/platypus.drawio.png)


1. `Flashloan` 44 Million USDC from Aave
2. `Deposit` the borrowed USDC into the `platypus` pool to get LP tokens
3. Receive LP tokens
4. `Deposit` LP tokens to the `masterPlatypus` contract as **collateral**
5. `Borrow` as much USP as possible against the LP collateral
6. Execute `emergencyWithdraw` to get the LP collateral back without paying debt
   




**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
