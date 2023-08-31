// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract RestrictableUpgradable is 
        ERC20Upgradeable, 
        AccessControlUpgradeable 
    {
    bytes32 public constant RESTRICT_AGENT_ROLE = keccak256("RESTRICT_AGENT_ROLE");

    mapping(address => bool) internal _restrictedList;

    event AddedRestriction(address _user);
    event RemovedRestriction(address _user);
    event DestroyedRestrictedFunds(address _blackListedUser, uint _balance);

    /**
     * @dev Initializes the contract in restrictable state.
     */
    function __RestrictableUpgradable_init() internal onlyInitializing {
        __RestrictableUpgradable_init_unchained();
    }

    function __RestrictableUpgradable_init_unchained() internal onlyInitializing {
    }

    function _requireNotRestricted(address _user) 
        internal view 
        virtual 
    {
        require(!_restrictedList[_user]);
    }

    modifier whenNotRestricted(address user) 
    {
        _requireNotRestricted(user);
        _;
    }
    
    /// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function isRestrictedUser(address _user) 
        external view 
        returns (bool) 
    {
        return _restrictedList[_user];
    }

    function addRestriction(address _user) 
        external 
        onlyRole(RESTRICT_AGENT_ROLE) 
    {
        _restrictedList[_user] = true;
        emit AddedRestriction(_user);
    }

    function removeRestriction(address _user) 
        external 
        onlyRole(RESTRICT_AGENT_ROLE) 
    {
        _restrictedList[_user] = false;
        emit RemovedRestriction(_user);
    }

    function destroyRestrictedFunds(address _user) 
        external 
        onlyRole(RESTRICT_AGENT_ROLE) 
    {
        require(_restrictedList[_user]);
        uint dirtyFunds = balanceOf(_user);
        _balances[_user] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedRestrictedFunds(_user, dirtyFunds);
    }
}