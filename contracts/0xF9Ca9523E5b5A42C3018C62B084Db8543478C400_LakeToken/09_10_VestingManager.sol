// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './Ownable2Step.sol';

error VestingManager_AddressIsZero();

abstract contract VestingManager is Ownable2Step {
    /**
     * @dev Event is triggered when Vesting Contract Address is changed
     * @param _address address vesting
     */

    event vestingAddressChanged(address _address);

    address public vesting;

    /**
     * @dev Changes the vesting address variable
     * @param _address new vesting contract address
     */
    function setVestingAddress(address _address) external onlyOwner {
        if (_address == address(0x0)) {
            revert VestingManager_AddressIsZero();
        }
        vesting = _address;
        emit vestingAddressChanged(_address);
    }
}