/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IAssetCheckerFeature {

    struct AssetCheckResultInfo {
        uint8 itemType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        uint256 allowance;
        uint256 balance;
        address erc721Owner;
        address erc721ApprovedAccount;
    }

    function checkAssetsEx(
        address account,
        address operator,
        uint8[] calldata itemTypes,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        view
        returns (AssetCheckResultInfo[] memory infos);

    function checkAssets(
        address account,
        address operator,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        view
        returns (AssetCheckResultInfo[] memory infos);
}