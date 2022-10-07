// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaSpace {
    struct Metadata {
        string title;
        string short_description;
        string description;
        string scene_uri;
    }

    struct Access {
        address token_address;
        uint256 access_fee;
    }

    struct Partner {
        address eth_address;
        uint256 percentage;
    }

    enum ContractType {
        single_token,
        multiple_token
    }
}

interface IERC20MetaSpace {
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721MetaSpace {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC1155MetaSpace {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}