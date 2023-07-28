// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/introspection/IERC165.sol";

interface INFT20 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mint(address to) external;

    function burn(uint256 tokenId) external;

    function deposit(
        address to,
        address erc20address,
        uint256 amount
    ) external;

    function withdraw(uint256 tokenId) external;

    function getNFTInfo(uint256 nftId)
        external
        view
        returns (
            address _erc20address,
            uint256 _amount,
            uint256 _block
        );

    function totalStaked(address token) external view returns (uint256 amount);
}