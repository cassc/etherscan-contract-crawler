// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NFT Receiver contract
interface INFTReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4);
}