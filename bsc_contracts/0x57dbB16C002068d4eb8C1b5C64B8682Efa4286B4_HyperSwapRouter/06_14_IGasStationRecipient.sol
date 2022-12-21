//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IGasStationRecipient {

    event GasStationChanged(address indexed gasStation);

    function isOwnGasStation(address addressToCheck) external view returns(bool);
}