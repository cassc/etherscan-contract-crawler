// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./openzeppelin/token/ERC20/ERC20.sol";
import "./openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "./openzeppelin/security/Pausable.sol";
import "./openzeppelin/access/AccessControl.sol";

contract DUD is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => bool) public blacklist;

    constructor(
        address admin,
        address pauser
    ) ERC20("Do Ut Des", "DUD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, admin);
    }

    modifier whenNotBlacklisted(address from, address to) {
        require(blacklist[from] == false, "Sender address is blacklisted");
        require(blacklist[to] == false, "Recipient address is blacklisted");
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
        whenNotBlacklisted(from, to)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function confiscateFrom(
        address from,
        address to,
        uint256 amount
    ) public onlyRole(ADMIN_ROLE) returns (bool) { 
        _transfer(from, to, amount);
        return true;
    }

    function blacklistAddress(address _addr, bool _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklist[_addr] = _value;
    }
}