pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/external/aura/IAuraStaking.sol)

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAuraBooster } from "contracts/interfaces/external/aura/IAuraBooster.sol";

interface IAuraStaking {
    struct AuraPoolInfo {
        address token;
        address rewards;
        uint32 pId;
    }

    struct Position {
        uint256 staked;
        uint256 earned;
    }

    event SetAuraPoolInfo(uint32 indexed pId, address token, address rewards);
    event RecoveredToken(address token, address to, uint256 amount);
    event SetRewardsRecipient(address recipient);
    event RewardTokensSet(address[] rewardTokens);

    function bptToken() external view returns (IERC20);
    function auraPoolInfo() external view returns (
        address token,
        address rewards,
        uint32 pId
    );
    function booster() external view returns (IAuraBooster);

    function rewardsRecipient() external view returns (address);
    function rewardTokens(uint256 index) external view returns (address);
    
    function setAuraPoolInfo(uint32 _pId, address _token, address _rewards) external;

    function setRewardsRecipient(address _recipeint) external;

    function setRewardTokens(address[] memory _rewardTokens) external;

    function recoverToken(address token, address to, uint256 amount) external;
    function isAuraShutdown() external view returns (bool);

    function depositAndStake(uint256 amount) external;

    function withdrawAndUnwrap(uint256 amount, bool claim, address recipient) external;

    function withdrawAllAndUnwrap(bool claim, address recipient) external;

    function getReward(bool claimExtras) external;

    function stakedBalance() external view returns (uint256);

    /**
     * @notice The total balance of BPT owned by this contract - either staked in Aura 
     * or unstaked
     */
    function totalBalance() external view returns (uint256);

    function earned() external view returns (uint256);

    function showPositions() external view returns (Position memory position);
}