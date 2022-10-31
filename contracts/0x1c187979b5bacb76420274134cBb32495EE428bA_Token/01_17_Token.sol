// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol';

contract Token is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant AUDITOR_ROLE = keccak256('AUDITOR_ROLE');
    EnumerableMapUpgradeable.AddressToUintMap private _blacklist;

    event BlacklistAdded(address indexed account);
    event BlacklistRemoved(address indexed account);

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(AUDITOR_ROLE, msg.sender);
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

    function burn(address from, uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(from, amount);
    }

    function addBlacklist(address account) public onlyRole(AUDITOR_ROLE) returns (bool) {
        emit BlacklistAdded(account);
        return _blacklist.set(account, 1);
    }

    function removeBlacklist(address account) public onlyRole(AUDITOR_ROLE) returns (bool) {
        emit BlacklistRemoved(account);
        return _blacklist.remove(account);
    }

    function isBlacklist(address account) public view returns (bool _isBlacklist) {
        return _blacklist.contains(account);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(!isBlacklist(from), 'Token: sender in blacklist');
        return super.transferFrom(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(!isBlacklist(msg.sender), 'Token: caller in blacklist');
        require(!isBlacklist(to), 'Token: recipient in blacklist');
        super._beforeTokenTransfer(from, to, amount);
    }
}