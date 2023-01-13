//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/ILandWorksAdsDistributor.sol";

contract LandWorksAdsDistributor is
    ILandWorksAdsDistributor,
    Ownable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    IERC20 public immutable override token;
    bytes32 public override merkleRoot;

    mapping(address => uint256) public override claimed;

    constructor(address _token, bytes32 _merkleRoot) {
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;

        emit SetMerkleRoot(_merkleRoot);
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));

        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        uint256 transferAmount = amount - claimed[account];
        if (transferAmount == 0) revert AlreadyClaimed();

        claimed[account] = amount;
        token.safeTransfer(account, transferAmount);

        emit Claim(account, transferAmount);
    }
}