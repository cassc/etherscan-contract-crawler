// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// @title: Wagon Network Token
// @author: wagon.network
// @website: https://wagon.network
// @telegram: https://t.me/wagon_network

// ██╗    ██╗ █████╗  ██████╗  ██████╗ ███╗   ██╗
// ██║    ██║██╔══██╗██╔════╝ ██╔═══██╗████╗  ██║
// ██║ █╗ ██║███████║██║  ███╗██║   ██║██╔██╗ ██║
// ██║███╗██║██╔══██║██║   ██║██║   ██║██║╚██╗██║
// ╚███╔███╔╝██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Wagon is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, Pausable, ERC20Permit, ERC20Votes {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");

    uint256 public constant INITIAL_SUPPLY = 100000000;
    address public emergencyAccount;

    mapping (address => bool) public isBlackListed;

    event RecoveredBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    event UpdateEmergencyAccount(address _user);

    // Constructor.
    // Setting all the roles needed and mint the initial supply.
    // @param "Wagon" Token Name
    // @param "WAG" Token Symbol
    constructor() ERC20("Wagon", "WAG") ERC20Permit("Wagon") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** decimals());
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BLACKLISTER_ROLE, msg.sender);
        emergencyAccount = msg.sender;
    }

    // Update Emergency Account.
    // Set a new address to the emergency account. This account will hold WAG tokens 
    // retrieved from blacklisted address.
    // @param _newEmergencyAddress new emergency address
    function updateEmergencyAccount(address _newEmergencyAddress) public onlyRole(DEFAULT_ADMIN_ROLE){
        emergencyAccount = _newEmergencyAddress;
        emit UpdateEmergencyAccount(_newEmergencyAddress);
    }

    // Snapshot.
    // Make a snapshot.
    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    // Get Current Snapshot Id.
    // Get the recent Snapshot Id
    function getCurrentSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }
    
    // Pause.
    // Openzeppelin pausable token transfers, minting and burning.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    // Unpause.
    // Openzeppelin unpause token transfers, minting and burning.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Mint
    // Function to mint new WAG tokens.
    // @param to receiver address.
    // @param amount amount of WAG to mint.
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Before Token Transfer
    // Function to check before any transfer happens. 
    // It will fail, if it's paused or blacklisted.
    // @param from sender address.
    // @param to receiver address.
    // @param amount amount of WAG to be transfered.
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        isNotBlackListed(from, to)
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /* *
     * @title Blacklist
     * @dev Blacklist operations
     */

    // Is Not BlackListed.
    // Check if the sender or receiver of transfer is not on the blacklist.
    // @param _from sender address
    // @param _to receiver address
    modifier isNotBlackListed(address _from, address _to) {
        // sender is not blacklisted or recover black funds to emergency account
        require(!isBlackListed[_from] || _to == emergencyAccount, "Blacklist: blacklisted sender");
        // receiver is not blacklisted
        require(!isBlackListed[_to], "Blacklist: blacklisted receiver");
        _;
    }

    // Get BlackList Status
    // Get the blacklist status of an address.
    // @param _maker address.
    function getBlackListStatus(address _maker) public view returns (bool) {
        return isBlackListed[_maker];
    }
    
    // Add Blacklist.
    // Add address to blacklist
    // @param _evilUser address
    function addBlackList (address _evilUser) public onlyRole(BLACKLISTER_ROLE) {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    // Remove Blacklist.
    // Remove address from blacklist
    // @param _clearedUser address
    function removeBlackList (address _clearedUser) public onlyRole(BLACKLISTER_ROLE) {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    // Recover Black Funds.
    // Recover WAG token from blacklisted address.
    // @param _blackListedUser address
    function recoverBlackFunds (address _blackListedUser) public onlyRole(BLACKLISTER_ROLE) {
        require(isBlackListed[_blackListedUser], "User is not blacklisted");
        uint dirtyFunds = balanceOf(_blackListedUser);
        _transfer(_blackListedUser, emergencyAccount, dirtyFunds);
        emit RecoveredBlackFunds(_blackListedUser, dirtyFunds);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}