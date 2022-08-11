//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract Vesting is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;

    mapping(address => VestingStruct) public vestings;

    struct VestingStruct {
        uint256 amount;
        uint256 claimed;
        uint256 slicePeriod;
        uint256 startTime;
        uint256 duration;
    }

    event UserAdded(
        address indexed user,
        uint256 amount,
        uint256 slicePeriod,
        uint256 startTime,
        uint256 duration
    );

    event RewardClaimed(address indexed user, uint256 amount);

    /**
     * @param newToken ERC-20 token address for vesting
     */
    constructor(IERC20 newToken) {
        require(address(newToken) != address(0));
        token = newToken;
    }

    /**
     * @notice Function to add certain user for vesting
     * @param newUser Address of user
     * @param newAmount Amount allocated for user
     * @param newSlicePeriod Period for which user can get reward
     * @param newStartTime Start time of vesting
     * @param newDuration Duration of vesting
     */
    function addUser(
        address newUser,
        uint256 newAmount,
        uint256 newSlicePeriod,
        uint256 newStartTime,
        uint256 newDuration
    ) external onlyOwner {
        require(newUser != address(0), 'User isnt specified');
        require(
            vestings[newUser].amount == 0,
            'This user has been already added to vesting'
        );
        require(
            block.timestamp <= newStartTime,
            'Cant make start before block.timestamp time'
        );

        vestings[newUser] = VestingStruct({
            amount: newAmount,
            claimed: 0,
            slicePeriod: newSlicePeriod,
            startTime: newStartTime,
            duration: newDuration
        });

        emit UserAdded(newUser, newAmount, newSlicePeriod, newStartTime, newDuration);
    }

    /**
     * External function for user to claim his reward
     */
    function claim() external {
        uint256 availableTokens = available(msg.sender);
        require(availableTokens > 0, 'Cant claim zero tokens');

        vestings[msg.sender].claimed += availableTokens;
        token.safeTransfer(msg.sender, availableTokens);

        emit RewardClaimed(msg.sender, availableTokens);
    }

    /**
     * @notice Function to see how much tokens is available
     * @param newUser Address of user, which reward we want to calculate
     */
    function available(address newUser) public view returns (uint256) {
        VestingStruct memory current = vestings[newUser];

        if (current.startTime > block.timestamp) {
            return 0;
        }

        uint256 endTime = current.startTime + current.duration;

        uint256 lastTimeApplicable = block.timestamp > endTime
            ? endTime
            : block.timestamp;

        if (lastTimeApplicable == endTime) {
            return current.amount - current.claimed;
        }

        uint256 timeFromStart = lastTimeApplicable - current.startTime;

        uint256 vestedSlicePeriods = timeFromStart / current.slicePeriod;
        uint256 vestedSeconds = vestedSlicePeriods * current.slicePeriod;

        return (vestedSeconds * current.amount) / current.duration - current.claimed;
    }
}