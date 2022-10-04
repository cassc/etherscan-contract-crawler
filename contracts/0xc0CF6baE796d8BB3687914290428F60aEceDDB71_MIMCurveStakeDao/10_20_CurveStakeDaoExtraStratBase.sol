//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../utils/Constants.sol';
import '../../interfaces/ICurvePool4.sol';
import './CurveStakeDaoStratBase.sol';

abstract contract CurveStakeDaoExtraStratBase is Context, CurveStakeDaoStratBase {
    using SafeERC20 for IERC20Metadata;

    uint256 public constant ZUNAMI_EXTRA_TOKEN_ID = 3;

    IERC20Metadata public token;
    IERC20Metadata public extraToken;
    address[] extraTokenSwapPath;

    constructor(
        Config memory config,
        address vaultAddr,
        address poolLpAddr,
        address tokenAddr,
        address extraTokenAddr,
        address[2] memory extraTokenSwapTailAddresses
    ) CurveStakeDaoStratBase(config, vaultAddr, poolLpAddr) {
        if (extraTokenAddr != address(0)) {
            extraToken = IERC20Metadata(extraTokenAddr);
            extraTokenSwapPath = [extraTokenAddr, extraTokenSwapTailAddresses[0], extraTokenSwapTailAddresses[1]];
        }

        token = IERC20Metadata(tokenAddr);
        decimalsMultipliers[ZUNAMI_EXTRA_TOKEN_ID] = calcTokenDecimalsMultiplier(token);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + sdt x sdtPrice + _config.crv * crvPrice + extraToken * extraTokenPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual override returns (uint256) {
        uint256 extraEarningsFeeToken = 0;
        if (address(extraToken) != address(0)) {
            uint256 extraTokenEarned = vault.liquidityGauge().claimable_reward(address(this), address(extraToken));
            uint256 amountIn = extraTokenEarned + extraToken.balanceOf(address(this));
            extraEarningsFeeToken = priceTokenByExchange(amountIn, extraTokenSwapPath);
        }

        return
            super.totalHoldings() +
            extraEarningsFeeToken *
            decimalsMultipliers[feeTokenId] +
            token.balanceOf(address(this)) *
            decimalsMultipliers[ZUNAMI_EXTRA_TOKEN_ID];
    }

    function sellRewardsExtra() internal override virtual {
        if (address(extraToken) == address(0)) {
            return;
        }

        uint256 extraBalance = extraToken.balanceOf(address(this));
        if (extraBalance == 0) {
            return;
        }

        extraToken.safeApprove(address(_config.router), extraToken.balanceOf(address(this)));
        _config.router.swapExactTokensForTokens(
            extraBalance,
            0,
            extraTokenSwapPath,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );
    }

    /**
     * @dev can be called by Zunami contract.
     * This function need for moveFunds between strategys.
     */
    function withdrawAll() external virtual onlyZunami {
        vault.withdraw(vault.liquidityGauge().balanceOf(address(this)));

        sellRewards();

        withdrawAllSpecific();

        transferZunamiAllTokens();
    }

    function withdrawAllSpecific() internal virtual;
}