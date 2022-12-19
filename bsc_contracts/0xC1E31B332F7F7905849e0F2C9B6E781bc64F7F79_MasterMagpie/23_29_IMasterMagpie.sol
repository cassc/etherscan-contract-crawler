// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterMagpie {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(uint256 _allocPoint, address _stakingTokenToken, address _rewarder, address _helper, bool _helperNeedsHarvest) external;

    function set(address _stakingToken, uint256 _allocPoint, address _helper,
        address _rewarder, bool _helperNeedsHarvest) external;

    function createRewarder(address _stakingTokenToken, address mainRewardToken) external
        returns (address);

    // View function to see pending GMPs on frontend.
    function getPoolInfo(address token) external view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function rewarderBonusTokenInfo(address _stakingToken) external view
        returns (address[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function pendingTokens(address _stakingToken, address _user, address token) external view
        returns (
            uint256 _pendingGMP,
            address _bonusTokenAddress,
            string memory _bonusTokenSymbol,
            uint256 _pendingBonusToken
        );

    function allPendingTokens(address _stakingToken, address _user)external view
        returns (
            uint256 pendingMGP,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function massUpdatePools() external;

    function updatePool(address _stakingToken) external;

    function deposit(address _stakingToken, uint256 _amount) external;

    function withdraw(address _stakingToken, uint256 _amount) external;

    function depositFor(address _stakingToken, uint256 _amount, address sender) external;

    function withdrawFor(address _stakingToken, uint256 _amount, address _sender ) external;

    function depositVlMGPFor(uint256 _amount, address sender) external;

    function withdrawVlMGPFor(uint256 _amount, address sender) external;

    function multiclaimFor(address[] calldata _stakingTokens, address[][] calldata _rewardTokens, address user_address) external;

    function multiclaimOnBehalf(address[] memory _stakingTokens, address[][] calldata _rewardTokens, address user_address) external;

    function emergencyWithdraw(address _stakingToken, address sender) external;

    function updateEmissionRate(uint256 _gmpPerSec) external;

    function stakingInfo(address _stakingToken, address _user)
        external
        view
        returns (uint256 depositAmount, uint256 availableAmount);
}