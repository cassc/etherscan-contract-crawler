// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../utils/AuthorizableU.sol";

contract BlackListToken is ERC20Upgradeable, AuthorizableU {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////    
    
    bool public isBlackListChecking;
    mapping (address => bool) public isBlackListed; // for from address
    mapping (address => bool) public isWhiteListed; // for to address
    
    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    event StartedBlackList(bool _status);

    event SetBlackList(address[] _users, bool _status);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    event SetWhiteList(address[] _users, bool _status);
    event AddedWhiteList(address _user);
    event RemovedWhiteList(address _user);    

    modifier whenTransferable(address _from, address _to, uint256 _amount) {
        require(isTransferable(_from, _to, _amount), "[email protected]: transfer isn't allowed");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function __BlackList_init() internal virtual initializer {
        __Authorizable_init();

        isBlackListChecking = true;
    }
    
    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    
    function startBlackList(bool _status) public onlyAuthorized {
        isBlackListChecking = _status;
        
        emit StartedBlackList(_status);
    }

    // Blacklist
    function setBlackList(address[] memory _addrs, bool _status) public onlyAuthorized {
        for (uint256 i; i < _addrs.length; ++i) {
            isBlackListed[_addrs[i]] = _status;
        }

        emit SetBlackList(_addrs, _status);
    }

    function addBlackList(address _toAdd) public onlyAuthorized {
        isBlackListed[_toAdd] = true;

        emit AddedBlackList(_toAdd);
    }

    function removeBlackList(address _toRemove) public onlyAuthorized {
        isBlackListed[_toRemove] = false;

        emit RemovedBlackList(_toRemove);
    }
    
    // Whitelist
    function setWhiteList(address[] memory _addrs, bool _status) public onlyAuthorized {
        for (uint256 i; i < _addrs.length; ++i) {
            isWhiteListed[_addrs[i]] = _status;
        }

        emit SetWhiteList(_addrs, _status);
    }

    function addWhiteList(address _toAdd) public onlyAuthorized {
        isWhiteListed[_toAdd] = true;

        emit AddedWhiteList(_toAdd);
    }

    function removeWhiteList (address _toRemove) public onlyAuthorized {
        isWhiteListed[_toRemove] = false;

        emit RemovedWhiteList(_toRemove);
    }
    
    function isTransferable(address _from, address _to, uint256 _amount) public view virtual returns (bool) {
        if (isBlackListChecking) {
            // require(!isBlackListed[_from], "B[email protected]: _from is in isBlackListed");
            // require(!isBlackListed[_to] || isWhiteListed[_to], "[email protected]: _to is in isBlackListed");
            require(!isBlackListed[_from] || isWhiteListed[_to], "[email protected]: _from is in isBlackListed");            
        }
        return true;
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override whenTransferable(_from, _to, _amount) {
        super._transfer(_from, _to, _amount);
    }
}