// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/// @title PoLidoNFT interface.
/// @author 2021 ShardLabs
interface IPoLidoNFT is IERC721Upgradeable {
    function mint(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool);

    function setStMATIC(address _stMATIC) external;
    function getOwnedTokens(address _address) external view returns (uint256[] memory);
}