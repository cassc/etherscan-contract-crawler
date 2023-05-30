// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @notice ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {

    /**
     * @notice ERC721 token receiver interface
     * @dev Interface for any contract that wants to support safeTransfers
     * from ERC721 asset contracts.
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        pure
        returns (bytes4)
    {
        return 0x150b7a02;
    }
}