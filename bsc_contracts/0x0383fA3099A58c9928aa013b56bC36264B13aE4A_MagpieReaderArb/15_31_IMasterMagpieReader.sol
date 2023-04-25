// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterMagpieReader {
    // struct PoolInfo {
    //     address stakingToken; // Address of staking token contract to be staked.
    //     uint256 allocPoint; // How many allocation points assigned to this pool. MGPs to distribute per second.
    //     uint256 lastRewardTimestamp; // Last timestamp that MGPs distribution occurs.
    //     uint256 accMGPPerShare; // Accumulated MGPs per share, times 1e12. See below.
    //     address rewarder;
    //     address helper;
    //     bool    helperNeedsHarvest;
    // }
    function poolLength() external view returns (uint256);
    function registeredToken(uint256) external view returns (address);
    function tokenToPoolInfo(address) external view returns (address, uint256, uint256, uint256, address, address, bool);
    function getPoolInfo(address) external view returns (uint256, uint256, uint256, uint256);
    function mgp() external view returns (address);
    function vlmgp() external view returns (address);
    function MPGRewardPool(address) external view returns (bool);

    function allPendingTokens(address _stakingToken, address _user)
        external view returns (
            uint256 pendingMGP,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );
    function stakingInfo(address _stakingToken, address _user)
        external
        view
        returns (uint256 stakedAmount, uint256 availableAmount);
}