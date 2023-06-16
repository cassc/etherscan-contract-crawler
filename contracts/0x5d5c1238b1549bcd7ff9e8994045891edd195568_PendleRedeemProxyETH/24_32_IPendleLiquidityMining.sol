// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

interface IPendleLiquidityMining {
    event RedeemLpInterests(uint256 expiry, address user, uint256 interests);
    event Funded(uint256[] _rewards, uint256 numberOfEpochs);
    event RewardsToppedUp(uint256[] _epochIds, uint256[] _rewards);
    event AllocationSettingSet(uint256[] _expiries, uint256[] _allocationNumerators);
    event Staked(uint256 expiry, address user, uint256 amount);
    event Withdrawn(uint256 expiry, address user, uint256 amount);
    event PendleRewardsSettled(uint256 expiry, address user, uint256 amount);

    /**
     * @notice fund new epochs
     */
    function fund(uint256[] calldata rewards) external;

    /**
    @notice top up rewards for any funded future epochs (but not to create new epochs)
    */
    function topUpRewards(uint256[] calldata _epochIds, uint256[] calldata _rewards) external;

    /**
     * @notice Stake an exact amount of LP_expiry
     */
    function stake(
        address to,
        uint256 expiry,
        uint256 amount
    ) external returns (address);

    /**
     * @notice Stake an exact amount of LP_expiry, using a permit
     */
    function stakeWithPermit(
        uint256 expiry,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address);

    /**
     * @notice Withdraw an exact amount of LP_expiry
     */
    function withdraw(
        address to,
        uint256 expiry,
        uint256 amount
    ) external;

    /**
     * @notice Get the pending rewards for a user
     * @return rewards Returns rewards[0] as the rewards available now, as well as rewards
     that can be claimed for subsequent epochs (size of rewards array is numberOfEpochs)
     */
    function redeemRewards(uint256 expiry, address user) external returns (uint256 rewards);

    /**
     * @notice Get the pending LP interests for a staker
     * @return dueInterests Returns the interest amount
     */
    function redeemLpInterests(uint256 expiry, address user)
        external
        returns (uint256 dueInterests);

    /**
     * @notice Let the liqMiningEmergencyHandler call to approve spender to spend tokens from liqMiningContract
     *          and to spend tokensForLpHolder from the respective lp holders for expiries specified
     */
    function setUpEmergencyMode(uint256[] calldata expiries, address spender) external;

    /**
     * @notice Read the all the expiries that user has staked LP for
     */
    function readUserExpiries(address user) external view returns (uint256[] memory expiries);

    /**
     * @notice Read the amount of LP_expiry staked for a user
     */
    function getBalances(uint256 expiry, address user) external view returns (uint256);

    function lpHolderForExpiry(uint256 expiry) external view returns (address);

    function startTime() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function totalRewardsForEpoch(uint256) external view returns (uint256);

    function numberOfEpochs() external view returns (uint256);

    function vestingEpochs() external view returns (uint256);

    function baseToken() external view returns (address);

    function underlyingAsset() external view returns (address);

    function underlyingYieldToken() external view returns (address);

    function pendleTokenAddress() external view returns (address);

    function marketFactoryId() external view returns (bytes32);

    function forgeId() external view returns (bytes32);

    function forge() external view returns (address);

    function readAllExpiriesLength() external view returns (uint256);
}