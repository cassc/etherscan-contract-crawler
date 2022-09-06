// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721Extended is IERC165, IERC721, IERC721Metadata {
    function tokenDescriptor() external view returns (address);

    function tokenDescriptorSetter() external view returns (address);

    function totalSupply() external view returns (uint256);

    function latestTokenId() external view returns (uint256);

    function nonces(uint256 tokenId) external view returns (uint256 nonce);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}