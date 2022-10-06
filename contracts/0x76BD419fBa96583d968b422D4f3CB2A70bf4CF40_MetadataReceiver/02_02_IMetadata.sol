//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMetadataReceiver {
    event MetadataReceived(address indexed sender, bytes metadata);

    function emitBytes(bytes calldata metadata) external;
}