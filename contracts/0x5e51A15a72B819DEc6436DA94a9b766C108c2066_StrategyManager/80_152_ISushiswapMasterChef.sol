// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

interface ISushiswapMasterChef {
    /*
     * @notice Struct that stores each of the user's states for each pair token
     */
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    /*
     * @notice Function that returns the state of the user regarding a specific pair token (e.g., SUSHI-WETH-USDC)
     * @param _pid Pool ID in MasterChef contract
     * @param _user User's address
     */
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    /*
     * @notice Function that returns the amount of accrued SUSHI corresponding to a specific pair token
     *        (e.g., SUSHI-WETH-USDC) that hasn't been claimed yet
     * @param _pid Pool ID in MasterChef contract
     * @param _user User address
     */
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function sushi() external view returns (address);
}