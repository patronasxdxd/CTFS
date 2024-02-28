# Shop

## Vulnerability

Overflow

## Analysis

The contract was exploited by overflow that occurred in purchaseItem, The mechanism of overflow involves the binary representation of numbers. Consider a uint8, where the binary representation of 255 is 1111 1111. Adding 1 to it transforms the binary to 0000 0000, equivalent to 0 in decimal.

So, if `purchaseItem` is called, and quantity is 9930, multiplying the amount with the price of the item will cause overflow because they are both uint16, wich is capped at 65535. Overflow occurs when the product of the quantity and price exceeds the maximum representable value for the data type, So in our case we are able to buy alot for a low price.


### Exploited code

```solidity
     function purchaseItem(uint8 itemId, uint16 quantity) external payable {
        ClothingItem storage item = clothingItems[itemId];
        require(item.quantity >= quantity, "Not enough quantity available");
        
        //exploit here
        uint256 totalPrice = item.price * quantity;
        ....
    }
```

# proof of concept (PoC) 

We can simply call the `purschaseItem` function to buy items, Item one cost $99 USD, so if uint16 is capped at 65535, we can devide that by the price 99, and it would be 662, but this would profit 65 thousand, but we need 100_000, so we can simply add twice the amount so we buy 1324 for a total profil of $131076 USD, for only $4 USD.

Logs:
```
    Total Price: 4
    Buyer's Balance: 10000
    Transaction Successful. Owner's Balance: 9970
         ✔ Execution
    Total Value of Owned Items: BigNumber { value: "131076" }
```

# Summary

Overflows are extremely common in smart contracts and they should be prevented by the safemath library 
especially in methods involving transactions, to safeguard against overflows. While it may introduce 
additional gas costs, the security benefits far outweigh the risks associated with potential vulnerabilities 


