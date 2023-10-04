// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ISnxAddressResolver } from './interfaces/ISnxAddressResolver.sol';

contract SnxConfig {
    bytes32 public trackingCode;
    ISnxAddressResolver public addressResolver;
    address public perpsV2MarketData;

    constructor(
        address _addressResolver,
        address _perpsV2MarketData,
        bytes32 _snxTrackingCode
    ) {
        addressResolver = ISnxAddressResolver(_addressResolver);
        // https://github.com/Synthetixio/synthetix/blob/master/contracts/PerpsV2MarketData.sol
        perpsV2MarketData = _perpsV2MarketData;
        trackingCode = _snxTrackingCode;
    }
}