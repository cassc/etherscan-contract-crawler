// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RetroactiveRewards is Ownable{
    using SafeERC20 for IERC20;

    IERC20 public immutable purse;
    bytes32 public immutable merkleRoot;
    uint128 public rewardStartTime;
    uint128 public rewardEndTime;

    mapping(address => bool) public isClaim;

    constructor(address token, bytes32 _merkleRoot) {
        purse = IERC20(token);
        merkleRoot = _merkleRoot;
    }

    event Claim(address user, uint256 amount);
    event UpdatedClaimPeriod(uint128 startTime, uint128 endTime);

    function updateRewardsPeriod(uint128 startTime, uint128 endTime) external onlyOwner {
        require(endTime > startTime, "endTime must be greater than startTime");
        require(endTime > block.timestamp, "Invalid timestamp");
        rewardStartTime = startTime;
        rewardEndTime = endTime;
        emit UpdatedClaimPeriod(rewardStartTime, rewardEndTime);
    }

    function claimRewards(uint256 amount, bytes32[] calldata merkleProof) external {
        require(block.timestamp >= rewardStartTime, "Claim not started");
        require(block.timestamp <= rewardEndTime, "Claim ended");
        require(!isClaim[msg.sender], "Already claimed");

        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, node), 'Invalid proof.');
        isClaim[msg.sender] = true;

        emit Claim(msg.sender, amount);
        safePurseTransfer(msg.sender, amount);
    }

    function safePurseTransfer(address to, uint256 amount) private {
        uint256 totalPurse = purse.balanceOf(address(this));
        if (amount <= totalPurse) {
            purse.transfer(to, amount);
        } else {
            require(totalPurse > 0 , "Zero balance");
            purse.transfer(to, totalPurse);
        }
    }

    function returnToken(address token, uint256 amount, address to) external onlyOwner {
        require(to != address(0), "Zero address");
        IERC20(token).safeTransfer(to, amount);
    }
}