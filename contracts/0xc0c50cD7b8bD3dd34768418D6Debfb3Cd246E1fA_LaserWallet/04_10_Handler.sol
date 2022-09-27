// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "../interfaces/IHandler.sol";
import "../interfaces/IERC165.sol";

/**
 * @title Handler
 *
 * @notice Supports token callbacks.
 */
contract Handler is IHandler, IERC165 {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 result) {
        return 0xbc197c81;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure {}

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            _interfaceId == 0x1626ba7e || // EIP 1271.
            _interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155.
            _interfaceId == 0x4e2312e0 || // ERC-1155 `ERC1155TokenReceiver` support.
            _interfaceId == 0xae029e0b || // Laser Wallet contract: bytes4(keccak256("I_AM_LASER")).
            _interfaceId == 0x150b7a02; // ERC721 onErc721Received.
    }
}