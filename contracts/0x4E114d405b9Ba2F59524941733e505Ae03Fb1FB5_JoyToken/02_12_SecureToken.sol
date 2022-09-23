// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NOT_AUTHORIZED();
error MAX_TOTAL_SUPPLY();

contract SecureToken is AccessControl, ERC20, Ownable {
    /**
     * Maximum totalSupply 
     */
    uint256 public maxTotalSupply;

    /**
     * A map of all blacklisted addresses
     */
    mapping(address => bool) public blacklisted;

    /**
     * A map of whitelisted receivers.
     */
    mapping(address => bool) public whitelisted;

    event WhitelistedMany(address[] _users);
    event Whitelisted(address _user);
    event RemovedFromWhitelist(address _user);

    event BlacklistedMany(address[] _users);
    event Blacklisted(address _user);
    event RemovedFromBlacklist(address _user);

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    /**
     * Constructor of SecureToken contract
     * @param _whitelist - List of addresses to be whitelisted as always allowed token transfering
     * @param _blacklist  - Initial blacklisted addresses to forbid any token transfers
     * @param _admins    - List of administrators that can change this contract settings
     */
    constructor(
        address[] memory _whitelist,
        address[] memory _blacklist,
        address[] memory _admins,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        maxTotalSupply = 5000000000 * 1e18; // 5B Joy & xJoy

        if (_admins.length > 0) {
            for (uint i; i < _admins.length; ) {
                _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
                unchecked { i++; }
            }
        }

        if (_whitelist.length > 0) {
            addManyToWhitelist(_whitelist);
        }
        if (_blacklist.length > 0) {
            addManyToBlacklist(_blacklist);
        }
    }

    /**
     * Adding new admin to the contract
     * @param _admin - New admin to be added to administrator list
     */
    function addAdmin(address _admin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * Removing admin from token administrators list
     * @param _admin - Admin to be removed from admin list
     */
    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == owner()) revert NOT_AUTHORIZED();
        _revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }
    
    /**
     * Minting tokens for many addressess
     * @param _addrs - Address to mint new tokens to
     * @param _amounts - Amount new tokens to be minted
     */
    function mintMany(address[] memory _addrs, uint256[] memory _amounts) external onlyOwner {
        uint256 totalMinted;
        for (uint i=0; i<_addrs.length; i++) {
            _mint(_addrs[i], _amounts[i]);
            totalMinted += _amounts[i];
        }
        if(totalSupply() > maxTotalSupply) revert MAX_TOTAL_SUPPLY();
    }

    /**
     * Minting new tokens
     * @param _to - Address to mint new tokens to
     * @param _amount - Amount new tokens to be minted
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        if(totalSupply() + _amount > maxTotalSupply) revert MAX_TOTAL_SUPPLY();
        _mint(_to, _amount);
    }

    /**
     * Burning existing tokens
     * @param _from - Address to burn tokens from
     * @param _amount - Amount of tokens to be burned
     */
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    /**
     * Adding new address to the blacklist
     * @param _blacklisted - New address to be added to the blacklist
     */
    function addToBlacklist(address _blacklisted) public onlyAdmin {
        blacklisted[_blacklisted] = true;
        emit Blacklisted(_blacklisted);
    }

    /**
     * Adding many addresses to the blacklist
     * @param _blacklisted - An array of addresses to be added to the blacklist
     */
    function addManyToBlacklist(address[] memory _blacklisted) public onlyAdmin {
        for (uint i; i < _blacklisted.length; ) {
            blacklisted[_blacklisted[i]] = true;
            unchecked { i++; }
        }
        emit BlacklistedMany(_blacklisted);
    }

    /**
     * Removing address from the blacklist
     * @param _address - Address to be removed from the blacklist
     */
    function removeFromBlacklist(address _address) public onlyAdmin {
        blacklisted[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    /**
     * Adding an address to contracts whitelist
     * @param _whitelisted - Address to be added to the whitelist
     */
    function addToWhitelist(address _whitelisted) public onlyAdmin {
        whitelisted[_whitelisted] = true;
        emit Whitelisted(_whitelisted);
    }

    /**
     * Adding many addresses to the whitelist
     * @param _whitelisted - An array of addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] memory _whitelisted) public onlyAdmin {
        for (uint i; i < _whitelisted.length; ) {
            whitelisted[_whitelisted[i]] = true;
            unchecked { i++; }
        }
        emit WhitelistedMany(_whitelisted);
    }

    /**
     * Removing an address from the whitelist
     * @param _address - Address to be removed from the whitelist
     */
    function removeFromWhitelist(address _address) public onlyAdmin {
        whitelisted[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

}