// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC721Receiver standard
 */
interface IERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}