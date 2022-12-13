// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../libraries/PartLib.sol";
import "../libraries/MintERC721Lib.sol";
import "../libraries/SignatureLib.sol";

interface IERC721LazyMint is IERC721Upgradeable {
    event Minted(bytes32 indexed mintERC721Hash);

    function lazyMint(
        MintERC721Lib.MintERC721Data memory mintERC721Data,
        SignatureLib.SignatureData memory signatureData
    ) external;

    function isMinted(uint256 tokenId) external view returns (bool);
}