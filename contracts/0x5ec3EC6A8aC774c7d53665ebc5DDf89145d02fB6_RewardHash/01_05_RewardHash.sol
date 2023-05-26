// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IRewardHash.sol";

contract RewardHash is IRewardHash, Ownable {
    using SafeMath for uint256;

    mapping(uint256 => CycleHashTuple) public override cycleHashes;
    uint256 public latestCycleIndex;
    
    constructor() public { 
        latestCycleIndex = 0;
    }

    function setCycleHashes(uint256 index, string calldata latestClaimableIpfsHash, string calldata cycleIpfsHash) external override onlyOwner {
        require(bytes(latestClaimableIpfsHash).length > 0, "Invalid latestClaimableIpfsHash");
        require(bytes(cycleIpfsHash).length > 0, "Invalid cycleIpfsHash");

        cycleHashes[index] = CycleHashTuple(latestClaimableIpfsHash, cycleIpfsHash);

        if (index >= latestCycleIndex) {
            latestCycleIndex = index;
        }

        emit CycleHashAdded(index, latestClaimableIpfsHash, cycleIpfsHash);
    }
}