# [Title]


## What's [Title]?


## Amount stolen



## Vulnerability



## Analysis



# proof of concept (PoC) ❗


- The exploiter leverages the lack of parameter checks to create a fake market, exploiting its usability instead of a legitimate market.

- The exploiter repeats the first step 16 times, resulting in a list of fake markets.

- The first 8 markets are set as victims, addreses of the victims are used within that FakeMarket contract to handle actions.



![euler Image](../images/exactly/exactly4.drawio.png)

- In the permit function, the address is changed into the address of the victim so the msg sender is overwritten;

- Now the 8 victims use the leverage function, this will invoke the noTransferLeverage to deposit, but since we gave a fake market place it will execute the deposit function that is on the fake market , we can alter that function.

- In that fake market `deposit()` function, we trigger the crossDelevage(), which swapper tokens from the position to fake token of the attacker.



![euler Image](../images/exactly/exactly5.drawio.png)

`IERC20PermitUpgradeable(address(token)).safePermit(p.account, address(this), assets, p.deadline, p.v, p.r, p.s);`


the line is calling a permit function on an ERC-20 token contract, 
enabling the contract to interact with the token on behalf of the user 
by using a permit instead of a traditional approval. This can be more gas-efficient 
in some scenarios, especially in DeFi protocols where multiple interactions with tokens are common.



![euler Image](../images/exactly/exactly7.drawio.png)


6.  Removed liquidity from the Uniswap pool gaining profit.


* Finally, the hacker has liquidated position of the victim, and tries to call leverage on the position in order to manipulate it even further.




**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)


