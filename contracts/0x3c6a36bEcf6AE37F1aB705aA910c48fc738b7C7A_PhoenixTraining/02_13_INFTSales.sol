//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface INFTSales {
    function batchMint(address receiver, uint32[] calldata nftTypes) external;

    function mint(address receiver, uint32 nftType) external;

    function assignNFTType(uint32[] calldata nftIDs, uint32[] calldata nftTypes)
        external;

    function getNFTTypeForTokenID(uint32 tokenID)
        external
        view
        returns (uint32);

    function getNFTTypesForTokenIDs(uint32[] calldata tokenIDs)
        external
        view
        returns (uint32[] memory);

    function evolve(uint32[] calldata nftIDs, uint32[] calldata nftTypes)
        external;

    function uncrate(uint32 id) external payable;

    function uncrateBatch(uint32[] calldata ids) external;

    function isOwnerOf(address account, uint32[] calldata tokenIDs)
        external
        view
        returns (bool);

    function batchSafeTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}