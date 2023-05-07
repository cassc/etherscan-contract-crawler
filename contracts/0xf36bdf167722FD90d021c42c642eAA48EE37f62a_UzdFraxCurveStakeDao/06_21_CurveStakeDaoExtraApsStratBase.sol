//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import "./CurveStakeDaoApsStratBase.sol";

abstract contract CurveStakeDaoExtraApsStratBase is Context, CurveStakeDaoApsStratBase {
    using SafeERC20 for IERC20Metadata;

    uint256 public constant ZUNAMI_EXTRA_TOKEN_ID = 1;

    IERC20Metadata public immutable token;
    IERC20Metadata public immutable extraRewardToken;

    uint256  decimalsMultiplier;

    constructor(
        Config memory config,
        address vaultAddr,
        address poolLpAddr,
        address tokenAddr,
        address extraRewardTokenAddr
    ) CurveStakeDaoApsStratBase(config, vaultAddr, poolLpAddr) {
        extraRewardToken = IERC20Metadata(extraRewardTokenAddr);

        token = IERC20Metadata(tokenAddr);
        decimalsMultiplier = calcTokenDecimalsMultiplier(token);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + sdt x sdtPrice + _config.crv * crvPrice + extraToken * extraTokenPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual override returns (uint256) {
        uint256 extraEarningsFeeToken = 0;
        if (address(extraRewardToken) != address(0)) {
            uint256 extraTokenEarned = vault.liquidityGauge().claimable_reward(
                address(this),
                address(extraRewardToken)
            );
            uint256 amountIn = extraTokenEarned + extraRewardToken.balanceOf(address(this));
            extraEarningsFeeToken = rewardManager.valuate(
                address(extraRewardToken),
                amountIn,
                Constants.USDC_ADDRESS
            );
        }

        return
            super.totalHoldings() +
            extraEarningsFeeToken * 12 + // USDC token multiplier 18 - 6
            token.balanceOf(address(this)) *
            decimalsMultiplier;
    }

    function sellRewardsExtra() internal virtual override {
        if (address(extraRewardToken) == address(0)) {
            return;
        }

        uint256 extraBalance = extraRewardToken.balanceOf(address(this));
        if (extraBalance == 0) {
            return;
        }

        extraRewardToken.safeTransfer(address(rewardManager), extraBalance);
        rewardManager.handle(
            address(extraRewardToken),
            extraBalance,
            Constants.USDC_ADDRESS
        );
    }

    /**
     * @dev can be called by Zunami contract.
     * This function need for moveFunds between strategies.
     */
    function withdrawAll() external virtual onlyZunami {
        vault.withdraw(vault.liquidityGauge().balanceOf(address(this)));

        sellRewards();

        withdrawAllSpecific();

        transferZunamiAllTokens();
    }

    function withdrawAllSpecific() internal virtual;
}