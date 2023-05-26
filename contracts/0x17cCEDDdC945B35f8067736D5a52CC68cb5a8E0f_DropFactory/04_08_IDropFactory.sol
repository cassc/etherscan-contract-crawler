// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDropFactory {
    function createDrop(address tokenAddress) external;

    function addDropData(
        uint256 tokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 merkleRoot,
        address tokenAddress
    ) external;

    function updateDropData(
        uint256 additionalTokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot,
        address tokenAddress
    ) external;

    function claimFromDrop(
        address tokenAddress,
        uint256 index,
        uint256 amount,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) external;

    function multipleClaimsFromDrop(
        address tokenAddress,
        uint256[] calldata indexes,
        uint256[] calldata amounts,
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs
    ) external;

    function withdraw(address tokenAddress, bytes32 merkleRoot) external;

    function pause(address tokenAddress, bytes32 merkleRoot) external;

    function unpause(address tokenAddress, bytes32 merkleRoot) external;

    function updateFeeReceiver(address newFeeReceiver) external;

    function updateFee(uint256 newFee) external;

    function isDropClaimed(
        address tokenAddress,
        uint256 index,
        bytes32 merkleRoot
    ) external view returns (bool);

    function getDropDetails(address tokenAddress, bytes32 merkleRoot)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool
        );

    event DropCreated(address indexed dropAddress, address indexed tokenAddress);
    event DropDataAdded(address indexed tokenAddress, bytes32 merkleRoot, uint256 tokenAmount, uint256 startDate, uint256 endDate);
    event DropDataUpdated(address indexed tokenAddress, bytes32 oldMerkleRoot, bytes32 newMerkleRoot, uint256 tokenAmount, uint256 startDate, uint256 endDate);
    event DropClaimed(address indexed tokenAddress, uint256 index, address indexed account, uint256 amount, bytes32 indexed merkleRoot);
    event DropWithdrawn(address indexed tokenAddress, address indexed account, bytes32 indexed merkleRoot, uint256 amount);
    event DropPaused(bytes32 merkleRoot);
    event DropUnpaused(bytes32 merkleRoot);
}