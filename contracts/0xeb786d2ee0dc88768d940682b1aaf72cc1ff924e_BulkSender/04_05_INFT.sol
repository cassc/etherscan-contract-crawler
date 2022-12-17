// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ERCBase {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);
}

interface ERC721Partial is ERCBase {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ERC1155Partial is ERCBase {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata
    ) external;
}