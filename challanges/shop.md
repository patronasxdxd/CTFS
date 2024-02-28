```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
import "hardhat/console.sol";
contract Shop {

    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(uint8 => uint256)) public ownedItems; // Mapping buyer's address to owned items
    mapping(uint8 => ClothingItem) public clothingItems;

    struct ClothingItem {
        string name;
        uint16 price; 
        uint16 quantity;
    }


    event Purchase(address indexed buyer, uint256 itemId, uint256 quantity);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function addItem(uint8 itemId, string memory name, uint16 price, uint16 quantity) public onlyOwner {
        clothingItems[itemId] = ClothingItem(name, price, quantity);
    }

    constructor() public {
        owner = msg.sender;
        balances[owner] += 10_000;
        addItem(1, "Sample Item", 99, 10000);
    }

    function purchaseItem(uint8 itemId, uint16 quantity) external payable {
        ClothingItem storage item = clothingItems[itemId];
        require(item.quantity >= quantity, "Not enough quantity available");
        
        uint256 totalPrice = item.price * quantity;
        console.log("Total Price:", totalPrice);

        console.log("Buyer's Balance:", balances[msg.sender]);
        require(balances[msg.sender] >= totalPrice, "Insufficient funds");

        ownedItems[msg.sender][itemId] += quantity;

        item.quantity -= quantity;
        balances[msg.sender] -= totalPrice;
        emit Purchase(msg.sender, itemId, quantity);

        console.log("Transaction Successful. Owner's Balance:", balances[owner]);
    }

    function withdrawFunds() external onlyOwner {
        require(balances[owner] > 0, "No funds available for withdrawal");
        payable(owner).transfer(balances[owner]);
        balances[owner] = 0;
    }


     function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    
    function getOwnedItemsValue() external view returns (uint256 totalValue) {
        uint256 numItems = 4;  

        for (uint8 itemId = 1; itemId <= numItems; itemId++) {
            totalValue += ownedItems[msg.sender][itemId] * clothingItems[itemId].price;
        }

        return totalValue;
    }

}
```

[**< Show Solution >**](https://patronasxdxd.github.io/CTFS/challanges/shopSolution)


[**< Back >**](https://patronasxdxd.github.io/CTFS/)

