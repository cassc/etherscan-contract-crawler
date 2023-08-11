/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

pragma solidity 0.5.16;

contract Counter {
    address private   _owner;

    constructor() public {
        _owner = msg.sender;
    }
    
    function getAddress() public view returns (address) {
        return _owner;
    }

}