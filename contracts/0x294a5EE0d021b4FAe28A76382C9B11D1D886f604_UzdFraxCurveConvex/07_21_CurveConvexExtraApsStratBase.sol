//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './CurveConvexApsStratBase.sol';
import "../../../curve/convex/interfaces/IConvexRewards.sol";

abstract contract CurveConvexExtraApsStratBase is Context, CurveConvexApsStratBase {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public token;
    IERC20Metadata public extraRewardToken;
    IConvexRewards public extraRewards;
    address[] extraTokenSwapPath;

    uint256 public decimalsMultiplier;

    constructor(
        Config memory config,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID,
        address tokenAddr,
        address extraRewardsAddr,
        address extraRewardTokenAddr
    ) CurveConvexApsStratBase(config, poolLPAddr, rewardsAddr, poolPID) {
        token = IERC20Metadata(tokenAddr);
        if (extraRewardTokenAddr != address(0)) {
            extraRewardToken = IERC20Metadata(extraRewardTokenAddr);
        }
        extraRewards = IConvexRewards(extraRewardsAddr);

       decimalsMultiplier = calcTokenDecimalsMultiplier(token);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + cvx x cvxPrice + _config.crv * crvPrice + extraToken * extraTokenPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual override returns (uint256) {
        uint256 extraEarningsFeeToken = 0;
        if (address(extraRewardToken) != address(0)) {
            uint256 amountIn = extraRewards.earned(address(this)) +
                extraRewardToken.balanceOf(address(this));
            extraEarningsFeeToken = rewardManager.valuate(
                address(extraRewardToken),
                amountIn,
                Constants.USDC_ADDRESS
            );
        }

        return
            super.totalHoldings() +
            extraEarningsFeeToken * 12 + // 18 - 6
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

        extraRewardToken.transfer(address(rewardManager), extraBalance);
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
        cvxRewards.withdrawAllAndUnwrap(true);

        sellRewards();

        withdrawAllSpecific();

        transferZunamiAllTokens();
    }

    function withdrawAllSpecific() internal virtual;

    function calcTokenDecimalsMultiplier(IERC20Metadata _token) internal view returns (uint256) {
        uint8 decimals = _token.decimals();
        require(decimals <= 18, 'Zunami: wrong token decimals');
        if (decimals == 18) return 1;
        return 10**(18 - decimals);
    }
}