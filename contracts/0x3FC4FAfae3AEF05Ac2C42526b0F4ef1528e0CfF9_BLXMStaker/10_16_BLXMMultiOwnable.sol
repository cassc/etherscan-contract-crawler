// SPDX-License-Identifier: GPL-3.0 License

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/BLXMLibrary.sol";


abstract contract BLXMMultiOwnable is Initializable {
    
    // member address => permission
    mapping(address => bool) public members;

    event OwnershipChanged(address indexed executeOwner, address indexed targetOwner, bool permission);

    modifier onlyOwner() {
        require(members[msg.sender], "NOT_OWNER");
        _;
    }

    function __BLXMMultiOwnable_init() internal onlyInitializing {
        _changeOwnership(msg.sender, true);
    }

    function addOwnership(address newOwner) public virtual onlyOwner {
        BLXMLibrary.validateAddress(newOwner);
        _changeOwnership(newOwner, true);
    }

    function removeOwnership(address owner) public virtual onlyOwner {
        BLXMLibrary.validateAddress(owner);
        _changeOwnership(owner, false);
    }

    function _changeOwnership(address owner, bool permission) internal virtual {
        members[owner] = permission;
        emit OwnershipChanged(msg.sender, owner, permission);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}