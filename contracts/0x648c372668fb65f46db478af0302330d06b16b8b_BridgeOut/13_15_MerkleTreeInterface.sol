pragma solidity >=0.5.0;

interface IMerkleTree {
    function createSpace(
        bytes32 regimentId,
        uint256 pathLength
    ) external returns (bytes32);

    function merkleProof(
        bytes32 spaceId,
        uint256 _treeIndex,
        bytes32 _leafHash,
        bytes32[] calldata _merkelTreePath,
        bool[] calldata _isLeftNode
    ) external view returns (bool);

    function getLeafLocatedMerkleTreeIndex(
        bytes32 spaceId,
        uint256 leaf_index
    ) external view returns (uint256);

    function getMerklePath(
        bytes32 spaceId,
        uint256 leafNodeIndex
    )
        external
        view
        returns (
            uint256 treeIndex,
            uint256 pathLength,
            bytes32[] memory neighbors,
            bool[] memory positions
        );

    function recordMerkleTree(
        bytes32 spaceId,
        bytes32[] memory leafNodeHash
    ) external returns (uint256);
}