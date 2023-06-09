// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.19;

import "../../../library/util/Percent.sol";
import "../../../library/KContract.sol";
import "../../Pricing/PricingLibrary.sol";
import "../../Oracle/IOracle.sol";
import "../../Token/IToken.sol";

import "../IRewards.sol";

import "./IRewardDistributor.sol";

contract RewardDistributor is IRewardDistributor, KContract {

    bytes32 public constant override MANAGE_DISTRIBUTION_CONFIG_ROLE = keccak256('MANAGE_DISTRIBUTION_CONFIG_ROLE');

    IRewards.DistributionConfig private $config;

    /**
    * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRewardDistributor).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function distributionConfig() public override view returns (IRewards.DistributionConfig memory) {
        return $config;
    }

    function updateDistributionConfig(IRewards.DistributionConfig calldata newConfig) external override onlyRole(MANAGE_DISTRIBUTION_CONFIG_ROLE) {
        uint256 totalPercent =
            uint256(newConfig.adminPercent) +
            uint256(newConfig.processorPercent) +
            uint256(newConfig.stakingPercent) +
            uint256(newConfig.affiliatePercent) +
            uint256(newConfig.debtPercent);

        require(totalPercent <= Percent.BASE_PERCENT, 'RewardDistributor: INVALID_TOTAL_PERCENTAGE');

        emit DistributionConfigUpdate($config, newConfig, _msgSender());
        $config = newConfig;
    }

    function _distributeProfit(uint256 totalProfit, IKEI.Core memory k) internal {
        _distributeProfit(totalProfit, 0, k);
    }

    function _distributeProfit(uint256 totalProfit, IKEI.Snapshot memory k) internal {
        _distributeProfit(totalProfit, 0, k);
    }

    function _distributeProfit(uint256 totalProfit, uint256 mintExtra, IKEI.Core memory k) internal {
        return _distributeProfit(
            totalProfit,
            mintExtra,
            IOracle(k.oracle).prices().floorPrice,
            k.token,
            k.rewards
        );
    }

    function _distributeProfit(uint256 totalProfit, uint256 mintExtra, IKEI.Snapshot memory k) internal {
        return _distributeProfit(
            totalProfit,
            mintExtra,
            IOracle(k.oracle).prices().floorPrice,
            k.token,
            k.rewards
        );
    }

    function _distributeProfit(
        uint256 totalProfit,
        uint256 floorPrice,
        address token,
        address rewards
    ) internal {
        return _distributeProfit(
            totalProfit,
            0,
            floorPrice,
            token,
            rewards
        );
    }

    function _distributeProfit(
        uint256 totalProfit,
        uint256 mintExtra,
        uint256 floorPrice,
        address token,
        address rewards
    ) internal {
        uint256 totalTokens = PricingLibrary.baseToTokens(floorPrice, totalProfit);
        uint256 toMint = totalTokens + mintExtra;

        if (toMint > 0) {
            IToken(token).mint(toMint);
        }
        if (totalTokens > 0) {
            IRewards(rewards).sync(totalTokens, $config);
        }
    }

    function _distributeProfitTokens(uint256 totalTokens, IKEI.Core memory k) internal {
        IRewards(k.rewards).sync(totalTokens, $config);
    }
}