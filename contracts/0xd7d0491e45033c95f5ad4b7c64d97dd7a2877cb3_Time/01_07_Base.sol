// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Time is ERC20, ERC20Burnable, Ownable {
    uint256 public constant feePercent = 3; // Hard-coded, unchangeable fee

    constructor() ERC20("Time", "Time") {
        uint256 initialSupply = 100000000 * 10**decimals();
        _mint(_msgSender(), initialSupply);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = calculateFee(amount);
        uint256 amountMinusFee = amount - feeAmount;
        _transfer(_msgSender(), owner(), feeAmount);
        return super.transfer(recipient, amountMinusFee);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = calculateFee(amount);
        uint256 amountMinusFee = amount - feeAmount;
        _transfer(sender, owner(), feeAmount);
        return super.transferFrom(sender, recipient, amountMinusFee);
    }

    function calculateFee(uint256 amount) public pure returns (uint256) {
        return (amount * feePercent) / 100;
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }
}