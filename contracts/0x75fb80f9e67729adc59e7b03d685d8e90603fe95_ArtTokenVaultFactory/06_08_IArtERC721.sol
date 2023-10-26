//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IArtERC721 {
    function initialize(string memory name, string memory symbol) external;

    function mintItem(
        address owner,
        string memory tokenURI
    ) external returns (uint256);

    function setArtToken(address artToken) external;

    function burnItem(uint256 tokenId) external;

    function transferOwnership(address newOwner) external;

    function onArtTokenTransfer(address from, uint256 fromBalance, address to, uint256 toBalance) external;

}