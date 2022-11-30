//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../Member.sol";

contract Vistor is Member {

    mapping(address => bool) private visitors;
    
    event UpdateVistor(address indexed visitor, bool allow);

    modifier onlyVistor {
        require(visitors[msg.sender], "not vistor allow");
        _;
    }

    function setVistor(address _addr, bool _allow) external {
        require(manager.members("gov") == msg.sender, 'only gov');
        visitors[_addr] = _allow;
        emit UpdateVistor(_addr, _allow);
    }
    
    function allow(address _addr) external view returns(bool) {
        return visitors[_addr];
    }
    
}