// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFT {
    function mint(address _to) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}