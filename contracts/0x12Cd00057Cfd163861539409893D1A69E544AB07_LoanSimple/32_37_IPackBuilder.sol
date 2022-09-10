// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPackBuilder {
    struct BundleElementERC721 {
        address tokenContract;
        uint256 id;
        bool safeTransferable;
    }

    struct BundleElementERC20 {
        address tokenContract;
        uint256 amount;
    }

    struct BundleElementERC1155 {
        address tokenContract;
        uint256[] ids;
        uint256[] amounts;
    }

    struct BundleElements {
        BundleElementERC721[] erc721s;
        BundleElementERC20[] erc20s;
        BundleElementERC1155[] erc1155s;
    }

    function createBundle(
        BundleElements memory _bundleElements,
        address _sender,
        address _receiver
    ) external returns (uint256);

    function unpackBundle(uint256 _tokenId, address _receiver) external;
}