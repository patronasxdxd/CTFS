# Rewardable

## Vulnerability
Read-Only Reetrancy


## Analysis

A user starts with 10 ether, 
The challange is solved when a user has 10 ether worth of KDG tokens and 10 ether worth of USDT tokens and calls the `challangeComplete` function. 

The attacker exploited read-only reentrancy to borrow additional tokens before the amounts are updated, this allowed the user to complete the challange with only 10 ether.

The function `withdrawThatCannotBeReentered` had a `nonReentrant` modifier which doesn’t allow the function to be called again, which is great to be protected against reentrance, but nothing prevents the malicious user from making another call to another contract which reads the state of this contract.

### Exploited code

```solidity
   function withdrawThatCannotBeReentered() public noReetrant {

        uint256 totalAmount = userBalanceKDGTokens[msg.sender] + userBalanceUSDTTokens[msg.sender];

        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "failed to send ether"); 

        userBalanceKDGTokens[msg.sender] = 0;
        userBalanceUSDTTokens[msg.sender] = 0;
    }
```

```solidity
     function completeChallange(address _addr) external {

            require(rewardable.getTotalAmountForUSDT(_addr) == 10 ether);
            require(rewardable.getTotalAmountForKDG(_addr) == 10 ether);
            console.log("challange completed");
            isCompleted = true;
      }
```

# proof of concept (PoC) 

![rewardable Image](./challangeImages/rewardable.drawio.png)


    - The user initiates a deposit of 10 ether into the attack contract.
    - Subsequently, the attack contract triggers the `depositKdg` function on the reward contract, transferring 10 ether.
    - Following that, the attack contract invokes the `withdrawAll` function on the reward contract to retrieve all KDG tokens.
    - The `receive` function, in turn, executes the `depositUSDT` function on the reward contract, depositing 10 ether to acquire USDT tokens.
    - Additionally, the `receive` function calls the `completeChallenge` function on the Reward contract.
    - This process involves two method invocations on the reward contract, retrieving both USDT and KDG amounts.
    - Successfully completed challenges.


## Flow

The user `deposit` KDG tokens to the contract

![rewardable Image](./challangeImages/rewardable2.drawio.png)

After the `withdraw` funciton is triggered, the attacker deposit `USDT` to the same contract. Because the reentrant function isn't finished yet, the amount/state is not updated to 0 for kdg tokens. 

![rewardable Image](./challangeImages/rewardable3.drawio.png)


## Prevent read-only reentrancy

You can prevent this by making a call to any other functions besides the function that has a reentrant guard, if the function fails it will indicate that the nonreetrant function is active and you shouldn’t read the state of the contract. If it doesn’t fail you can safely call the function to get the state of that contract.


