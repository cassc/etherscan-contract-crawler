// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrossChainDEX is Ownable,Pausable {

    uint256 private transfer_rate;
    address private sender_wallet;

    event Bought(address indexed buyer,uint256 amount);

    IERC20 private USDT;

    constructor(address _sender_wallet,uint256 _rate,IERC20 _usdt_address) {
        sender_wallet = _sender_wallet;
        transfer_rate = _rate;
        USDT = _usdt_address;
    }


    function setTransferRate(uint256 rate) public onlyOwner {
        transfer_rate = rate;
    }

    function getTransferRate() public view returns (uint) {
        return transfer_rate;
    }

    function setSenderWallet(address rate) public onlyOwner {
        sender_wallet = rate;
    }

    function getSenderWallet() public view returns (address) {
        return sender_wallet;
    }


    function buy(uint256 amount) public whenNotPaused {
        uint256 usdt_amount = amount;
        uint256 ghost_amount = amount * transfer_rate * 10 ** 12;
        USDT.transferFrom(msg.sender,sender_wallet,usdt_amount);
        emit Bought(msg.sender,ghost_amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}