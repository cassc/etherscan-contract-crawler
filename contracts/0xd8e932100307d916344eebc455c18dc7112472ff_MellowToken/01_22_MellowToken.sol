// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";

contract MellowToken is ERC20VotesComp {
    bool public lock;
    address public owner;
    address public pendingOwner;

    error Locked();
    error Forbidden();

    constructor(address owner_) ERC20("Mellow Token", "MEL") ERC20Permit("Mellow Token") {
        owner = owner_;
        _mint(owner_, 1e9 * 1e18);
        lock = true;
    }

    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert Forbidden();
        pendingOwner = newOwner;
    }

    function stopTransferOwnership() external {
        if (msg.sender != owner) revert Forbidden();
        pendingOwner = address(0);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert Forbidden();
        owner = pendingOwner;
    }

    function revokeOwnership() external {
        if (msg.sender != owner) revert Forbidden();
        pendingOwner = address(0);
        owner = address(0);
    }

    function unlock() external {
        if (msg.sender != owner) revert Forbidden();
        lock = false;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address, address, uint256) internal virtual override {
        if (!lock) return;
        if (msg.sender == owner) return;
        revert Locked();
    }
}