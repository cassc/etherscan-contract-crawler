// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface IXy3Nft {
    function burn(uint256 _tokenId) external;
    function mint(address _to, uint256 _tokenId) external;
}