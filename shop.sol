// SPDX-License-Identifier: GPL-3.0
// overflow
pragma solidity >=0.6.0;
import "hardhat/console.sol";

contract CTF1 {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(uint8 => uint256)) public ownedItems; // Mapping buyer's address to owned items
    mapping(uint8 => ClothingItem) public clothingItems;

    struct ClothingItem {
        string name;
        uint8 price;
        uint8 quantity;
    }

    event Purchase(address indexed buyer, uint256 itemId, uint256 quantity);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function addItem(uint8 itemId, string memory name, uint8 price, uint8 quantity) public onlyOwner {
        clothingItems[itemId] = ClothingItem(name, price, quantity);
    }

    constructor() public {
        owner = msg.sender;
        balances[owner] += 999999;
        addItem(1, "Sample Item", 50, 255);
    }

    function purchaseItem(uint8 itemId, uint8 quantity) external payable {
        ClothingItem storage item = clothingItems[itemId];
        require(item.quantity >= quantity, "Not enough quantity available");
        
        uint256 totalPrice = item.price * quantity;

        console.log("Buyer's Balance:", balances[msg.sender]);
        console.log("Total Price:", totalPrice);

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
}


