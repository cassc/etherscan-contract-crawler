// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

interface IBeaconSetter {
    function beacon() external view returns (address);
}