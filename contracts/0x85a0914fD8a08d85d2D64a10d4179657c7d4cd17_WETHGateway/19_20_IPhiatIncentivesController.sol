// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IPhiatIncentivesController {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(address indexed user, uint256 amount);

    /**
     * @dev add asset to accumulate rewards
     * @param asset The address of the reference asset of the distribution
     */
    function addAsset(address asset) external;

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * LEGACY **************************
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The (old) balance of the user of the asset in the lending pool
     *      latest user balance (if different) can be retrieved from sender's balanceOf function
     * @param totalSupply The (old) total supply of the asset in the lending pool
     *      latest total supply (if different) can be retrieved from sender's totalSupply function
     **/
    function handleAction(
        address user,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @param asset The asset to incentivize
     * @return the user index for the asset
     */
    function getUserAssetData(address user, address asset)
        external
        view
        returns (uint256);

    /**
     * @dev claim all user rewards
     * @param user the address of the user
     */
    function claimRewards(address user) external;

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function PRECISION() external view returns (uint8);

    /**
     * @dev Gets the distribution end timestamp of the emissions
     */
    function DISTRIBUTION_END() external view returns (uint256);
}