// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISaddleYieldDistro {
    function claim() external returns (uint256);

    function claim(
        address _user,
        bool _claim,
        bool _lock
    ) external returns (uint256);

    function admin() external view returns (address);

    function claimable(address _account) external view returns (uint256);

    function checkpoint_token() external; /// TODO Might be checkpoint_token()

    // to get the yield token from the yield distro contract
    function token() external view returns (address);

    // to get the yield token from VeSDLRewards contract
    function rewardToken() external view returns (address);

    // to get the vesdl_rewards address
    function vesdl_penalty_rewards() external view returns (address);

    // check the earned amount of VeSDLRewards
    function earned(address _account) external view returns (uint256);
}