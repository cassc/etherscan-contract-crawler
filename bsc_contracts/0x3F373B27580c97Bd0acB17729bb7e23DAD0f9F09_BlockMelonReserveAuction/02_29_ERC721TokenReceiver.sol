// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

/**
 * @dev ERC-721 token receiver contract for handling safe transfers
 */
abstract contract ERC721TokenReceiver is IERC721ReceiverUpgradeable {
    /**
     * @dev See {IERC721ReceiverUpgradeable-onERC721Received}
     */
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /* data*/
    ) public pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return interfaceId == type(IERC721ReceiverUpgradeable).interfaceId;
    }
}