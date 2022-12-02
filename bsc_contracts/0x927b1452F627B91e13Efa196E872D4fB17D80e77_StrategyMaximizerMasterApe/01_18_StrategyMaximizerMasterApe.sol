// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Discord:         https://discord.com/invite/apeswap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseBananaMaximizerStrategy.sol";
import "../libs/IVaultApe.sol";
import "../libs/IBananaVault.sol";
import "../libs/IMasterApeV2.sol";
import "../libs/IUniRouter02.sol";
import "../libs/IStrategyMaximizerMasterApe.sol";
import "../libs/IMaximizerVaultApe.sol";

/// @title Strategy Maximizer - MasterApe V2
/// @author ApeSwapFinance
/// @notice MasterApe strategy for maximizer vaults
/// @dev This contract is used to interface with the MasterApeV2 contract
contract StrategyMaximizerMasterApe is BaseBananaMaximizerStrategy {
    using SafeERC20 for IERC20;

    // Farm info
    IMasterApeV2 public immutable STAKE_TOKEN_FARM;
    uint256 public immutable FARM_PID;
    bool public immutable IS_BANANA_STAKING;

    constructor(
        address _masterApe,
        uint256 _farmPid,
        bool _isBananaStaking,
        address _stakedToken,
        address _farmRewardToken,
        address _bananaVault,
        address _router,
        address[] memory _pathToBanana,
        address[] memory _pathToWbnb,
        address[] memory _addresses //[_owner, _vaultApe]
    )
        BaseBananaMaximizerStrategy(
            _stakedToken,
            _farmRewardToken,
            _bananaVault,
            _router,
            _pathToBanana,
            _pathToWbnb,
            _addresses
        )
    {
        STAKE_TOKEN_FARM = IMasterApeV2(_masterApe);
        FARM_PID = _farmPid;
        IS_BANANA_STAKING = _isBananaStaking;
    }

    /// @notice total staked tokens of vault in farm
    /// @return total staked tokens of vault in farm
    function totalStake() public view override returns (uint256) {
        (uint256 amount, ) = STAKE_TOKEN_FARM.userInfo(FARM_PID, address(this));
        return amount;
    }

    /// @notice Handle deposits for this strategy
    /// @param _amount Amount to deposit
    function _vaultDeposit(uint256 _amount) internal override {
        _approveTokenIfNeeded(STAKE_TOKEN, _amount, address(STAKE_TOKEN_FARM));
        if (IS_BANANA_STAKING) {
            STAKE_TOKEN_FARM.deposit(0, _amount);
        } else {
            STAKE_TOKEN_FARM.deposit(FARM_PID, _amount);
        }
    }

    /// @notice Handle withdraw of this strategy
    /// @param _amount Amount to remove from staking
    function _vaultWithdraw(uint256 _amount) internal override {
        if (IS_BANANA_STAKING) {
            STAKE_TOKEN_FARM.withdraw(0, _amount);
        } else {
            STAKE_TOKEN_FARM.withdraw(FARM_PID, _amount);
        }
    }

    /// @notice Handle harvesting of this strategy
    function _vaultHarvest() internal override {
        if (IS_BANANA_STAKING) {
            STAKE_TOKEN_FARM.deposit(0, 0);
        } else {
            STAKE_TOKEN_FARM.deposit(FARM_PID, 0);
        }
    }

    /// @notice Using total rewards as the input, find the output based on the path provided
    /// @param _path Array of token addresses which compose the path from index 0 to n
    /// @return Reward output amount based on path
    function _getExpectedOutput(address[] memory _path)
        internal
        view
        override
        returns (uint256)
    {
        uint256 rewards = _rewardTokenBalance() +
            (STAKE_TOKEN_FARM.pendingBanana(FARM_PID, address(this)));
        return _getExpectedOutputAmount(_path, rewards);
    }

    /// @notice Handle emergency withdraw of this strategy without caring about rewards. EMERGENCY ONLY.
    function _emergencyVaultWithdraw() internal override {
        STAKE_TOKEN_FARM.emergencyWithdraw(FARM_PID);
    }

    function _beforeDeposit(address _to) internal override {}

    function _beforeWithdraw(address _to) internal override {}
}