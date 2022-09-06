// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IFlowerFamNewGen {
    function mint(
        address sender,
        uint256 amount
    ) external;

    function stake(address staker, uint256 tokenId) external;
    function unstake(address unstaker, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function realOwnerOf(uint256 tokenId) external view returns (address);
    function isAlreadyStaked(uint256 _tokenId) external view returns (bool);

    function startTokenId() external pure returns (uint256);
}