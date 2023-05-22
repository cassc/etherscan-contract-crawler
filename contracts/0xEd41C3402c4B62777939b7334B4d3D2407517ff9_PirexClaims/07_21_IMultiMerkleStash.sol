// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMultiMerkleStash {
    struct claimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function isClaimed(address token, uint256 index)
        external
        view
        returns (bool);

    function claim(
        address token,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    function claimMulti(address account, claimParam[] calldata claims) external;

    function updateMerkleRoot(address token, bytes32 _merkleRoot) external;

    event Claimed(
        address indexed token,
        uint256 index,
        uint256 amount,
        address indexed account,
        uint256 indexed update
    );
    event MerkleRootUpdated(
        address indexed token,
        bytes32 indexed merkleRoot,
        uint256 indexed update
    );
}