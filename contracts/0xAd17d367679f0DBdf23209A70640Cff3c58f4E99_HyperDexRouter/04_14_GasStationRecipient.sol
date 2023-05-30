//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IGasStationRecipient.sol";

abstract contract GasStationRecipient is IGasStationRecipient {
    /*
     * Allowed Gas Station Contract for accept calls from
     */
    address private _gasStation;

    function isOwnGasStation(address addressToCheck) external view returns(bool) {
        return _gasStation == addressToCheck;
    }

    function gasStation() external view returns (address) {
        return _gasStation;
    }

    function _setGasStation(address newGasStation) internal {
        require(newGasStation != address(0), "Invalid new gas station address");
        _gasStation = newGasStation;
        emit GasStationChanged(_gasStation);
    }

    /**
    * return the sender of this call.
    * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
    * of the msg.data.
    * otherwise, return `msg.sender`
    * should be used in the contract anywhere instead of msg.sender
    */
    function _msgSender() internal view returns (address ret) {
        if (msg.data.length >= 20 && this.isOwnGasStation(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && this.isOwnGasStation(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}