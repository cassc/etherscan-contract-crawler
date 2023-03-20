// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRewardDistributor} from "src/interfaces/IRewardDistributor.sol";

contract RewardDistributor is IRewardDistributor, Ownable {
    using BitMaps for BitMaps.BitMap;

    bytes32 public merkleRoot;
    uint256 public claimPeriodEnds;
    BitMaps.BitMap private claimed;

    constructor(address owner_) {
        _transferOwnership(owner_);
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

        if (amount > (address(this)).balance) {
            revert AmountExceedBalance();
        }

        // bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }
        if (isClaimed(uint160(_msgSender()))) {
            revert AlreadyClaimed();
        }

        claimed.set(uint160(_msgSender()));
        payable(msg.sender).transfer(amount);
        emit Claim(msg.sender, amount);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param index The index into the merkle tree.
     */
    function isClaimed(uint256 index) public view returns (bool) {
        return claimed.get(index);
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
    function withdraw() external onlyOwner {
        uint256 balance = (address(this)).balance;
        payable(msg.sender).transfer(balance);
        emit WithDrawn(msg.sender, balance);
    }

    /**
     * @dev receive native token as reward
     */
    receive() external payable {}
}