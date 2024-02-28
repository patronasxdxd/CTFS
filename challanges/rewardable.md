## Reward.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Rewardable.sol";

contract Reward is Owned {

        Rewardable public rewardable;
        bool public isCompleted;

        constructor(address payable _address) Owned(msg.sender) {
            rewardable =  Rewardable(_address);
        }
        
        function completeChallange(address _addr) external {

            require(rewardable.getTotalAmountForUSDT(_addr) == 10 ether);
            require(rewardable.getTotalAmountForKDG(_addr) == 10 ether);
            console.log("challange completed");
            isCompleted = true;
        }
}
```

## Rewardable.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "solmate/src/auth/Owned.sol";

contract Rewardable is Owned {
    bool internal locked;
    mapping (address => uint256) public userBalanceUSDTTokens;
    mapping (address => uint256) public userBalanceKDGTokens;

    modifier noReetrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() Owned(msg.sender) {}


    function depositKDG() external payable {
        userBalanceUSDTTokens[msg.sender] += msg.value;
    }

   function depositUSDT() external payable {
        userBalanceKDGTokens[msg.sender] += msg.value;
    }

    function withdrawThatCannotBeReentered() public noReetrant {

        uint256 totalAmount = userBalanceKDGTokens[msg.sender] + userBalanceUSDTTokens[msg.sender];

        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "failed to send ether"); 

        userBalanceKDGTokens[msg.sender] = 0;
        userBalanceUSDTTokens[msg.sender] = 0;
    }

    function getTotalAmountForKDG(address _addr) external view returns (uint256) {
        return userBalanceKDGTokens[_addr];
    }

    function getTotalAmountForUSDT(address _addr) external view returns (uint256) {
        return userBalanceUSDTTokens[_addr];
    }

    receive() external payable {}

}
```

[**< Show Solution >**](https://patronasxdxd.github.io/CTFS/challanges/rewardableSolution)
[**< Back >**](https://patronasxdxd.github.io/CTFS/)

