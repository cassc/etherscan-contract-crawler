// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SigmaToken is ERC20, Ownable {
    uint256 public transferTaxRate = 100; // 100 basis points = 1%

    constructor() ERC20("SigmaToken", "SGM") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount * transferTaxRate / 10000;
        uint256 sendAmount = amount - taxAmount;
        super.transfer(recipient, sendAmount);
        super.transfer(owner(), taxAmount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount * transferTaxRate / 10000;
        uint256 sendAmount = amount - taxAmount;
        super.transferFrom(sender, recipient, sendAmount);
        super.transferFrom(sender, owner(), taxAmount);
        return true;
    }

    function setTransferTaxRate(uint256 newRate) public onlyOwner {
        transferTaxRate = newRate;
    }
}