// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IOevDataFeedServer is IDataFeedServer {
    event UpdatedOevProxyBeaconWithSignedData(
        bytes32 indexed beaconId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedOevProxyBeaconSetWithSignedData(
        bytes32 indexed beaconSetId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event Withdrew(
        address indexed oevProxy,
        address oevBeneficiary,
        uint256 amount
    );

    function updateOevProxyDataFeedWithSignedData(
        address oevProxy,
        bytes32 dataFeedId,
        bytes32 updateId,
        uint256 timestamp,
        bytes calldata data,
        bytes[] calldata packedOevUpdateSignatures
    ) external payable;

    function withdraw(address oevProxy) external;

    function oevProxyToBalance(
        address oevProxy
    ) external view returns (uint256 balance);
}