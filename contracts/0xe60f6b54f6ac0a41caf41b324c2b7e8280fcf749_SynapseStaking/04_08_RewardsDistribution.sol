// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { Ownable } from "./Ownable.sol";

abstract contract RewardsDistributionData {
    address public rewardsDistributor;
}

abstract contract RewardsDistribution is Ownable, RewardsDistributionData {
    event RewardsDistributorChanged(address indexed previousDistributor, address indexed newDistributor);

    /**
     * @dev `rewardsDistributor` defaults to msg.sender on construction.
     */
    constructor() {
        rewardsDistributor = msg.sender;
        emit RewardsDistributorChanged(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the Reward Distributor.
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "caller is not reward distributor");
        _;
    }

    /**
     * @dev Change the rewardsDistributor - only called by owner
     * @param _rewardsDistributor Address of the new distributor
     */
    function setRewardsDistribution(address _rewardsDistributor) external onlyOwner {
        require(_rewardsDistributor != address(0), "zero address");

        emit RewardsDistributorChanged(rewardsDistributor, _rewardsDistributor);
        rewardsDistributor = _rewardsDistributor;
    }
}