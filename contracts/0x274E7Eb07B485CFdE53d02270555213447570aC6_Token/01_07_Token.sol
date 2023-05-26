// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract OwnedPausalbe is Pausable, Ownable {
    modifier onlyOwnerOrNotPaused() {
        if (owner() != _msgSender()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function pause() onlyOwner public {
        _pause();
    }

    function unpause() onlyOwner public {
        _unpause();
    }
}

contract Token is ERC20, OwnedPausalbe {
    constructor(string memory fullName, string memory symbol,uint256 initialSupply) ERC20(fullName, symbol) {
        _mint(msg.sender, initialSupply);
        _pause();
    }

    function transfer(address to, uint256 value) public onlyOwnerOrNotPaused override returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (from != owner()) {
            require(!paused(), "Pausable: paused");
        }
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public onlyOwnerOrNotPaused override returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public onlyOwnerOrNotPaused override returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public onlyOwnerOrNotPaused override returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}