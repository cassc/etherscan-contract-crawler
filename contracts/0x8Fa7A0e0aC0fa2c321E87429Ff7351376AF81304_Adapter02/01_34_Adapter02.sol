// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../IAdapter.sol";
import "../../lib/bancor/Bancor.sol";
import "../../lib/compound/Compound.sol";
import "../../lib/dodo/DODO.sol";
import "../../lib/kyber/Kyber.sol";
import "../../lib/shell/Shell.sol";
import "../../lib/weth/WethExchange.sol";
import "../..//lib/dodov2/DODOV2.sol";
import "../../lib/onebit/OneBit.sol";
import "../../lib/saddle/SaddleAdapter.sol";
import "../../lib/balancerv2/BalancerV2.sol";
import "../../lib/uniswapv2/dystopia/DystopiaUniswapV2Fork.sol";

/**
 * @dev This contract will route to:
 * 0- Bancor
 * 1- Compound
 * 2- Dodo
 * 3- Kyber
 * 4- Shell
 * 5- weth
 * 6- DODOV2
 * 7- OneBit
 * 8- SaddelAdapter
 * 9- BalancerV2
 * 10- DystopiaUniswapV2Fork
 * The above are the indexes
 */
contract Adapter02 is
    IAdapter,
    Bancor,
    Compound,
    DODO,
    Kyber,
    Shell,
    WethExchange,
    DODOV2,
    OneBit,
    SaddleAdapter,
    BalancerV2,
    DystopiaUniswapV2Fork
{
    using SafeMath for uint256;

    struct Data {
        address _bancorAffiliateAccount;
        uint256 _bancorAffiliateCode;
        address _ceth;
        address _dodoErc20ApproveProxy;
        uint256 _dodSwapLimitOverhead;
        address payable _kyberFeeWallet;
        uint256 _kyberPlatformFeeBps;
        uint256 _shellSwapLimitOverhead;
        address _weth;
    }

    /*solhint-disable no-empty-blocks*/
    constructor(Data memory data)
        public
        WethProvider(data._weth)
        Bancor(data._bancorAffiliateAccount, data._bancorAffiliateCode)
        Compound(data._ceth)
        DODO(data._dodoErc20ApproveProxy, data._dodSwapLimitOverhead)
        Kyber(data._kyberFeeWallet, data._kyberPlatformFeeBps)
        Shell(data._shellSwapLimitOverhead)
        DODOV2(data._dodSwapLimitOverhead, data._dodoErc20ApproveProxy)
    {}

    /*solhint-enable no-empty-blocks*/

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256,
        Utils.Route[] calldata route
    ) external payable override {
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].index == 0) {
                //swap on Bancor
                swapOnBancor(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 1) {
                //swap on compound
                swapOnCompound(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 2) {
                //swap on DODO
                swapOnDodo(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 3) {
                //swap on kyber
                swapOnKyber(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 4) {
                //swap on Shell
                swapOnShell(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].targetExchange);
            } else if (route[i].index == 5) {
                //swap on WETH
                swapOnWETH(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000));
            } else if (route[i].index == 6) {
                //swap on DODOV2
                swapOnDodoV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 7) {
                //swap on OneBit
                swapOnOneBit(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 8) {
                //swap on Saddle
                swapOnSaddle(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 9) {
                swapOnBalancerV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } if (route[i].index == 10) {
                swapOnDystopiaUniswapV2Fork(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].payload
                );
            } else {
                revert("Index not supported");
            }
        }
    }
}