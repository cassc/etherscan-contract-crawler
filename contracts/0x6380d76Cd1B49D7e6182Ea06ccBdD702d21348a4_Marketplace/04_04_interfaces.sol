// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IGouda {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function mint(address user, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface IMadMouse {
    function numStaked(address user) external view returns (uint256);

    function numOwned(address user) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getLevel(uint256 tokenId) external view returns (uint256);

    function getDNA(uint256 tokenId) external view returns (uint256);
}