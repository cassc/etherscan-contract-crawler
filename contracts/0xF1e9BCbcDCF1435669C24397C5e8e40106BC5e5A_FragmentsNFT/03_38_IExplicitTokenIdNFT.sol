// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IExplicitTokenIdNFT {
    function batchMintWithTokenIds(address[] calldata accounts, uint256[] calldata tokenIds, bool useSafeMint) external;
}