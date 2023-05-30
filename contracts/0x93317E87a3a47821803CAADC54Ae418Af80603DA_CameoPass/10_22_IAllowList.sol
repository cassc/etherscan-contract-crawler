// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAllowList {
    error NotAllowListed();
    error MaxAllowListRedemptions();

    function isAllowListed(bytes32[] calldata _proof, address _address)
        external
        view
        returns (bool);

    function setMerkleRoot(bytes32 _merkleRoot) external;
}