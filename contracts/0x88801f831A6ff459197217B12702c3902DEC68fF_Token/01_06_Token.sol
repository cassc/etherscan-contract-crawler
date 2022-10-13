// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {
    uint constant cDecimal = 1000000;
    uint constant fee = 50000;
    address public feeAddress;
    uint public price = 1000000;

    constructor(
        string memory name,
        string memory symbol,
        uint initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        feeAddress = msg.sender;
    }

    function setFeeAddress(address _newAddress) external onlyOwner {
        feeAddress = _newAddress;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint feeAmount = (amount * fee) / cDecimal;
        if ((feeAmount * price) / cDecimal / 10**18 > 100) {
            feeAmount = (100 * 10**18 * cDecimal) / price;
        }
        super._transfer(from, to, amount - feeAmount);
        super._transfer(from, feeAddress, feeAmount);
    }
}