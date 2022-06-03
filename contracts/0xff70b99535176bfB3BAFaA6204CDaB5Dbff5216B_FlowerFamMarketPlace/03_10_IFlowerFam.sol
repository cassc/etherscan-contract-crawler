// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFlowerFam {
    function prodigy() external view returns (uint256);
    function seedling() external view returns (uint256);
    function ancestor() external view returns (uint256);
    function elder() external view returns (uint256);
    function pioneer() external view returns (uint256);

    function upgradeCooldownTime() external view returns (uint256);
    
    function getUpgradeCountOfFlower(uint256 tokenId) external view returns (uint16);

    function exists(uint256 _tokenId) external view returns (bool);

    function isAlreadyStaked(uint256 _tokenId) external view returns (bool);

    function mint(address _to, uint256 _tokenId) external;

    function stake(address staker, uint256 tokenId) external;

    function unstake(address unstaker, uint256 tokenId) external;

    function realOwnerOf(uint256 tokenId) external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function setBaseURI(string memory _newBaseURI) external;

    function upgrade(address upgrader, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function startTokenId() external pure returns (uint256);
}