// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract ETHPayment is Pausable, Ownable {
    using SafeMath for uint256;
    uint256 public price = 1000000000000000000;

    constructor() {
    }

    event ETHTransferSuccess(address indexed fromAddress, address indexed toAddress, uint256 indexed amount, address tokenAddress, bytes data);

    //******SET UP******
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function airdrop(
        address[] memory _address,
        uint256 _amount
    ) external onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            payable(_address[i]).transfer(_amount);
            emit ETHTransferSuccess(address(this), msg.sender, _amount, address(0x0), bytes("Airdrop"));
        }
    }

    //******FUNCTIONS******
    function pay() external payable whenNotPaused {
        require(msg.value >= price, "insufficient value");
        emit ETHTransferSuccess(msg.sender, address(this), price, address(0x0), bytes("Payment"));
    }
}