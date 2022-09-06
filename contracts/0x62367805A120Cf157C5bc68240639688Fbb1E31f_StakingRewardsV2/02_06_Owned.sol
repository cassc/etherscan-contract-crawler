// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;

    constructor(address _owner)  {
        require(_owner != address(0), "400: invalid owner");
        owner = _owner;
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "401: not owner");
    }
}