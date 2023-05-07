// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Erc20C20Contract.sol";

contract Erc20C20EtherPoolContract is
Erc20C20Contract
{
    constructor(
        string[2] memory strings,
        address[7] memory addresses,
        uint256[68] memory uint256s,
        bool[25] memory bools
    ) Erc20C20Contract(strings, addresses, uint256s, bools)
    {

    }

    function tryCreatePairToken()
    internal
    override
    returns (address)
    {
        return IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), addressWETH);
    }

    function doSwapWithPool(uint256 thisTokenForSwap)
    internal
    override
    {
        uint256 halfShareLiquidity = shareLiquidity / 2;
        uint256 thisTokenForRewardToken = thisTokenForSwap * (shareLper + shareHolder) / (shareMax - shareBurn);
        uint256 thisTokenForSwapEther = thisTokenForSwap * (shareMarketing + halfShareLiquidity) / (shareMax - shareBurn);
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

        if (thisTokenForSwapEther > 0) {
            uint256 prevBalance = address(this).balance;

            swapThisTokenForEthToAccount(address(this), thisTokenForSwapEther);

            uint256 etherForShare = address(this).balance - prevBalance;

            if (shareMarketing > 0) {
                doMarketing(etherForShare * shareMarketing / (shareMarketing + halfShareLiquidity));
            }

            if (shareLiquidity > 0) {
                doLiquidity(etherForShare * halfShareLiquidity / (shareMarketing + halfShareLiquidity), thisTokenForLiquidity);
            }
        }
    }

    function doLiquidity(uint256 poolTokenOrEtherForLiquidity, uint256 thisTokenForLiquidity)
    internal
    override
    {
        addEtherAndThisTokenForLiquidityByAccount(
            addressLiquidity,
            poolTokenOrEtherForLiquidity,
            thisTokenForLiquidity
        );
    }

    function swapThisTokenForRewardTokenToAccount(address account, uint256 amount)
    internal
    override
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = addressWETH;
        path[2] = addressRewardToken;

        if (!isArbitrumCamelotRouter) {
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                account,
                block.timestamp
            );
        } else {
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                account,
                addressDead,
                block.timestamp
            );
        }
    }

    function swapThisTokenForPoolTokenToAccount(address account, uint256 amount)
    internal
    override
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = addressWETH;
        path[2] = addressPoolToken;

        if (!isArbitrumCamelotRouter) {
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                account,
                block.timestamp
            );
        } else {
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                account,
                addressDead,
                block.timestamp
            );
        }
    }

    function swapThisTokenForEthToAccount(address account, uint256 amount)
    internal
    override
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = addressWETH;

        if (!isArbitrumCamelotRouter) {
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                account,
                block.timestamp
            );
        } else {
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                account,
                addressDead,
                block.timestamp
            );
        }
    }
}