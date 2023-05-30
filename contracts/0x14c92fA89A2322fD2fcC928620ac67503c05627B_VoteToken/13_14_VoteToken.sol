// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VoteToken is ERC20, Pausable, AccessControl {
    bytes32 public constant FULLTIME_TRANSFER_ROLE =
        keccak256("FULLTIME_TRANSFER_ROLE");
    bytes32 public constant PAUSE_UNPAUSE_ROLE =
        keccak256("PAUSE_UNPAUSE_ROLE");
    bytes32 public constant MINT_BURN_ROLE =
        keccak256("MINT_BURN_ROLE");
    bytes32 public constant BLACKLIST_ADD_REMOVE_ROLE =
        keccak256("BLACKLIST_ADD_REMOVE_ROLE");
    bytes32 public constant DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE =
        keccak256("DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE");

    mapping(address => address) public depositorAddresses;
    mapping(address => bool) public blacklist;

    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);
    event AddedToDepositorAddresses(
        address indexed receiverAddress,
        address indexed depositorAddress
    );
    event RemovedFromDepositorAddresses(
        address indexed receiverAddress,
        address indexed depositorAddress
    );

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant DEFAULT_ADMIN_ROLE by calling grantRole(),
     * and also can renounce it's own DEFAULT_ADMIN_ROLE by calling renounceRole().
     *
     * Initially _paused is set to true to pause asset transfers except for FULLTIME_TRANSFER_ROLE and depositorAddresses.
     */
    constructor(string memory tokenName, string memory tokenSymbol)
        ERC20(tokenName, tokenSymbol)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _pause();
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant BLACKLIST_ADD_REMOVE_ROLE by calling grantRole().
     * Only BLACKLIST_ADD_REMOVE_ROLE can addToBlacklist.
     */
    function addToBlacklist(address account)
        external
        onlyRole(BLACKLIST_ADD_REMOVE_ROLE)
    {
        blacklist[account] = true;
        emit AddedToBlacklist(account);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant BLACKLIST_ADD_REMOVE_ROLE by calling grantRole().
     * Only BLACKLIST_ADD_REMOVE_ROLE can removeFromBlacklist.
     */
    function removeFromBlacklist(address account)
        external
        onlyRole(BLACKLIST_ADD_REMOVE_ROLE)
    {
        blacklist[account] = false;
        emit RemovedFromBlacklist(account);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE by calling grantRole().
     * Only DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE can addToDepositorAddresses.
     */
    function addToDepositorAddresses(
        address receiverAddress,
        address depositorAddress
    ) external onlyRole(DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE) {
        depositorAddresses[receiverAddress] = depositorAddress;
        emit AddedToDepositorAddresses(receiverAddress, depositorAddress);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE by calling grantRole().
     * Only DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE can removeFromDepositorAddresses.
     */
    function removeFromDepositorAddresses(address receiverAddress)
        external
        onlyRole(DEPOSITOR_ADDRESSES_ADD_REMOVE_ROLE)
    {
        depositorAddresses[receiverAddress] = address(0);
        emit RemovedFromDepositorAddresses(receiverAddress, address(0));
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant MINT_BURN_ROLE by calling grantRole().
     * Only MINT_BURN_ROLE can mint.
     */
    function mint(address to, uint256 amount) external onlyRole(MINT_BURN_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant MINT_BURN_ROLE by calling grantRole().
     * Only MINT_BURN_ROLE can burn.
     */
    function burn(address account, uint256 amount)
        external
        onlyRole(MINT_BURN_ROLE)
    {
        _burn(account, amount);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant PAUSE_UNPAUSE_ROLE by calling grantRole().
     * Only PAUSE_UNPAUSE_ROLE can unpause.
     */
    function unpause() external onlyRole(PAUSE_UNPAUSE_ROLE) {
        _unpause();
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant PAUSE_UNPAUSE_ROLE by calling grantRole().
     * Only PAUSE_UNPAUSE_ROLE can pause.
     */
    function pause() external onlyRole(PAUSE_UNPAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev blacklisted account cannot use his voting power to vote.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (blacklist[account]) {
            return 0;
        } else {
            return super.balanceOf(account);
        }
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant FULLTIME_TRANSFER_ROLE by calling grantRole().
     * FULLTIME_TRANSFER_ROLE and depositorAddresses is not subject to the _paused status.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPausedWithException(msg.sender, recipient)
        notBlacklisted(msg.sender)
        notBlacklisted(recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(sender)
        notBlacklisted(recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    modifier whenNotPausedWithException(address caller, address recipient) {
        if (hasRole(FULLTIME_TRANSFER_ROLE, caller)) {
            _;
        } else if (depositorAddresses[caller] == recipient) {
            _;
        } else {
            _requireNotPaused();
            _;
        }
    }

    modifier notBlacklisted(address account) {
        require(!blacklist[account], "Account is blacklisted");
        _;
    }
}