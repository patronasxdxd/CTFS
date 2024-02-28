```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "solmate/src/auth/Owned.sol";
import "hardhat/console.sol";

contract Bank is Owned {

    mapping(address => uint256) public balances;

    constructor() Owned(msg.sender){
    }


    function withdrawAll() external payable {
        // Check if the user has any balance
        require(balances[msg.sender] > 0, "No balance to withdraw");

        uint256 userBalance = balances[msg.sender];

        (bool success, ) = msg.sender.call{value: userBalance}("");
        require(success, "failed to send ether"); 

        //if succesful remove user credits
        balances[msg.sender] = 0;
    }

   receive() external payable {}

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
}
```
[**< Show Solution >**](https://patronasxdxd.github.io/CTFS/challanges/bankSolution)

[**< Back >**](https://patronasxdxd.github.io/CTFS/)

