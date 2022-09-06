// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDEXConstants {
    /**
     * @dev Returns the index of maker side in the swap components array.
     */
    function MAKER_SIDE() external pure returns (uint8);

    /**
     * @dev Returns the index of taker side in the swap components array.
     */
    function TAKER_SIDE() external pure returns (uint8);

    /**
     * @dev Returns the asset type for ERC1155 swap components.
     */
    function ERC1155_ASSET() external pure returns (uint8);

    /**
     * @dev Returns the asset type for ERC721 swap components.
     */
    function ERC721_ASSET() external pure returns (uint8);

    /**
     * @dev Returns the asset type for ERC20 swap components.
     */
    function ERC20_ASSET() external pure returns (uint8);

    /**
     * @dev Returns to asset type for Ether swap components.
     */
    function ETHER_ASSET() external pure returns (uint8);

    /**
     * @dev Returns the swap status for open (i.e. active) swaps.
     */
    function OPEN_SWAP() external pure returns (uint8);

    /**
     * @dev Returns the swap status for closed swaps.
     */
    function CLOSED_SWAP() external pure returns (uint8);

    /**
     * @dev Returns the swap status for dropped swaps.
     */
    function DROPPED_SWAP() external pure returns (uint8);
}