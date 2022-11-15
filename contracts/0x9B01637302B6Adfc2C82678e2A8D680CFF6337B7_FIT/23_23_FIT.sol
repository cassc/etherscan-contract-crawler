// SPDX-License-Identifier: MIT
// Klaytn Contract Library v1.0.0 (KIP/token/KIP7/extensions/KIP7Snapshot.sol)
// Based on OpenZeppelin Contracts v4.5.0 (token/ERC20/extensions/ERC20Snapshot.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/releases/tag/v4.5.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract FIT is ERC20Snapshot, ERC20PresetMinterPauser, ERC20Capped, Ownable {
    event SetBlacklist(address user, bool status);
    mapping(address => bool) public blacklist;

    constructor(string memory name_, string memory symbol_) ERC20PresetMinterPauser(name_, symbol_) ERC20Capped(6000000000000000000000000000){
    }

    function mint(address to, uint256 amount) public virtual override(ERC20PresetMinterPauser) {
        ERC20PresetMinterPauser.mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Snapshot, ERC20PresetMinterPauser, ERC20) {
        require(!blacklist[from] && !blacklist[to] && !blacklist[msg.sender], "BLACKLIST");
        ERC20PresetMinterPauser._beforeTokenTransfer(from, to, amount);
    }

    function setBlacklist(address user, bool status) external onlyOwner {
        blacklist[user] = status;
        emit SetBlacklist(user, status);
    }

    function snapshot() external virtual onlyOwner returns (uint256) {
        uint256 currentId = super._snapshot();
        return currentId;
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }

}