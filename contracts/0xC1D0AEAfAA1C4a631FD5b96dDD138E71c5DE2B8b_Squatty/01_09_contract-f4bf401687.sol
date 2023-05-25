// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Squatty is ERC20Capped, Pausable, Ownable {
    constructor(uint256 cap) ERC20("Squatty", "SQUAT") ERC20Capped(cap){
        ERC20._mint(_msgSender(), 50000000000 * 10 ** decimals());
    }
        // Airdrop function
    function airdrop(address[] memory recipients, uint256 amount) external {
        require(recipients.length > 0, "No recipients specified");
        require(amount > 0, "Invalid amount");

        uint256 totalAmount = amount * recipients.length;
        require(totalAmount <= balanceOf(msg.sender), "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            _transfer(msg.sender, recipient, amount);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}