// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerluzoCoin is ERC20, ERC20Burnable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 70000000000 * 10**18;
    uint256 public maxTransferAmount;

    constructor() ERC20("MerluzoCoin", "MERLUZO") {
        _mint(msg.sender, INITIAL_SUPPLY);
        maxTransferAmount = INITIAL_SUPPLY / 200; // 0.5% of the total supply
    }

    function distributeTokens(address distributionWallet) external onlyOwner {
        uint256 supply = balanceOf(msg.sender);
        require(supply == INITIAL_SUPPLY, "Tokens already distributed");

        _transfer(msg.sender, distributionWallet, supply);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= maxTransferAmount, "Transfer amount exceeds the maximum allowed.");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= maxTransferAmount, "Transfer amount exceeds the maximum allowed.");
        return super.transferFrom(sender, recipient, amount);
    }

    function setMaxTransferAmount(uint256 _maxTransferAmount) public onlyOwner {
        maxTransferAmount = _maxTransferAmount;
    }
}