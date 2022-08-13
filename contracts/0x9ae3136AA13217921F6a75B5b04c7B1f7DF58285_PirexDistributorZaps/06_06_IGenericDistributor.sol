// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGenericDistributor {
    function vault() external view returns (address);

    function merkleRoot() external view returns (bytes32);

    function week() external view returns (uint32);

    function frozen() external view returns (bool);

    function isClaimed(uint256 index) external view returns (bool);

    function setApprovals() external;

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    function freeze() external;

    function unfreeze() external;

    function stake() external;

    function updateMerkleRoot(bytes32 newMerkleRoot, bool unfreeze) external;

    function updateDepositor(address newDepositor) external;

    function updateAdmin(address newAdmin) external;

    function updateVault(address newVault) external;

    event DepositorUpdated(
        address indexed oldDepositor,
        address indexed newDepositor
    );

    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    event VaultUpdated(address indexed oldVault, address indexed newVault);

    event MerkleRootUpdated(bytes32 indexed merkleRoot, uint32 indexed week);
}