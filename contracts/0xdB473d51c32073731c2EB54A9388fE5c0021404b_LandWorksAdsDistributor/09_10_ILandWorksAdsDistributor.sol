//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILandWorksAdsDistributor {
    event SetMerkleRoot(bytes32 indexed merkleRoot);
    event Claim(address indexed account, uint256 indexed amount);

    /// @notice Thrown if address has already claimed
    error AlreadyClaimed();
    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();

    function token() external view returns (IERC20);

    function merkleRoot() external view returns (bytes32);

    function claimed(address) external view returns (uint256);

    function setMerkleRoot(bytes32) external;

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}