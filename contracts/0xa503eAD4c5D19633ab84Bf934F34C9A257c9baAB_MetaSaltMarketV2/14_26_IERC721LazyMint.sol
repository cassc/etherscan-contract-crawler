// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../lib/LibERC721LazyMint.sol";

interface IERC721LazyMint is IERC721Upgradeable {
    event Creator(
        uint256 tokenId,
        address creator,
        uint256 royaltyFee
    );

    function mintAndTransfer(
        LibERC721LazyMint.Mint721Data memory data,
        address to
    ) external;

    function transferFromOrMint(
        LibERC721LazyMint.Mint721Data memory data,
        address from,
        address to
    ) external;

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address, uint256 
    );
}