// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libs/NFT.sol";

interface ITMAsLocker {
    function lock(NFT.TokenStruct[] memory tokens) external;

    function unlock(NFT.TokenStruct[] memory tokens) external;

    function isLocked(address collectionAddress, uint256 tokenId)
        external
        view
        returns (bool);
}