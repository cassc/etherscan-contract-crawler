// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;
    mapping(address => bool) private _bots;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BotAddressAdded(address indexed botAddress);
    event BotAddressRemoved(address indexed botAddress);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function addBotAddress(address botAddress) public onlyOwner {
        require(!_bots[botAddress], "Ownable: address is already a bot");
        _bots[botAddress] = true;
        emit BotAddressAdded(botAddress);
    }

    function removeBotAddress(address botAddress) public onlyOwner {
        require(_bots[botAddress], "Ownable: address is not a bot");
        _bots[botAddress] = false;
        emit BotAddressRemoved(botAddress);
    }

    function isBotAddress(address account) public view returns (bool) {
        return _bots[account];
    }
}