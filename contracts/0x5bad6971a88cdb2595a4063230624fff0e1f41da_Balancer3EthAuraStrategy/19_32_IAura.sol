// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBalancerVault.sol";

interface IAura {
    function stake(
        uint256 amount
    ) external;

    function withdrawAndUnwrap(
        uint256 amount,
        bool claim
    ) external;

    function getReward(address _account, bool _extras) external returns (bool);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function earned(address _account) external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);

    function EMISSIONS_MAX_SUPPLY() external view returns (uint256);

    function rewardRate() external view returns (uint256);
}