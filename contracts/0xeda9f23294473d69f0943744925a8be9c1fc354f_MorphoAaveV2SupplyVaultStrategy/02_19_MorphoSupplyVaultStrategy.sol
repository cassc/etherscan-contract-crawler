// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/morpho/IMorphoSupplyVault.sol";
import "../../interfaces/morpho/IMorphoAaveV2Lens.sol";
import "../../interfaces/morpho/IMorphoCompoundLens.sol";
import "../ERC4626Strategy.sol";

abstract contract MorphoSupplyVaultStrategy is ERC4626Strategy {
    using SafeERC20Upgradeable for IERC20Detailed;
    /// @notice address of the MorphoSupplyVault
    IMorphoAaveV2Lens public AAVE_LENS;
    /// @notice address of the MorphoSupplyVault
    IMorphoCompoundLens public COMPOUND_LENS;

    /// @notice pool token address (e.g. aDAI, cDAI)
    address public poolToken;

    /// @notice reward token address (e.g. COMP)
    /// @dev set to address(0) to skip `redeemRewards`
    address public rewardToken;

    function initialize(
        address _strategyToken,
        address _token,
        address _owner,
        address _poolToken,
        address _rewardToken
    ) public {
        AAVE_LENS = IMorphoAaveV2Lens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);
        COMPOUND_LENS = IMorphoCompoundLens(0x930f1b46e1D081Ec1524efD95752bE3eCe51EF67);
        _initialize(_strategyToken, _token, _owner);
        poolToken = _poolToken;
        rewardToken = _rewardToken;
    }

    /// @notice redeem the rewards
    /// @return rewards amount of reward that is deposited to the ` strategy`
    function redeemRewards(bytes calldata) public override onlyIdleCDO nonReentrant returns (uint256[] memory rewards) {
        address _rewardToken = rewardToken;

        // if rewardToken is not set, skip redeeming rewards
        if (_rewardToken != address(0)) {
            // claim rewards
            uint256 rewardsAmount = IMorphoSupplyVault(strategyToken).claimRewards(address(this));
            rewards = new uint256[](1);
            rewards[0] = rewardsAmount;
            // send rewards to the idleCDO
            IERC20Detailed(_rewardToken).safeTransfer(idleCDO, rewardsAmount);
        }
    }

    function getRewardTokens() external view returns (address[] memory rewards) {
        address _rewardToken = rewardToken;

        if (_rewardToken != address(0)) {
            rewards = new address[](1);
            rewards[0] = _rewardToken;
        }
    }

    /// @dev set to address(0) to skip `redeemRewards`
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }
}