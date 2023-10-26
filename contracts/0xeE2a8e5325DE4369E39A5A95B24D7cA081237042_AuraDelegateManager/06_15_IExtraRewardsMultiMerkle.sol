// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IExtraRewardsMultiMerkle {
    event UpdateRoot(address indexed rewardToken, bytes32 merkleRoot, uint256 indexed nonce);
    event FrozenRoot(address indexed rewardToken, uint256 indexed nonce);

    struct ClaimParams {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function multiClaim(address account, ClaimParams[] calldata claims) external;

    function claim(
        address token,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    )
        external;

    function isClaimed(address token, uint256 index) external view returns (bool);

    function freezeRoot(address token) external;

    function updateRoot(address token, bytes32 root) external;

    function merkleRoots(address token) external view returns (bytes32);

    function rootManager() external view returns (address);
}