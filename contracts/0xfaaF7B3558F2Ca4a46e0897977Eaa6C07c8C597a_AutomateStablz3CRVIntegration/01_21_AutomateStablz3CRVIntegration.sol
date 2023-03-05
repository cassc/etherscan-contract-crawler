// SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/chainlink/common/ChainLinkAutomation.sol";
import "contracts/integrations/curve/common/ICurve3CRVGauge.sol";
import "contracts/integrations/curve/common/ICurve3CRVPool.sol";
import "contracts/integrations/curve/common/ICurveSwap.sol";
import "contracts/integrations/curve/common/Stablz3CRVMetaPoolIntegration.sol";
import "contracts/fees/IStablzFeeHandler.sol";

/// @title ChainLink automation for Stablz 3CRV integrations
contract AutomateStablz3CRVIntegration is ChainLinkAutomation {

    using SafeERC20 for IERC20;

    Stablz3CRVMetaPoolIntegration public immutable integration;
    address internal constant CRV_TOKEN = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    uint public metaToken3CRVRewardThreshold = 50 ether;
    uint public crv3CRVRewardThreshold = 50 ether;
    uint public metaTokenTo3CRVSlippage = 25;
    uint public crvTo3CRVSlippage = 75;
    uint public feeSwapSlippage = 25;
    uint public constant MAX_SLIPPAGE = 500;
    uint public constant SLIPPAGE_DENOMINATOR = 10000;

    event RewardThresholdUpdated(uint metaToken3CRVRewardThreshold, uint crv3CRVRewardThreshold);
    event SlippageUpdated(uint metaTokenTo3CRVSlippage, uint crvTo3CRVSlippage, uint feeSwapSlippage);

    /// @param _integration Stablz 3CRV meta pool integration address
    /// @param _keeperRegistry Chainlink keeper registry address
    constructor(address _integration, address _keeperRegistry) ChainLinkAutomation(_keeperRegistry) {
        require(_integration != address(0), "AutomateStablz3CRVIntegration: _integration cannot be the zero address");
        integration = Stablz3CRVMetaPoolIntegration(_integration);
    }

    /// @notice Set the minimum threshold for 3CRV rewards received from harvesting each reward type
    /// @param _metaToken3CRVRewardThreshold Minimum amount required when converting meta token rewards into 3CRV
    /// @param _crv3CRVRewardThreshold Minimum amount required when converting CRV rewards into 3CRV
    function set3CRVRewardThreshold(uint _metaToken3CRVRewardThreshold, uint _crv3CRVRewardThreshold) external onlyOwner {
        metaToken3CRVRewardThreshold = _metaToken3CRVRewardThreshold;
        crv3CRVRewardThreshold = _crv3CRVRewardThreshold;
        emit RewardThresholdUpdated(metaToken3CRVRewardThreshold, crv3CRVRewardThreshold);
    }

    /// @notice Set the slippage percentage for each swap
    /// @param _metaTokenTo3CRVSlippage Meta token reward slippage when converting to 3CRV, to 2 d.p.  e.g. 0.25% -> 25
    /// @param _crvTo3CRVSlippage CRV reward slippage when converting to 3CRV, to 2 d.p. e.g. 0.25% -> 25
    /**
        @param _feeSwapSlippage 3CRV fee slippage when converting to USDT, slippage from forecast harvest is already calculated
        into the fee swap amount (when there are rewards to harvest) therefore it is recommended to set this value to a
        relatively low number, to 2 d.p. e.g. 0.25% -> 25
    */
    function setSlippage(uint _metaTokenTo3CRVSlippage, uint _crvTo3CRVSlippage, uint _feeSwapSlippage) external onlyOwner {
        require(_metaTokenTo3CRVSlippage <= MAX_SLIPPAGE, "AutomateStablz3CRVIntegration: _metaTokenTo3CRVSlippage cannot exceed the maximum slippage");
        require(_crvTo3CRVSlippage <= MAX_SLIPPAGE, "AutomateStablz3CRVIntegration: _crvTo3CRVSlippage cannot exceed the maximum slippage");
        require(_feeSwapSlippage <= MAX_SLIPPAGE, "AutomateStablz3CRVIntegration: _feeSwapSlippage cannot exceed the maximum slippage");
        metaTokenTo3CRVSlippage = _metaTokenTo3CRVSlippage;
        crvTo3CRVSlippage = _crvTo3CRVSlippage;
        feeSwapSlippage = _feeSwapSlippage;
        emit SlippageUpdated(metaTokenTo3CRVSlippage, crvTo3CRVSlippage, feeSwapSlippage);
    }

    function _performUpkeep(bytes calldata _performData) internal override {
        (bool harvestNeeded, bool handleFeeNeeded, uint[10] memory minHarvestAmounts, uint minFeeAmount) = abi.decode(
            _performData,
            (bool, bool, uint[10], uint)
        );
        if (harvestNeeded) {
            integration.harvest(minHarvestAmounts);
        }
        if (handleFeeNeeded) {
            integration.handleFee(minFeeAmount);
        }
    }

    function _checkUpkeep(bytes calldata) internal override returns (bool upkeepNeeded, bytes memory performData) {
        if (integration.oracle() == address(this)) {
            IStablzFeeHandler feeHandler = IStablzFeeHandler(integration.feeHandler());
            uint[10] memory minHarvestAmounts;
            uint metaTokenRewardsIn3CRV = _getMetaTokenRewardsIn3CRV();
            uint crvRewardsIn3CRV = _getCRVRewardsIn3CRV();
            bool harvestNeeded;
            bool handleFeeNeeded;
            uint totalFee = integration.totalUnhandledFee();
            uint minFeeAmount;
            if (metaTokenRewardsIn3CRV >= metaToken3CRVRewardThreshold) {
                upkeepNeeded = true;
                harvestNeeded = true;
                minHarvestAmounts[0] = _calculateMinAmount(metaTokenRewardsIn3CRV, metaTokenTo3CRVSlippage);
                totalFee += feeHandler.calculateFee(minHarvestAmounts[0]);
            }
            if (crvRewardsIn3CRV >= crv3CRVRewardThreshold) {
                upkeepNeeded = true;
                harvestNeeded = true;
                minHarvestAmounts[1] = _calculateMinAmount(crvRewardsIn3CRV, crvTo3CRVSlippage);
                totalFee += feeHandler.calculateFee(minHarvestAmounts[1]);
            }
            if (totalFee > 0) {
                if (integration.isShutdown()) {
                    upkeepNeeded = true;
                    handleFeeNeeded = true;
                    /// @dev min fee amount is not required in a shutdown because raw fees are transferred directly to treasury
                    minFeeAmount = 0;
                } else if (totalFee >= integration.feeHandlingThreshold()) {
                    upkeepNeeded = true;
                    handleFeeNeeded = true;
                    /**
                        @dev amount of USDT received includes the slippage from forecast harvest therefore
                        it is recommended to set the feeSwapSlippage to a relatively low amount to prevent front-running
                    */
                    minFeeAmount = _calculateMinAmount(integration.calcRewardAmount(feeHandler.usdt(), totalFee), feeSwapSlippage);
                }
            }
            performData = abi.encode(harvestNeeded, handleFeeNeeded, minHarvestAmounts, minFeeAmount);
        }
        return (upkeepNeeded, performData);
    }

    function _getCRVRewards() internal returns (uint) {
        ICurve3CRVGauge gauge = ICurve3CRVGauge(integration.CRV_GAUGE());
        uint balance = IERC20(CRV_TOKEN).balanceOf(address(integration));
        uint reward = gauge.claimable_tokens(address(integration));
        return balance + reward;
    }

    function _getCRVRewardsIn3CRV() internal returns (uint expected){
        uint rewards = _getCRVRewards();
        /// @dev get_exchange_multiple_amount does not include fees, but the fees for the route taken are small (~0.4%)
        /// it can also revert if the return value is 0 therefore a low level call is made
        ICurveSwap curveSwap = ICurveSwap(integration.CRV_SWAP());
        (bool success, bytes memory returnData) = address(curveSwap).call(
            abi.encodePacked(
                curveSwap.get_exchange_multiple_amount.selector,
                abi.encode(integration.getCRVTo3CRVRoute(), integration.getCRVTo3CRVSwapParams(), rewards)
            )
        );
        if (success) {
            (expected) = abi.decode(returnData, (uint));
        }
        return expected;
    }

    function _getMetaTokenRewards() internal view returns (uint) {
        ICurve3CRVGauge gauge = ICurve3CRVGauge(integration.CRV_GAUGE());
        uint balance = IERC20(integration.META_TOKEN()).balanceOf(address(integration));
        uint reward = gauge.claimable_reward(address(integration), integration.META_TOKEN());
        return balance + reward;
    }

    function _getMetaTokenRewardsIn3CRV() internal view returns (uint expected) {
        uint rewards = _getMetaTokenRewards();
        /// @dev get_dy reverts if rewards = 0
        if (rewards > 0) {
            expected = ICurve3CRVPool(integration.CRV_META_POOL()).get_dy(0, 1, rewards);
        }
        return expected;
    }

    function _calculateMinAmount(uint _amount, uint _slippage) internal pure returns (uint) {
        return _amount - (_amount * _slippage / SLIPPAGE_DENOMINATOR);
    }
}