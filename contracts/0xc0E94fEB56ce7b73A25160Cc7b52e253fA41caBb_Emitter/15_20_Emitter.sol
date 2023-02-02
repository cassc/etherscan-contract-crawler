// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import './StorageBeacon.sol';
import '../Errors.sol';


/**
 * @title Forwarding contract for manual redeems.
 * @notice Forwards the address of the account that received a transfer, for a check-up
 * of the tx in case it needs a manual redeem
 */
contract Emitter is Initializable, Ownable {
    address private _beacon;

    event ShowTicket(address indexed proxy, address indexed owner);

    /// @dev Stores the beacon (ozUpgradableBeacon)
    function storeBeacon(address beacon_) external initializer {
        _beacon = beacon_;
    }

    /// @dev Gets the first version of the Storage Beacon
    function _getStorageBeacon() private view returns(StorageBeacon) {
        return StorageBeacon(ozUpgradeableBeacon(_beacon).storageBeacon(0));
    }
    
    /**
     * @dev Forwards the account/proxy to the offchain script that checks for 
     * manual redeems.
     */
    function forwardEvent(address user_) external { 
        bytes20 account = bytes20(msg.sender);
        bytes12 userFirst12 = bytes12(bytes20(user_));
        bytes32 acc_user = bytes32(bytes.concat(account, userFirst12));

        if (!_getStorageBeacon().verify(user_, acc_user)) revert NotAccount();
        emit ShowTicket(msg.sender, user_);
    }
}