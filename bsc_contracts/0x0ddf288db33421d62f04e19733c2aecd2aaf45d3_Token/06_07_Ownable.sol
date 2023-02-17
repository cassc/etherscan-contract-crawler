//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Ownable {
    address private _owner;

    constructor()
    {
        _setOwner(address(1));
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner());
        _;
    }

    function owner() view public returns(address)
    {
        return _owner;
    }

    function changeOwner(address newOwner) external onlyOwner
    {
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal
    {
        _owner = newOwner;
    }
}