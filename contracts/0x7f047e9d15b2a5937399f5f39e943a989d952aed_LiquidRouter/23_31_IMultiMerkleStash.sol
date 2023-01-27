// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IMultiMerkleStash {
    struct claimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function isClaimed(address token, uint256 index) external view returns (bool);

    function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)
        external;

    function merkleRoot(address _address) external returns (bytes32);

    function claimMulti(address account, claimParam[] calldata claims) external;

    function owner() external view returns (address);

    function updateMerkleRoot(address token, bytes32 _merkleRoot) external;
}