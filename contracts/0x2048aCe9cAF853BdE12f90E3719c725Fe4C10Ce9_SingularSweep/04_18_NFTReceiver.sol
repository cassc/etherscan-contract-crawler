// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721Receiver} from "./openzeppelin/interfaces/IERC721Receiver.sol";
import {IERC1155Receiver} from "./openzeppelin/interfaces/IERC1155Receiver.sol";
import {IERC165} from "./openzeppelin/interfaces/IERC165.sol";

/// @notice Safe Transfer callback handlers
abstract contract NFTReceiver is IERC165, IERC1155Receiver, IERC721Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }
}