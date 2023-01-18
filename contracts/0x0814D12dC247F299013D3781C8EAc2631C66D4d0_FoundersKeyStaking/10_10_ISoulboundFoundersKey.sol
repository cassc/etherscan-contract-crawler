// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISoulboundFoundersKey {
    function safeMint(address _to, uint256 _tokenId) external;
    function burn(uint256 _tokenId) external;
}