//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC1155TokenReceiver} from "../../interfaces/IERC1155TokenReceiver.sol";
import {IERC721TokenReceiver} from "../../interfaces/IERC721TokenReceiver.sol";
import {LibNftReceiver} from "../../libraries/LibNftReceiver.sol";

/// @title ERC1155 & ERC721 Token Receiver
/// @author Amit Molek
contract NftReceiverFacet is IERC1155TokenReceiver, IERC721TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return
            LibNftReceiver._onERC1155Received(operator, from, id, value, data);
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return
            LibNftReceiver._onERC1155BatchReceived(
                operator,
                from,
                ids,
                values,
                data
            );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return LibNftReceiver._onERC721Received(operator, from, tokenId, data);
    }
}