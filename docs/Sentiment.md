# Sentiment

## Amount stolen
**$1M USD**

March 3,2023

## Vulnerability
Read-Only-Reentrancy

## Analysis
The attacker exploited read-only reentrancy to borrow additional tokens before the collateral was updated, this allowed the user to borrow tokens at a discounted value, and gain a profit.

The function had a nonReentrant modifier which doesn't allow the function to be called again, which is great to be protected against reentrance, but nothing prevents the malicious user from making another call to another contract which reads the state of this contract. 

The vulnerability occurs when you join or exit a pool and it will call `_callPoolBalanceChange` to return the balance. Before the values are updated, the attacker exploits this window by borrowing additional tokens at the manipulated price caused by making an external call from the fallback function to the contract that reads the collateral amount, at the temporal state which is in this case a bigger amount of collateral tokens. This allows the exploiter to take advantage of the temporarily distorted state of the pool, profiting from the price differential.


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

# Proof of concept (PoC) 

Attacker flashloaned 606 WBTC,10_000 ETH and 18 million USDC tokens the from sentiments lending pool

## Join pool

The attacker starts the attack by joining the pool and depositing the flash-loaned tokens.


## Exit pool
After successfully joining the pool, the attacker can execute the `exitPool` function to withdraw their liquidity. However, instead of completing a straightforward withdrawal, the attacker leverages the fallback function of the `exitPool` to borrow additional tokens.

## Borrow all

The `borrowAll` function is then triggered, calculating the price based on the current values of the incomplete `exitPool` function within the pool. 

![euler Image](../images/sentiment/Sentiment2.drawio.png)


The key advantage lies in the ability to borrow additional tokens at a lower price. This advantageous pricing is made possible by utilizing the collateral price, which, at this point, is significantly higher. By capitalizing on the dynamic changes in collateral prices, the attacker maximizes their gains, obtaining more tokens than would be possible under regular circumstances.

## Return Exit Pool

Finally, the attacker transfers the profits obtained from this manipulation back to their contract.

![euler Image](../images/sentiment/Sentiment1.drawio.png)


**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
