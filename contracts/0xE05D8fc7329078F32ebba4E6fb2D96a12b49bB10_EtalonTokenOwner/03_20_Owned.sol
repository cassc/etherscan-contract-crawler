// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.7;

// gives the owner rights
contract Owned {
    address _Owner;

    constructor() {
        _Owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _Owner, "Only owner can call this function.");
        _;
    }

    // shows Owner 
    // if 0 then there is no Owner
    // Owner is needed only to set up the token
    function GetOwner() public view returns (address) {
        return _Owner;
    }

    // sets new Owner
    // if Owner set to 0 then there is no more Owner
    function SetOwner(address newOwner) public onlyOwner {
        _Owner = newOwner;
    }
}