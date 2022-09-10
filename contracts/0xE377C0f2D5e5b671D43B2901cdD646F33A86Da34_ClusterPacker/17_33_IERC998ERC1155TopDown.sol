// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IERC998ERC1155TopDown {
    event Received1155Child(
        address indexed from,
        uint256 indexed toTokenId,
        address indexed childContract,
        uint256 childTokenId,
        uint256 amount
    );
    event Transfer1155Child(
        uint256 indexed fromTokenId,
        address indexed to,
        address indexed childContract,
        uint256 childTokenId,
        uint256 amount
    );
    event Transfer1155BatchChild(
        uint256 indexed fromTokenId,
        address indexed to,
        address indexed childContract,
        uint256[] childTokenIds,
        uint256[] amounts
    );

    function safeTransferChild(
        uint256 fromTokenId,
        address to,
        address childContract,
        uint256 childTokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferChild(
        uint256 fromTokenId,
        address to,
        address childContract,
        uint256[] calldata childTokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function childBalance(
        uint256 tokenId,
        address childContract,
        uint256 childTokenId
    ) external view returns (uint256);
}