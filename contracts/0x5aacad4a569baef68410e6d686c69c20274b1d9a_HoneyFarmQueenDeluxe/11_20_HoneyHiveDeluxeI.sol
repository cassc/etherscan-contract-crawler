//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract HoneyHiveDeluxeI is Ownable, IERC721 {
    function mint(address _owner, uint256 _bearId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external virtual returns (uint256);

    function increaseUsageOfMintingBee(uint256 _hiveId) external virtual;

    function getUsageOfMintingBee(uint256 _hiveId) external view virtual returns (uint8);

    function resetUsageOfMintingBee(uint256 _hiveId) external virtual;

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);

    function totalSupply() public view virtual returns (uint256);
}