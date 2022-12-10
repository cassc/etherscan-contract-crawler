// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Train is ERC20PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // Token name
    string private constant _NAME = "TrainCraft Token";
    // Token symbol
    string private constant _SYMBOL = "TRACK";

    // `maxTotalSupply` - maximum count of contract tokens
    uint256 private _maxTotalSupply; // max total supply

    // Mapping for accounting blacklisted addresses
    mapping(address => bool) private _blacklistedAddresses;

    /**
     * @dev Emitted when `account` added to blacklist.
     */
    event AddToBlacklist(address indexed account);
    /**
     * @dev Emitted when `account` removed from blacklist.
     */
    event RemoveFromBlacklist(address indexed account);

    /**
     * @dev Initializes the contract by setting `maxTotalSupply`.
     *
     * Requirements:
     * - `maxTotalSupply` cannot be 0.
     */
    function initialize() initializer external {
        __ERC20_init(_NAME, _SYMBOL);
        __Ownable_init();
        __ReentrancyGuard_init();

        _maxTotalSupply = 1000000000000000000000000000;
    }

    /**
     * @dev Returns contract owner - for BEP20 compatibility.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns `maxTotalSupply` limit.
     */
    function maxTotalSupply() external view returns (uint256) {
        return _maxTotalSupply;
    }

    /**
     * @dev Checks if 'account' is blacklisted.
     */
    function isBlacklistedAddress(address account_) external view returns (bool) {
        return _blacklistedAddresses[account_];
    }

    /**
     * @dev Overridden `transfer` method.
     *
     * Requirements:
     * - `to` must not be blacklisted,
     * - `msgSender()` must not be blacklisted.
     */
    function transfer(
        address to_,
        uint256 amount_
    )
        public
        override
        notBlacklistedAddress(_msgSender())
        notBlacklistedAddress(to_)
        returns (bool)
    {
        return super.transfer(to_, amount_);
    }

    /**
     * @dev Overridden `transferFrom` method.
     *
     * Requirements:
     * - `from` must not be blacklisted,
     * - `to` must not be blacklisted,
     * - `msgSender()` must not be blacklisted.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    )
        public
        override
        notBlacklistedAddress(_msgSender())
        notBlacklistedAddress(from_)
        notBlacklistedAddress(to_)
        returns (bool)
    {
        return super.transferFrom(from_, to_, amount_);
    }

    /**
     * @dev Add `account` to blacklist.
     *
     * Requirements:
     * - must be called by owner account.
     */
    function addToBlacklist(address account_) external onlyOwner {
        _blacklistedAddresses[account_] = true;
        emit AddToBlacklist(account_);
    }

    /**
     * @dev Remove `account` from blacklist.
     *
     * Requirements:
     * - must be called by owner account.
     */
    function removeFromBlacklist(address account_) external onlyOwner {
        _blacklistedAddresses[account_] = false;
        emit RemoveFromBlacklist(account_);
    }

    /**
     * @dev Emission of tokens to the desired `account`.
     *
     * Requirements:
     * - must be called by owner account,
     * - `account` cannot be the zero address,
     * - not exceeding the `maxTotalSupply` limit.
     */
    function mintAmount(
        address account_,
        uint256 amount_
    )
        external
        onlyOwner
        nonReentrant
        notBlacklistedAddress(account_)
    {
        require(account_ != address(0), "Train: Invalid address");
        _mint(account_, amount_);
        require(totalSupply() <= _maxTotalSupply, "Train: Max total supply limit reached");
    }

    /**
     * @dev Pause contract.
     *
     * Requirements:
     * - must be called by owner account.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract.
     *
     * Requirements:
     * - must be called by owner account.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Throws if called by blacklisted `account`.
     */
    modifier notBlacklistedAddress(address account_) {
        require(!_blacklistedAddresses[account_], "Train: Address is blacklisted");
        _;
    }
}