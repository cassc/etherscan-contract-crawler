// pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixelsIncExtensionStorageV2 {
    struct Variant {
        bool isOperatorExecution;
        bool isFreeForCollection;
        bool isEnabled;
        bool isDisabledForSpecialPixels;
        uint16 contributerCut;
        uint128 cost;
        uint128 supply;
        uint128 count;
        uint128 categoryId;
        address contributer;
        address collection;
    }

    struct Category {
        uint128 cost;
        uint128 supply;
    }

    struct VariantStatus {
        bool isAlreadyClaimed;
        uint128 cost;
        uint128 supply;
    }

    function extendWithVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external;

    function extendMultipleWithVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenId,
        uint256[] memory collectionTokenIds
    ) external;

    function detachVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId
    ) external;

    function detachVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds
    ) external;

    function variantDetail(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external view returns (Variant memory, VariantStatus memory);

    function variantDetails(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) external view returns (Variant[] memory, VariantStatus[] memory);

    function variantsOfExtension(
        uint256 extensionId,
        uint256[] memory variantIds
    ) external view returns (Variant[] memory);

    function transferExtensionVariant(
        address owner,
        uint256 extensionId,
        uint256 variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    ) external;

    function pixelExtensions(uint256 tokenId) external view returns (uint256);

    function balanceOfToken(
        uint256 extensionId,
        uint256 tokenId,
        uint256[] memory variantIds
    ) external view returns (uint256);

    function currentVariantIdOf(uint256 extensionId, uint256 tokenId)
        external
        view
        returns (uint256);

    function currentVariantIdsOf(uint256 extensionId, uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);
}