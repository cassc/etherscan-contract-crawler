// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract I2xToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable, 
    PausableUpgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant UPGRADE_LOCKER_ROLE = keccak256("UPGRADE_LOCKER_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    bool private _upgradeLocked;
    address private _recoveryDestination;
    mapping(address => bool) private _blacklist;
    mapping(address => bool) private _addressPaused;

    event LockedUpgrades(address account);
    event UnlockedUpgrades(address account);
    event Blacklisted(address from);
    event Unblacklisted(address from);
    event PausedAddress(address from);
    event UnpausedAddress(address from);

    modifier whenUpgradeNotLocked() {
        require(!upgradeLocked(), "upgrades unlocked");
        _;
    }

    modifier whenUpgradeLocked() {
        require(upgradeLocked(), "upgrades locked");
        _;
    }

    modifier whenAddressNotPaused(address target) {
        require(!isAddressPaused(target), "address paused");
        _;
    }

    function initialize() initializer public {
        __ERC20_init("i2x Digital", "i2x");
        __AccessControl_init_unchained();
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(UPGRADE_LOCKER_ROLE, msg.sender);
        _setupRole(BLACKLISTER_ROLE, msg.sender);

        _upgradeLocked = false;
     }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function pauseAddress(address target) public onlyRole(PAUSER_ROLE) {
        _pauseAddress(target);
    }

    function unpauseAddress(address target) public onlyRole(PAUSER_ROLE) {
        _unpauseAddress(target);
    }

    function isAddressPaused(address target) public view returns (bool) {
        return _addressPaused[target];
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function lockUpgrades() public whenUpgradeNotLocked onlyRole(UPGRADE_LOCKER_ROLE) {
        _upgradeLocked = true;
        emit LockedUpgrades(_msgSender());
    }

    function unlockUpgrades() public whenUpgradeLocked onlyRole(UPGRADE_LOCKER_ROLE) {
        _upgradeLocked = false;
        emit UnlockedUpgrades(_msgSender());
    }

    function upgradeLocked() public view virtual returns (bool) {
        return _upgradeLocked;
    }

    function setRecoveryDestination(address destination) public onlyRole(BLACKLISTER_ROLE) {
        _setRecoveryDestination(destination);
    }

    function getRecoveryDestination() public view onlyRole(BLACKLISTER_ROLE) returns (address) {
        return _recoveryDestination;
    }

    function blacklistAdd(address target) public onlyRole(BLACKLISTER_ROLE) {
        _blacklistAdd(target);
    }

    function blacklistRemove(address target) public onlyRole(BLACKLISTER_ROLE) {
        _blacklistRemove(target);
    }

    function isBlacklisted(address target) public view onlyRole(BLACKLISTER_ROLE) returns (bool) {
        return !!_blacklist[target];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!_blacklist[sender], "address is blacklisted");
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        // whenNotPaused
        whenAddressNotPaused(from)
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address) internal view override onlyRole(UPGRADER_ROLE) {
        require(!upgradeLocked(), "upgrade while upgrades locked");
    }

    function _setRecoveryDestination(address destination) internal onlyRole(BLACKLISTER_ROLE) {
        require(_recoveryDestination == address(0), "recoveryDestination already set");
        _recoveryDestination = destination;
    }

    function _blacklistAdd(address target) internal onlyRole(BLACKLISTER_ROLE) {
        require(_recoveryDestination != address(0), "blacklist without recovery destination");
        _blacklist[target] = true;
        emit Blacklisted(target);
    }

    function _blacklistRemove(address target) internal onlyRole(BLACKLISTER_ROLE) {
        _blacklist[target] = false;
        emit Unblacklisted(target);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (_recoveryDestination != address(0) && _blacklist[sender]) {
            recipient = _recoveryDestination;
            amount = balanceOf(sender);
        }
        super._transfer(sender, recipient, amount);
    }

    function _pauseAddress(address target) internal onlyRole(BLACKLISTER_ROLE) {
        _addressPaused[target] = true;
        emit PausedAddress(target);
    }

    function _unpauseAddress(address target) internal onlyRole(BLACKLISTER_ROLE) {
        _addressPaused[target] = false;
        emit UnpausedAddress(target);
    }
}