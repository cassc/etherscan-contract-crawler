// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";    

abstract contract Manageable is Ownable {

    address[] private _managers;
    
    constructor() {
        addManager(_msgSender());
    }

    /// @dev Throws if called by any account other than a manager.
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /// @notice Check, whether a wallet is a manager or not
    function isManager(address wallet) public view virtual returns (bool) {
        for(uint256 index = 0; index < _managers.length; index++) {
            if(_managers[index] == wallet) return true;
        }

        return false;
    }

    /// @dev Throws if the sender is not a manager
    function _checkManager() internal view virtual {
        require(isManager(_msgSender()), "Managable: caller is not a manager");
    }

    /// @notice Add a list of addresses to a list of managers
    function addManagers(address[] memory newManagers) public virtual onlyOwner {
        for(uint256 index = 0; index < newManagers.length; index++) {
            addManager(newManagers[index]);
        }
    }

    /// @notice Add an address to a list of managers
    function addManager(address newManager) public virtual onlyOwner {
        require(!isManager(newManager), "Managable: wallet is already a manager");
        require(newManager != address(0), "Managable: new manager is the zero address");

        _managers.push(newManager);
    }

    /// @notice Remove all managers from the contract
    function removeManagers() public virtual onlyOwner {
        delete _managers;
    }
}