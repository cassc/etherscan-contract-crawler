// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@p12/contracts-lib/contracts/access/SafeOwnable.sol";

import "src/interfaces/IRewardDistributor.sol";

contract RewardERC20Distributor is IRewardDistributor, SafeOwnable {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;
    IERC20 public immutable rewardToken;
    uint256 public claimPeriodEnds;
    BitMaps.BitMap private claimed;

    constructor(address owner_, IERC20 rewardToken_) SafeOwnable(owner_) {
        if (owner_ == address(0) || address(rewardToken_) == address(0)) {
            revert ZeroAddressSet();
        }
        rewardToken = rewardToken_;
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp >= claimPeriodEnds) {
            revert ClaimPeriodNotStartOrEnd();
        }

        if (amount > rewardToken.balanceOf(address(this))) {
            revert AmountExceedBalance();
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }
        if (isClaimed(_msgSender())) {
            revert AlreadyClaimed();
        }

        claimed.set(uint160(_msgSender()));
        rewardToken.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account address of account
     */
    function isClaimed(address account) public view returns (bool) {
        return claimed.get(uint160(account));
    }

    /**
     * @dev Sets the merkle root.
     * @param newMerkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        if (merkleRoot != bytes32(0)) {
            revert RootSetTwice();
        }
        if (newMerkleRoot == bytes32(0)) {
            revert ZeroRootSet();
        }
        merkleRoot = newMerkleRoot;
        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @dev Sets the claim period ends.
     * @param claimPeriodEnds_ The merkle root to set.
     */
    function setClaimPeriodEnds(uint256 claimPeriodEnds_) external onlyOwner {
        if (claimPeriodEnds_ <= block.timestamp) {
            revert InvalidTimestap();
        }
        claimPeriodEnds = claimPeriodEnds_;
        emit ClaimPeriodEndsChanged(claimPeriodEnds);
    }

    /**
     * @dev withdraw remaining native tokens.
     */
    function withdraw(address to) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(to, balance);
        emit WithDrawn(to, balance);
    }
}