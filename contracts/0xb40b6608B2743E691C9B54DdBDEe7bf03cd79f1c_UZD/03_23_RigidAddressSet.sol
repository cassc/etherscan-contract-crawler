// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract RigidAddressSet {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _rigidAddresses;

    event AddedRigidAddress(address indexed rigidAddress);

    event RemovedRigidAddress(address indexed rigidAddress);

    function rigidAddresses() public view returns (address[] memory) {
        return _rigidAddresses.values();
    }

    function _addRigidAddress(address _rigidAddress) internal {
        if(_rigidAddresses.add(_rigidAddress)) {
            emit AddedRigidAddress(_rigidAddress);
        } else {
            revert("RigidAddressSet: add existed address");
        }
    }

    function _removeRigidAddress(address _rigidAddress) internal {
        if(_rigidAddresses.remove(_rigidAddress)){
            emit RemovedRigidAddress(_rigidAddress);
        } else {
            revert("RigidAddressSet: remove un-existed address");
        }
    }

    function _containRigidAddress(address _rigidAddress) internal view returns (bool) {
        return _rigidAddresses.contains(_rigidAddress);
    }
}