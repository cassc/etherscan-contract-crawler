// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IExplicitTokenIdNFT {
    function mintWithTokenId(address to, uint256 tokenId, bool useSafeMint) external;
}