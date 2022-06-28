//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract BeesDeluxeI is Ownable, IERC721, IERC721Enumerable {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external view virtual returns (uint256);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);

    function totalSupply() public view virtual returns (uint256);

    function burnByQueen(uint256 _tokenId) external virtual;
}