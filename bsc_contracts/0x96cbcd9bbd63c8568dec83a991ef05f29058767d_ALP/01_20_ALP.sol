// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ALP is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    mapping(address => bool) public fromWhiteList;
    mapping(address => bool) public toWhiteList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) initializer public {
        __ERC20_init("ApolloX LP", "ALP");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ADMIN_ROLE, owner);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(amount > 0, "ERC20: mint zero amount");
        _mint(to, amount);
    }

    function addFromWhiteList(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "account cannot be 0 address");
        fromWhiteList[account] = true;
    }

    function removeFromWhiteList(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "account cannot be 0 address");
        delete fromWhiteList[account];
    }

    function addToWhiteList(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "account cannot be 0 address");
        toWhiteList[account] = true;
    }

    function removeToWhiteList(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "account cannot be 0 address");
        delete toWhiteList[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
        require(from == address(0) || fromWhiteList[from] || to == address(0) || toWhiteList[to],
            "Non-whitelisted addresses are prohibited from transfer");
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}
}