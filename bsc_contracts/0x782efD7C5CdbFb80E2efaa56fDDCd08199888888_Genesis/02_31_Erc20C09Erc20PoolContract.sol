// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Erc20C09Contract.sol";

contract Erc20C09Erc20PoolContract is
Erc20C09Contract
{
    constructor(
        string[2] memory strings,
        address[7] memory addresses,
        uint256[68] memory uint256s,
        bool[25] memory bools
    ) Erc20C09Contract(strings, addresses, uint256s, bools)
    {

    }

    function tryCreatePairToken()
    internal
    override
    returns (address)
    {
        return IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), addressPoolToken);
    }

    function doSwapWithPool(uint256 thisTokenForSwap)
    internal
    override
    {
        uint256 halfShareLiquidity = shareLiquidity / 2;
        uint256 thisTokenForRewardToken = thisTokenForSwap * (shareLper + shareHolder) / (shareMax - shareBurn);
        uint256 thisTokenForPoolToken = thisTokenForSwap * (shareMarketing + halfShareLiquidity) / (shareMax - shareBurn);
        uint256 thisTokenForLiquidity = thisTokenForSwap * halfShareLiquidity / (shareMax - shareBurn);

        if (thisTokenForRewardToken > 0) {
            swapThisTokenForRewardTokenToAccount(addressWrap, thisTokenForRewardToken);

            uint256 rewardTokenForShare = IERC20(addressRewardToken).balanceOf(addressWrap);

            if (isUseFeatureLper && shareLper > 0) {
                doLper(rewardTokenForShare * shareLper / (shareLper + shareHolder));
            }

            if (isUseFeatureHolder && shareHolder > 0) {
                doHolder(rewardTokenForShare * shareHolder / (shareLper + shareHolder));
            }
        }

        if (thisTokenForPoolToken > 0) {
            swapThisTokenForPoolTokenToAccount(addressWrap, thisTokenForPoolToken);

            uint256 poolTokenForShare = IERC20(addressPoolToken).balanceOf(addressWrap);

            if (shareMarketing > 0) {
                doMarketing(poolTokenForShare * shareMarketing / (shareMarketing + halfShareLiquidity));
            }

            if (shareLiquidity > 0) {
                doLiquidity(poolTokenForShare * halfShareLiquidity / (shareMarketing + halfShareLiquidity), thisTokenForLiquidity);
            }
        }
    }

    function doLiquidity(uint256 poolTokenOrEtherForLiquidity, uint256 thisTokenForLiquidity)
    internal
    override
    {
        IERC20(addressPoolToken).transferFrom(addressWrap, address(this), poolTokenOrEtherForLiquidity);

        addPoolTokenAndThisTokenForLiquidityByAccount(
            addressLiquidity,
            poolTokenOrEtherForLiquidity,
            thisTokenForLiquidity
        );
    }

    function swapThisTokenForRewardTokenToAccount(address account, uint256 amount)
    internal
    override
    {
        if (addressRewardToken == addressPoolToken) {
            swapThisTokenForPoolTokenToAccount(account, amount);
        } else {
            address[] memory path = new address[](4);
            path[0] = address(this);
            path[1] = addressPoolToken;
            path[2] = addressWETH;
            path[3] = addressRewardToken;

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                account,
                block.timestamp
            );
        }
    }

    function swapThisTokenForPoolTokenToAccount(address account, uint256 amount)
    internal
    override
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = addressPoolToken;

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
        path[1] = addressPoolToken;
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