/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2023 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title OGN Distributor contract
 * @notice Allows users to claim tokens based on a merkle root
 */
contract OgnDistributor is Ownable {
    /**
     * @dev User has claimed their allocation
     * @param index Index of the claim
     * @param account Address of the user
     * @param amount Amount of tokens claimed
     */
    event Claimed(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Owner has withdrawn unclaimed tokens
     * @param amount Amount of tokens withdrawn
     */
    event UnclaimedWithdrawn(uint256 amount);

    address public immutable ogn;
    bytes32 public immutable merkleRoot;
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    mapping(uint256 => uint256) private claimedBitMap;

    error InvalidRange();
    error ClaimPeriodNotStarted();
    error ClaimPeriodEnded();
    error AlreadyClaimed();
    error InvalidProof();
    error ClaimFailed();
    error ClaimPeriodNotEnded();
    error WithdrawUnclaimedFailed();

    /**
     * @dev Constructor
     * @param _ogn Address of OGN token
     * @param _merkleRoot Merkle root of the claim tree
     * @param _startTime Start time of the claim period
     * @param _endTime End time of the claim period
     */
    constructor(
        address _ogn,
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint256 _endTime
    ) {
        if (_startTime >= _endTime) {
            revert InvalidRange();
        }

        if (_startTime <= block.timestamp) {
            revert InvalidRange();
        }

        ogn = _ogn;
        merkleRoot = _merkleRoot;
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @dev Public function to check if a claim has been made
     * @param index Index of the claim
     * @return True if the claim has already been made
     */
    function isClaimed(uint256 index) public view returns (bool) {
        return _isClaimed(index);
    }

    /**
     * @dev Internal function to check if a claim has been made
     * @param index Index of the claim
     * @return True if the claim has already been made
     */
    function _isClaimed(uint256 index) internal view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @dev Public function to check if a proof is valid
     * @param index Index of the claim
     * @param account Address of the user
     * @param amount Amount of tokens claimed
     * @param merkleProof Proof of the claim
     * @return True if the proof is valid
     */
    function isProofValid(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        return _isProofValid(index, account, amount, merkleProof);
    }

    /**
     * @dev Internal function to check if a proof is valid
     * @param index Index of the claim
     * @param account Address of the user
     * @param amount Amount of tokens claimed
     * @param merkleProof Proof of the claim
     * @return True if the proof is valid
     */
    function _isProofValid(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    /**
     * @dev Set a claim index as claimed
     * @param index Index of the claim
     */
    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @dev Lets a user claim their tokens
     * @param index Index of the claim
     * @param amount Amount of tokens being claimed
     * @param merkleProof Proof of the claim
     */
    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp < startTime) {
            revert ClaimPeriodNotStarted();
        }

        if (block.timestamp >= endTime) {
            revert ClaimPeriodEnded();
        }

        if (_isClaimed(index)) {
            revert AlreadyClaimed();
        }

        if (!_isProofValid(index, msg.sender, amount, merkleProof)) {
            revert InvalidProof();
        }

        _setClaimed(index);

        bool success = IERC20(ogn).transfer(msg.sender, amount);
        if (!success) {
            revert ClaimFailed();
        }

        emit Claimed(index, msg.sender, amount);
    }

    /**
     * @dev Lets the owner withdraw unclaimed tokens
     * @notice Can only be called after the claim period has ended
     */
    function withdrawUnclaimed() external onlyOwner {
        if (block.timestamp < endTime) {
            revert ClaimPeriodNotEnded();
        }

        uint256 unclaimed = IERC20(ogn).balanceOf(address(this));

        bool success = IERC20(ogn).transfer(msg.sender, unclaimed);
        if (!success) {
            revert WithdrawUnclaimedFailed();
        }

        emit UnclaimedWithdrawn(unclaimed);
    }
}