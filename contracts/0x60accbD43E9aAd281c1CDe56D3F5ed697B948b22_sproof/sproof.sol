/**
 *Submitted for verification at Etherscan.io on 2019-10-08
*/

pragma solidity ^0.5.9;
contract sproof {
    event lockHashEvent(address indexed from, bytes32 indexed hash);
    
    address payable owner;


    mapping(address => bool) sproofAccounts;

    uint  costToLockHash = 0;

    constructor() public {
        owner = msg.sender;
    }

    function addSproofAccount(address _addr) public{
        require(msg.sender == owner);
        sproofAccounts[_addr] = true;
    }
    
      function updateOwner(address payable newOwner) public{
        require(msg.sender == owner);
        owner = newOwner;
    }
    
     function removeSproofAccount(address _addr) public{
        require(msg.sender == owner);
        sproofAccounts[_addr] = false;
    }


    function setCost (uint newCostToLockHash) public {
        require (msg.sender == owner);
        costToLockHash = newCostToLockHash;
    }
    
   function getCost() public view returns(uint)  {
        return costToLockHash;
    }

    function lockHash(bytes32 hash) public payable{
        if(sproofAccounts[msg.sender] != true)
            require(msg.value >= costToLockHash);
        emit lockHashEvent(msg.sender, hash);
    }
    
    
    function lockHashProxy(address _addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public payable {
        require(ecrecover(hash, v, r, s) == _addr);
        if (sproofAccounts[msg.sender] != true)
            require(msg.value >= costToLockHash);
        emit lockHashEvent(_addr, hash);
    }
 
    function lockHashesProxy(address [] memory _addresses, bytes32 [] memory hashes, uint8[] memory vs, bytes32 [] memory rs, bytes32 [] memory ss) public payable {

        if (sproofAccounts[msg.sender] != true)
            require(msg.value >= _addresses.length*costToLockHash);

        for (uint i=0; i < _addresses.length; i++) {
            require(ecrecover(hashes[i], vs[i], rs[i], ss[i]) == _addresses[i]);
            emit lockHashEvent(_addresses[i], hashes[i]);
        }
    }

    function payout() public{
        require (msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}