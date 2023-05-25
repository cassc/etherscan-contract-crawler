// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Foxe is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) private _blacklist;

    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    constructor() ERC20("Foxe", "FOXE") {
        _mint(msg.sender, 177781900000000 * 10 ** decimals());
    }

    function addToBlacklist(address account) public onlyOwner {
        require(account != address(0), "Cannot add zero address to blacklist");
        require(!_blacklist[account], "Address is already blacklisted");
        _blacklist[account] = true;
        emit Blacklisted(account);
    }

    function removeFromBlacklist(address account) public onlyOwner {
        require(account != address(0), "Cannot remove zero address from blacklist");
        require(_blacklist[account], "Address is not blacklisted");
        _blacklist[account] = false;
        emit Unblacklisted(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!isBlacklisted(from), "Token transfer refused. Sender is on the blacklist.");
        require(!isBlacklisted(to), "Token transfer refused. Receiver is on the blacklist.");
        super._beforeTokenTransfer(from, to, amount);
    }
}