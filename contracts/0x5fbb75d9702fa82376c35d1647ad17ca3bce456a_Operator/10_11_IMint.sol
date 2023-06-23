// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.17;

interface IMint {
    function mint(address to, uint256 amount) external returns (bool);

    function safeMint(
        address creator,
        string memory _tokenURI,
        bool region
    ) external returns (uint256);

    function ownerOf(uint256 tokenId) external returns (address);
}