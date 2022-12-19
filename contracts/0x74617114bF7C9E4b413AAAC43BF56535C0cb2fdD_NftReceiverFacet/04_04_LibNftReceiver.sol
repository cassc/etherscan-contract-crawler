//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Please see `NftReceiverFacet` for docs
library LibNftReceiver {
    bytes4 internal constant ERC1155_RECEIVED_MAGICVALUE =
        bytes4(
            keccak256(
                "onERC1155Received(address,address,uint256,uint256,bytes)"
            )
        );
    bytes4 internal constant ERC1155_BATCH_RECEIVED_MAGICVALUE =
        bytes4(
            keccak256(
                "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
            )
        );
    bytes4 internal constant ERC721_RECEIVED_MAGICVALUE =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    function _onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) internal pure returns (bytes4) {
        return ERC1155_RECEIVED_MAGICVALUE;
    }

    function _onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal pure returns (bytes4) {
        return ERC1155_BATCH_RECEIVED_MAGICVALUE;
    }

    function _onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) internal pure returns (bytes4) {
        return ERC721_RECEIVED_MAGICVALUE;
    }
}