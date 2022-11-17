// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BEP20 is Ownable, Pausable, ERC20 {
    uint256 private immutable _cap;

    constructor(string memory name_, string memory symbol_, uint256 cap_, uint256 initialSupply_)
        ERC20(name_, symbol_)
    {
        _cap = cap_;
        _mint(msg.sender, initialSupply_);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function cap() external view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply() + amount <= _cap, "Capped: cap exceeded");
        super._mint(account, amount);
    }

    function mint(uint256 amount) external onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Paused: token transfer while paused");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}