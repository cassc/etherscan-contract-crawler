// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenAutoMarket {
    function mint(string memory tokenURI) external returns (uint256 tokenID);

    function mint(
        address minter,
        string memory tokenURI,
        uint256 price,
        address receiver,
        uint96 fee
    ) external payable returns (uint256 tokenID);

    function gift(address to, uint256 tokenID) external payable;

    function buy(uint256 tokenID) external payable;

    function open() external view returns (bool);
}