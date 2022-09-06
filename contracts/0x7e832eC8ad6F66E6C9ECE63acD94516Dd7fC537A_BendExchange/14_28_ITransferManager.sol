// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITransferManager {
    function transfers(address collection) external view returns (address);

    function addCollectionTransfer(address collection, address transfer) external;

    function removeCollectionTransfer(address collection) external;

    function checkTransferForToken(address collection) external view returns (address);
}