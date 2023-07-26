// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

// contracts
import "./FarmingRange.sol";
import "./Staking.sol";

// libraries
import "../core/libraries/TransferHelper.sol";

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRewardManager.sol";

/**
 * @title RewardManager
 * @notice RewardManager handles the creation of the contract staking and farming, automatically create a campaignInfo
 * in the farming for the staking, at slot 0 and initialize farming. The RewardManager is the owner of the funds in
 * the FarmingRange, only the RewardManager is capable of sending funds to be farmed and only the RewardManager will get
 * the funds back when updating of removing campaigns.
 */
contract RewardManager is IRewardManager {
    bytes4 private constant TRANSFER_OWNERSHIP_SELECTOR = bytes4(keccak256(bytes("transferOwnership(address)")));

    IFarmingRange public immutable farming;
    IStaking public immutable staking;

    /**
     * @param _farmingOwner address who will own the farming
     * @param _smardexToken address of the smardex token
     * @param _startFarmingCampaign block number the staking pool in the farming will start to give rewards
     */
    constructor(address _farmingOwner, IERC20 _smardexToken, uint256 _startFarmingCampaign) {
        require(_startFarmingCampaign > block.number, "RewardManager:start farming is in the past");
        farming = new FarmingRange(address(this));
        staking = new Staking(_smardexToken, farming);
        farming.addCampaignInfo(staking, _smardexToken, _startFarmingCampaign);
        staking.initializeFarming();

        address(farming).call(abi.encodeWithSelector(TRANSFER_OWNERSHIP_SELECTOR, _farmingOwner));
    }

    /// @inheritdoc IRewardManagerL2
    function resetAllowance(uint256 _campaignId) external {
        require(_campaignId < farming.campaignInfoLen(), "RewardManager:campaignId:wrong campaign ID");

        (, IERC20 _rewardToken, , , , , ) = farming.campaignInfo(_campaignId);

        // In case of tokens like USDT, an approval must be set to zero before setting it to another value.
        // Unlike most tokens, USDT does not ignore a non-zero current allowance value, leading to a possible
        // transaction failure when you are trying to change the allowance.
        if (_rewardToken.allowance(address(this), address(farming)) != 0) {
            TransferHelper.safeApprove(address(_rewardToken), address(farming), 0);
        }

        // After ensuring that the allowance is zero (or it was zero to begin with), we then set the allowance to max.
        TransferHelper.safeApprove(address(_rewardToken), address(farming), type(uint256).max);
    }
}