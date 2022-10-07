// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ICollectionswap.sol";
import "./RewardPoolETH.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Collectionstaker is Ownable {
    using SafeERC20 for IERC20;

    ICollectionswap lpToken;
    uint256 public constant MAX_REWARD_TOKENS = 5;

    /// @notice Event emitted when a liquidity mining incentive has been created
    /// @param poolAddress The Reward pool address
    /// @param rewardTokens The tokens being distributed as a reward
    /// @param rewards The amount of reward tokens to be distributed
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    event IncentiveETHCreated(
        address poolAddress,
        IERC20[] rewardTokens,
        uint256[] rewards,
        uint256 startTime,
        uint256 endTime
    );

    constructor(ICollectionswap _lpToken) {
        lpToken = _lpToken;
    }

    function createIncentiveETH(
        IERC721 nft,
        address bondingCurve,
        uint128 delta,
        uint96 fee,
        IERC20[] calldata rewardTokens,
        uint256[] calldata rewards,
        uint256 startTime,
        uint256 endTime
    ) external {
        require(startTime > block.timestamp, "cannot backdate");
        uint256 rewardTokensLength = rewardTokens.length;
        require(rewardTokensLength <= MAX_REWARD_TOKENS, "too many reward tokens");
        require(rewardTokensLength == rewards.length, "unequal lengths");
        uint256[] memory rewardRates = new uint256[](rewardTokensLength);
        for (uint i; i < rewardTokensLength; ) {
            rewardRates[i] = rewards[i] / (endTime - startTime); // guaranteed endTime > startTime
            require(rewardRates[i] != 0, "0 reward rate");
            unchecked {
                ++i;
            }
        }

        RewardPoolETH rewardPool = new RewardPoolETH(
            owner(),
            msg.sender,
            lpToken,
            nft,
            bondingCurve,
            delta,
            fee,
            rewardTokens,
            rewardRates,
            startTime,
            endTime  
        );

        // transfer reward tokens to RewardPool
        for (uint i; i < rewardTokensLength; ) {
            rewardTokens[i].safeTransferFrom(
                msg.sender,
                address(rewardPool),
                rewards[i]
            );
            
            unchecked {
                ++i;
            }
        }

        emit IncentiveETHCreated(address(rewardPool), rewardTokens, rewards, startTime, endTime);
    }
}