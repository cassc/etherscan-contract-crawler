// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./libraries/CloneLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author YFLOW Team
/// @title StakingRewardsFactory
/// @notice Factory contract to create new instances
contract StakingRewardsFactory {
    using CloneLibrary for address;

    event NewStaking(address staking, address client);
    event FactoryOwnerChanged(address newowner);
    event NewStakingImplementation(address newstaking);

    address public factoryOwner;
    address public stakingImplementation;


    constructor(
        address _stakingImplementation
    )
    {
        require(_stakingImplementation != address(0), "No zero address for _stakingImplementation");

        factoryOwner = msg.sender;
        stakingImplementation = _stakingImplementation;

        emit FactoryOwnerChanged(factoryOwner);
        emit NewStakingImplementation(stakingImplementation);
    }

    function stakingMint(
        address _owner,
        address _rewardsDistribution,
        address _stakingToken,
        address _rewardToken,
        uint256 _lockTime
    )
    external
    returns(address staking)
    {
        staking = stakingImplementation.createClone();

        emit NewStaking(staking, msg.sender);

        IStakingRewardsImplementation(staking).initialize(
                _owner,
                _rewardsDistribution,
                _stakingToken,
                _rewardToken,
                _lockTime
        );
    }

    /**
     * @dev lets the owner change the current polygon implementation
     *
     * @param staking_ the address of the new implementation
    */
    function newStakingImplementation(address staking_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(staking_ != address(0), "No zero address for vesting_");

        stakingImplementation = staking_;
        emit NewStakingImplementation(staking_);
    }


    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(newOwner != address(0), "No zero address for newOwner");

        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }

    /**
     * receive function to receive funds
    */
    receive() external payable {}
}

interface IStakingRewardsImplementation {
    function initialize(
        address _owner,
        address _rewardsDistribution,
        address _stakingToken,
        address _rewardsToken,
        uint256 _lockTime
    ) external;
}