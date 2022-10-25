// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Erc20C09Contract.sol";

contract Erc20C09Erc20PoolContract is
Erc20C09Contract
{
    constructor(
        string[2] memory strings,
        address[4] memory addresses,
        uint256[67] memory uint256s,
        bool[24] memory bools
    ) Erc20C09Contract(strings, addresses, uint256s, bools)
    {

    }

    function tryCreatePairToken()
    internal
    override
    returns (address)
    {
        return IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), addressBaseToken);
    }

    function doSwapWithPool(uint256 thisTokenForSwap)
    internal
    override
    {
        uint256 thisTokenForSwapBaseToken =
        thisTokenForSwap
        * (shareMarketing + shareLper + shareHolder + (shareLiquidity / 2))
        / shareMax;

        uint256 thisTokenForLiquidity = thisTokenForSwap * (shareLiquidity / 2) / shareMax;
        uint256 thisTokenForBurn = thisTokenForSwap * shareBurn / shareMax;

        uint256 baseTokenForMarketingLperHolder;
        uint256 baseTokenForLiquidity;

        if (thisTokenForSwapBaseToken > 0) {
            swapThisTokenForBaseTokenToAccount(addressWrap, thisTokenForSwapBaseToken);

            uint256 baseTokenForShare = IERC20(addressBaseToken).balanceOf(addressWrap);

            baseTokenForMarketingLperHolder =
            baseTokenForShare
            * (shareMarketing + shareLper + shareHolder)
            / (shareMarketing + shareLper + shareHolder + (shareLiquidity / 2));

            baseTokenForLiquidity = baseTokenForShare - baseTokenForMarketingLperHolder;
        }

        if (baseTokenForMarketingLperHolder > 0) {
            if (shareMarketing > 0) {
                doMarketing(baseTokenForMarketingLperHolder * shareMarketing / (shareMarketing + shareLper + shareHolder));
            }

            if (isUseFeatureLper && shareLper > 0) {
                doLper(baseTokenForMarketingLperHolder * shareLper / (shareMarketing + shareLper + shareHolder));
            }

            if (isUseFeatureHolder && shareHolder > 0) {
                doHolder(baseTokenForMarketingLperHolder * shareHolder / (shareMarketing + shareLper + shareHolder));
            }
        }

        if (shareLiquidity > 0 && baseTokenForLiquidity > 0 && thisTokenForLiquidity > 0) {
            doLiquidity(baseTokenForLiquidity, thisTokenForLiquidity);
        }

        if (shareBurn > 0 && thisTokenForBurn > 0) {
            doBurn(thisTokenForBurn);
        }
    }

    function doLiquidity(uint256 baseTokenOrEtherForLiquidity, uint256 thisTokenForLiquidity)
    internal
    override
    {
        IERC20(addressBaseToken).transferFrom(addressWrap, address(this), baseTokenOrEtherForLiquidity);

        addBaseTokenAndThisTokenForLiquidityByAccount(
            addressBaseOwner,
            baseTokenOrEtherForLiquidity,
            thisTokenForLiquidity
        );
    }

    function swapThisTokenForBaseTokenToAccount(address account, uint256 amount)
    internal
    override
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = addressBaseToken;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            account,
            block.timestamp
        );
    }

    function swapThisTokenForEthToAccount(address account, uint256 amount)
    internal
    override
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = addressBaseToken;
        path[2] = addressWETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            account,
            block.timestamp
        );
    }
}