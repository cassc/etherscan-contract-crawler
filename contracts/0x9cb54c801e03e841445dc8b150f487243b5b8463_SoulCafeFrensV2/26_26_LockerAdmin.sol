// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../Errors.sol";

abstract contract LockerAdmin {
    event LockerAdminSet(address indexed asset, address indexed account);

    address private _admin;

    /**
     * Return the address of the account that is allowed to lock/unlock amounts.
     */
    function getLockerAdmin() external view returns (address) {
        return _admin;
    }

    /**
     * Set the address of the account that is allowed to lock/unlock amounts.
     *
     * @param admin The address of the deployed Staking contract.
     */
    function _setLockerAdmin(address admin) internal {
        emit LockerAdminSet(address(this), admin);
        _admin = admin;
    }

    function _onlyLockerAdmin() internal view {
        if (msg.sender != _admin) revert Unauthorized();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}