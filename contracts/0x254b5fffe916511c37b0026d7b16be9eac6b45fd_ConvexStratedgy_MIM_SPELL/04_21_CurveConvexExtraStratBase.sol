//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../utils/Constants.sol';
import '../interfaces/ICurvePool_Mk3.sol';
import '../interfaces/IConvexRewards.sol';
import './CurveConvexStratBase.sol';

abstract contract CurveConvexExtraStratBase is Context, CurveConvexStratBase {
    using SafeERC20 for IERC20Metadata;

    uint256 public constant DSF_EXTRA_TOKEN_ID = 3;

    IERC20Metadata public token;
    IERC20Metadata public extraToken;
    IConvexRewards public extraRewards;
    address[] extraTokenSwapPath;

    constructor(
        Config memory config,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID,
        address tokenAddr,
        address extraRewardsAddr,
        address extraTokenAddr
    ) CurveConvexStratBase(config, poolLPAddr, rewardsAddr, poolPID) {
        token = IERC20Metadata(tokenAddr);
        if (extraTokenAddr != address(0)) {
            extraToken = IERC20Metadata(extraTokenAddr);
            extraTokenSwapPath = [extraTokenAddr, Constants.WETH_ADDRESS, Constants.USDT_ADDRESS];
        }
        extraRewards = IConvexRewards(extraRewardsAddr);

        decimalsMultipliers[DSF_EXTRA_TOKEN_ID] = calcTokenDecimalsMultiplier(token);
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * return amount is lpBalance x lpPrice + cvx x cvxPrice + _config.crv * crvPrice + extraToken * extraTokenPrice.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual override returns (uint256) {
        uint256 extraEarningsUSDT = 0;
        if (address(extraToken) != address(0)) {
            uint256 amountIn = extraRewards.earned(address(this)) +
                extraToken.balanceOf(address(this));
            extraEarningsUSDT = priceTokenByExchange(amountIn, extraTokenSwapPath);
        }

        return
            super.totalHoldings() +
            extraEarningsUSDT *
            decimalsMultipliers[DSF_USDT_TOKEN_ID] +
            token.balanceOf(address(this)) *
            decimalsMultipliers[DSF_EXTRA_TOKEN_ID];
    }

    function sellRewards() internal override {
        super.sellRewards();
        if (address(extraToken) != address(0)) {
            sellExtraToken();
        }
    }

    /**
     * @dev sell extra reward token on strategy can be called by anyone
     */
    function sellExtraToken() public {
        uint256 extraBalance = extraToken.balanceOf(address(this));
        if (extraBalance == 0) {
            return;
        }

        uint256 usdtBalanceBefore = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));

        extraToken.safeApprove(address(_config.router), extraToken.balanceOf(address(this)));
        _config.router.swapExactTokensForTokens(
            extraBalance,
            0,
            extraTokenSwapPath,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );

        managementFees += DSF.calcManagementFee(
            _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this)) - usdtBalanceBefore
        );

        emit SoldRewards(0, 0, extraBalance);
    }

    /**
     * @dev can be called by DSF contract.
     * This function need for moveFunds between strategys.
     */
    function withdrawAll() external virtual onlyDSF {
        cvxRewards.withdrawAllAndUnwrap(true);

        sellRewards();

        withdrawAllSpecific();

        transferDSFAllTokens();
    }

    function withdrawAllSpecific() internal virtual;
}