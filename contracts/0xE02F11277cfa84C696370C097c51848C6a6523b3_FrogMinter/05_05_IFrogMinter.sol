// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFoundingFrog.sol";

interface IFrogMinter {
    struct FrogMeta {
        address beneficiary;
        uint256 tokenId;
        bytes32 imageHash;
    }

    /// @notice Mints a new founding frog given its metadata and a vaild merkle proof
    function mint(FrogMeta memory meta, bytes32[] memory proof) external;
}