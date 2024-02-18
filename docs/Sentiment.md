# Sentiment


## What's [Title]?


## Amount stolen
**$1M USD**

March 3,2023

## Vulnerability
Read-Only-Reentrancy

Balancer integration


## Analysis
Attacker used view re-entrance Balancer bug to execute malicious code before pool balances were updated and steal money using overpriced collateral

Reentrant attacks in read-only mode occur when a view function is initially called and later reentered by another function that alters the contract's state.
This vulnerability can be exploited by manipulating the values used in functions dependent on the returned results, leading to potential rate manipulation or incorrect parsing.


In order to join the pool you call the function `Balancer.joinPool{value: 0.001 ether}(PoolId, address(this), address(this), joinPoolRequest_2);` with the respected parameters, 
also sending either asmassage value bnecause creating an account cost some ether. 

But before we called this function there funciton was excuted wihtin the same flashloan but slightly different.
Firstly an acccount was created `account = AccountManager.openAccount(address(this));` paying the slight free, than 50 WETH was deposited into it using `deposit`,
Using a JoinPoolrequest, there was 

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
        // This function uses a large number of stack variables (poolId, sender and recipient, balances, amounts, fees,
        // etc.), which leads to 'stack too deep' issues. It relies on private functions with seemingly arbitrary
        // interfaces to work around this limitation.

        InputHelpers.ensureInputLengthMatch(change.assets.length, change.limits.length);

        // We first check that the caller passed the Pool's registered tokens in the correct order, and retrieve the
        // current balance for each.
        IERC20[] memory tokens = _translateToIERC20(change.assets);
        bytes32[] memory balances = _validateTokensAndGetBalances(poolId, tokens);

        // The bulk of the work is done here: the corresponding Pool hook is called, its final balances are computed,
        // assets are transferred, and fees are paid.
        (
            bytes32[] memory finalBalances,
            uint256[] memory amountsInOrOut,
            uint256[] memory paidProtocolSwapFeeAmounts
        ) = _callPoolBalanceChange(kind, poolId, sender, recipient, change, balances);

        // All that remains is storing the new Pool balances.
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _setTwoTokenPoolCashBalances(poolId, tokens[0], finalBalances[0], tokens[1], finalBalances[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _setMinimalSwapInfoPoolBalances(poolId, tokens, finalBalances);
        } else {
            // PoolSpecialization.GENERAL
            _setGeneralPoolBalances(poolId, finalBalances);
        }

        bool positive = kind == PoolBalanceChangeKind.JOIN; // Amounts in are positive, out are negative
        emit PoolBalanceChanged(
            poolId,
            sender,
            tokens,
            // We can unsafely cast to int256 because balances are actually stored as uint112
            _unsafeCastToInt256(amountsInOrOut, positive),
            paidProtocolSwapFeeAmounts
        );
    }
```

# proof of concept (PoC) 

Entry point: _joinOrExit

Whats `_joinOrExit?`

`_joinOrExit` function is called whenever the `joinPool` or `exitPool`





![euler Image](../images/euler/euler.png)


**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
