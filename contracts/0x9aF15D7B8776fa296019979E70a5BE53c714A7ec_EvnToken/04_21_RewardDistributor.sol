pragma solidity >=0.6.0 <0.8.0;

import "./IFestakeRewardManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRewardDistributor {
    function rollAndGetDistributionAddress(address addressForRandom) external view returns(address);
    function updateRewards(address target) external returns(bool);
}

contract RewardDistributor is Ownable, IRewardDistributor {
    struct RewardPools {
        bytes pools;
    }
    RewardPools rewardPools;
    address[] rewardReceivers;

    function addNewPool(address pool)
    onlyOwner()
    external returns(bool) {
        require(pool != address(0), "RewardD: Zero address");
        require(rewardReceivers.length < 30, "RewardD: Max no of pools reached");
        IFestakeRewardManager manager = IFestakeRewardManager(pool);
        require(address(manager.rewardToken()) != address(0), "RewardD: No reward address was provided");
        rewardReceivers.push(pool);
        IFestakeRewardManager firstManager = IFestakeRewardManager(rewardReceivers[0]);
        require(firstManager.rewardToken() == manager.rewardToken(),
            "RewardD: Reward token inconsistent with current pools");
        return true;
    }

    /**
     * poolRatio is used for a gas efficient round-robbin distribution of rewards.
     * Pack a number of uint8s in poolRatios. Maximum number of pools is 14.
     * Sum of ratios must add to 100.
     */
    function updateRewardDistributionForPools(bytes calldata poolRatios)
    onlyOwner()
    external returns (bool) {
        uint sum = 0;
        uint len = rewardReceivers.length;
        for (uint i = 0; i < len; i++) {
            sum = toUint8(poolRatios, i) + sum;
        }
        require(sum == 100, "ReardD: ratios must add to 100");
        rewardPools.pools = poolRatios;
        return true;
    }

    /**
     * @dev be carefull. Randomly chooses a pool using round robbin.
     * Assuming the transaction sizes are randomly distributed, each pool gets
     * the right share of rewards in aggregate.
     * Sacrificing accuracy for reduction in gas for each transaction.
     */
    function rollAndGetDistributionAddress(address addressForRandom)
    external override view returns(address) {
        require(addressForRandom != address(0) , "RewardD: address cannot be 0");
        uint256 rand = block.timestamp * (block.difficulty == 0 ? 1 : block.difficulty) *
             (uint256(addressForRandom) >> 128) * 31 % 100;
        uint sum = 0;
        bytes memory poolRatios = rewardPools.pools;
        uint256 len = rewardReceivers.length;
        for (uint i = 0; i < len && i < poolRatios.length; i++) {
            uint poolRatio = toUint8(poolRatios, i);
            sum += poolRatio;
            if (sum >= rand && poolRatio != 0 ) {
                return rewardReceivers[i];
            }
        }
        return address(0);
    }

    function updateRewards(address target) external override returns(bool) {
        IFestakeRewardManager manager = IFestakeRewardManager(target);
        return manager.addMarginalReward();
    }

    function bytes32ToBytes(bytes32 _bytes32) private pure returns (bytes memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
    }

    function toByte32(bytes memory _bytes)
    private pure returns (bytes32) {
        bytes32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), 0))
        }

        return tempUint;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
    private pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }
}