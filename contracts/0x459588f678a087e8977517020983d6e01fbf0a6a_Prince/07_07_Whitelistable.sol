//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelistable Token
 * @dev Allows accounts to be Whitelisted by a "Whitelister" role
 */
contract Whitelistable is Ownable {
    address public _whitelister;
    mapping(address => bool) internal _whitelisted;

    event Whitelisted(address indexed account);
    event UnWhitelisted(address indexed account);
    event WhitelisterChanged(address indexed newWhitelister);

    error Unauthorized();
    error NotInWhitelist();
    error InWhitelist();
    error ZeroAddress();

    /**
     * @dev Throws if called by any account other than the whitelister
     */
    modifier onlyWhitelister() {
        if(msg.sender != _whitelister){
            revert Unauthorized();
        }
        _;
    }

    /**
     * @dev Throws if argument account is not whitelisted
     * @param account The address to check
     */
    modifier inWhitelist(address account) {
        if(!_whitelisted[account]){
            revert NotInWhitelist();
        }
        _;
    }

    constructor(address whitelister) {
        updateWhitelister(whitelister);
    }

    /**
     * @dev Returns the address of the current whitelister
     */
    function getWhitelister() external view returns (address) {
        return _whitelister;
    }

    /**
     * @dev Checks if account is whitelisted
     * @param account The address to check
     */
    function isWhitelisted(address account) external view returns (bool) {
        return _whitelisted[account];
    }

    /**
     * @dev Adds account to whitelist
     * @param account The address to whitelist
     */
    function addWhitelist(address account) external onlyWhitelister {
        _addWhitelist(account);
    }

    /**
     * @dev Adds accounts to whitelist
     * @param accounts batch of addresses to whitelist
     */
    function addBatchToWhitelist(address[] calldata accounts) external onlyWhitelister {
        for(uint i = 0; i < accounts.length; ++i){
            _addWhitelist(accounts[i]);
        }
    }

    /**
     * @dev Removes account from whitelist
     * @param account The address to remove from the whitelist
     */
    function unWhitelist(address account) external onlyWhitelister {
        _whitelisted[account] = false;
        emit UnWhitelisted(account);
    }

    function updateWhitelister(address newWhitelister) public onlyOwner{
        if(newWhitelister == address(0)){
            revert ZeroAddress();
        }
        _whitelister = newWhitelister;
        emit WhitelisterChanged(_whitelister);
    }

    /**
     * @dev Adds account to whitelist, do not check whitelist status of the account before adding
     * @param account The address to whitelist
     */
    function _addWhitelist(address account) internal {
        if(account == address(0)){
            revert ZeroAddress();
        }
        _whitelisted[account] = true;
        emit Whitelisted(account);
    }

}