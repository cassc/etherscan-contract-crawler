//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iKobolds {
    function batchStake(uint256[] calldata tokenIds) external;

    function batchUnstake(uint256[] calldata tokenIds) external;

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function checkIfBatchIsStaked(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory linkedStatus);
}