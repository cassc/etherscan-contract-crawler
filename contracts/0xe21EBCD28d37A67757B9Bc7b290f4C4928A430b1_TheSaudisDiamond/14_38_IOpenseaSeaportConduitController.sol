// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpenseaSeaportConduitController {
    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
    function getChannelStatus(address conduit, address channel) external view returns (bool isOpen);
}