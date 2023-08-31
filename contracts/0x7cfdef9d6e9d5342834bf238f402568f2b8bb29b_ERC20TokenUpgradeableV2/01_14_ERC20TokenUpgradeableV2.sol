// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ERC20 Token Upgradeable V2
 * @dev Basic ERC20 Implementation, Inherits the OpenZeppelin ERC20 implementation.
 */
contract ERC20TokenUpgradeableV2 is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping (address => bool) internal isBlackListed;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);

    error NotGovernor(address caller);
    error NotGuardian(address caller);
    error NotMinter(address caller);
    error Blacklisted(address caller);

    /**
     * @notice Implements Governor role.
     */
    modifier onlyGovernor() {
        if (!hasRole(GOVERNOR_ROLE, msg.sender))
            revert NotGovernor(msg.sender);
        _;
    }

    /**
     * @notice Implements Guardian role.
     */
    modifier onlyGuardian() {
        if (!hasRole(GUARDIAN_ROLE, msg.sender))
            revert NotGuardian(msg.sender);
        _;
    }

    /**
     * @notice Implements Minter role.
     */
    modifier onlyMinter() {
        if (!hasRole(MINTER_ROLE, msg.sender))
            revert NotMinter(msg.sender);
        _;
    }

    /**
     * @notice Throw if argument _addr is blacklisted.
     * @param _addr The address to check
     */
    modifier notBlacklisted(address _addr) {
        if (isBlackListed[_addr])
            revert Blacklisted(_addr);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the governor and removes timelock when upgrading the logic contract to the V2
     * @param governor The address of the default governor to be added
     * @param oldTimelock The address of timelock to be removed
     */
    function initializeV2(address governor, address oldTimelock) external reinitializer(2) {
        require(governor != address(0), "Invalid governor");

        bytes32 timelockRole = keccak256("TIMELOCK_ROLE");
        require(hasRole(timelockRole, oldTimelock), "Invalid timelock");

        _setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
        _setRoleAdmin(MINTER_ROLE, GOVERNOR_ROLE);

        _grantRole(GOVERNOR_ROLE, governor);
        _revokeRole(timelockRole, oldTimelock);
    }

    /**
     * @notice Changes the governor address
     * @param newGovernor New governor address
     * @param oldGovernor Old governor address
     */
    function setGovernor(address newGovernor, address oldGovernor) external onlyGovernor {
        require(newGovernor != address(0), "newGovernor cannot be the zero address");
        _revokeRole(GOVERNOR_ROLE, oldGovernor);
        _grantRole(GOVERNOR_ROLE, newGovernor);
    }

    /**
     * @notice Revokes the governor address
     * @param oldGovernor Governor address to revoke
     */
    function revokeGovernor(address oldGovernor) external onlyGovernor {
        require(oldGovernor != address(0), "oldGovernor cannot be the zero address");
        _revokeRole(GOVERNOR_ROLE, oldGovernor);
    }

    /**
     * @notice Changes the guardian address
     * @param newGuardian New guardian address
     * @param oldGuardian Old guardian address
     */
    function setGuardian(address newGuardian, address oldGuardian) external onlyGuardian {
        require(newGuardian != address(0), "newGuardian cannot be the zero address");
        _revokeRole(GUARDIAN_ROLE, oldGuardian);
        _grantRole(GUARDIAN_ROLE, newGuardian);
    }

    /**
     * @notice Revokes the guardian address
     * @param oldGuardian Guardian address to revoke
     */
    function revokeGuardian(address oldGuardian) external onlyGuardian {
        require(oldGuardian != address(0), "oldGuardian cannot be the zero address");
        _revokeRole(GUARDIAN_ROLE, oldGuardian);
    }

    /**
     * @notice Changes the minter address
     * @param newMinter New minter address
     * @param oldMinter Old minter address
     */
    function setMinter(address newMinter, address oldMinter) external onlyGovernor {
        require(newMinter != address(0), "newMinter cannot be the zero address");
        _revokeRole(MINTER_ROLE, oldMinter);
        _grantRole(MINTER_ROLE, newMinter);
    }

    /**
     * @notice Revokes the minter address
     * @param oldMinter minter address to revoke
     */
    function revokeMinter(address oldMinter) external onlyGovernor {
        require(oldMinter != address(0), "oldMinter cannot be the zero address");
        _revokeRole(MINTER_ROLE, oldMinter);
    }

    /**
     * @notice pause
     * @dev pause the contract
     */
    function pause() external onlyGuardian {
        _pause();
    }

    /**
     * @notice unpause
     * @dev unpause the contract
     */
    function unpause() external onlyGuardian {
        _unpause();
    }

    /**
     * @notice Mint amount of tokens.
     * @dev Function to mint tokens to specific account.
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     * Emits an {Mint} event.
     */
    function mint(address account, uint256 amount) external onlyMinter whenNotPaused notBlacklisted(account) {
        require(amount != 0, "Invalid amount");
        _mint(account, amount);
        emit Mint(account, amount);
    }

    /**
     * @notice Burns `amount` tokens from a `burner` address
     * @dev Function to burn tokens.
     * @param burner Address to burn from
     * @param amount The amount of tokens to burn
     * Emits an {Burn} event.
     */
    function burn(address burner, uint256 amount) external onlyMinter whenNotPaused notBlacklisted(burner) {
        require(amount != 0, "Invalid amount");
        _burn(burner, amount);
        emit Burn(burner, amount);
    }

    /**
     * @notice Override transfer to add whenNotPaused and notBlacklisted check.
     * @dev Make a function callable only when the contract is not paused
     * and account is not blacklisted.
     */
    function transfer(address recipient, uint256 amount) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(recipient) override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice Override transferFrom to add whenNotPaused and notBlacklisted check.
     * @dev Make a function callable only when the contract is not paused
     * and account is not blacklisted.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(from) notBlacklisted(to) override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Override approve to add whenNotPaused and notBlacklisted check.
     * @dev Make a function callable only when the contract is not paused
     * and account is not blacklisted.
     */
    function approve(address spender, uint256 amount) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(spender) override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice Override increaseAllowance to add whenNotPaused and notBlacklisted check.
     * @dev Make a function callable only when the contract is not paused
     * and account is not blacklisted.
     */
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(spender) override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Override decreaseAllowance to add whenNotPaused and notBlacklisted check.
     * @dev Make a function callable only when the contract is not paused
     * and account is not blacklisted.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(spender) override returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Add suspicious account to blacklist.
     * @dev Function to add suspicious account to blacklist,
     * Only callable by contract owner.
     * @param evilUser The address that will add to blacklist
     * Emits an {AddedBlackList} event.
     */
    function addBlackList(address evilUser) public onlyGuardian {
        require(evilUser != address(0), "Invalid address");
        isBlackListed[evilUser] = true;
        emit AddedBlackList(evilUser);
    }

    /**
     * @notice Remove suspicious account from blacklist.
     * @dev Function to remove suspicious account from blacklist,
     * Only callable by contract owner.
     * @param clearedUser The address that will remove from blacklist
     * Emits an {RemovedBlackList} event.
     */
    function removeBlackList(address clearedUser) public onlyGuardian {
        isBlackListed[clearedUser] = false;
        emit RemovedBlackList(clearedUser);
    }

    /**
     * @notice Address blacklisted check.
     * @dev Function to check address whether get blacklisted, 
     * Only callable by contract owner.
     * @param addr The address that will check whether get blacklisted
     */
    function getBlacklist(address addr) public onlyGuardian view returns(bool) {
        return isBlackListed[addr];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}