// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title PoLidoNFT interface.
interface IPoLidoNFT is IERC721 {
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool);

    function getOwnedTokens(address _address) external view returns (uint256[] memory);
}