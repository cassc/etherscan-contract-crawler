// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../IAdapter.sol";
import "../../lib/aavee/Aavee.sol";
import "../../lib/chai/ChaiExchange.sol";
import "../../lib/bprotocol/BProtocolAMM.sol";
import "../../lib/bzx/BZX.sol";
import "../../lib/smoothy/SmoothyV1.sol";
import "../../lib/uniswap/UniswapV1.sol";
import "../../lib/kyberdmm/KyberDmm.sol";
import "../../lib/jarvis/Jarvis.sol";
import "../../lib/lido/Lido.sol";
import "../../lib/makerpsm/MakerPsm.sol";
import "../../lib/augustus-rfq/AugustusRFQ.sol";
import "../../lib/synthetix/SynthetixAdapter.sol";
import "../../lib/lido/WstETH.sol";
import "../../lib/aave-v3/AaveV3.sol";
import "../../lib/hashflow/HashFlow.sol";

/**
 * @dev This contract will route call to:
 * 0 - ChaiExchange
 * 1 - UniswapV1
 * 2 - SmoothyV1
 * 3 - BZX
 * 4 - BProtocol
 * 5 - Aave
 * 6 - KyberDMM
 * 7 - Jarvis
 * 8 - Lido
 * 9 - MakerPsm
 * 10 - AugustusRFQ
 * 11 - Synthetix
 * 12 - wstETH
 * 13 - AaveV3
 * 14 - HashFlow
 * The above are the indexes
 */

contract Adapter03 is
    IAdapter,
    ChaiExchange,
    UniswapV1,
    SmoothyV1,
    BZX,
    BProtocol,
    Aavee,
    KyberDmm,
    Jarvis,
    Lido,
    MakerPsm,
    AugustusRFQ,
    Synthetix,
    WstETH,
    AaveV3,
    HashFlow
{
    using SafeMath for uint256;

    /*solhint-disable no-empty-blocks*/
    constructor(
        uint16 aaveeRefCode,
        address aaveeSpender,
        address uniswapFactory,
        address chai,
        address dai,
        address weth,
        address stETH,
        uint16 _aaveV3RefCode,
        address _aaveV3Pool,
        address _aaveV3WethGateway
    )
        public
        WethProvider(weth)
        Aavee(aaveeRefCode, aaveeSpender)
        UniswapV1(uniswapFactory)
        ChaiExchange(chai, dai)
        Lido(stETH)
        MakerPsm(dai)
        AaveV3(_aaveV3RefCode, _aaveV3Pool, _aaveV3WethGateway)
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
                //swap on ChaiExchange
                swapOnChai(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000));
            } else if (route[i].index == 1) {
                //swap on Uniswap
                swapOnUniswapV1(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000));
            } else if (route[i].index == 2) {
                //swap on Smoothy
                swapOnSmoothyV1(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 3) {
                //swap on BZX
                swapOnBzx(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].payload);
            } else if (route[i].index == 4) {
                //swap on BProtocol
                swapOnBProtocol(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 5) {
                //swap on aavee
                swapOnAavee(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 6) {
                //swap on KyberDmm
                swapOnKyberDmm(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 7) {
                //swap on Jarvis
                swapOnJarvis(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 8) {
                //swap on Lido
                swapOnLido(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 9) {
                //swap on MakerPsm
                swapOnMakerPsm(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 10) {
                //swap on augustusRFQ
                swapOnAugustusRFQ(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 11) {
                // swap on Synthetix
                swapOnSynthetix(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 12) {
                // swap on wstETH
                swapOnWstETH(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].targetExchange);
            } else if (route[i].index == 13) {
                //swap on AaveV3
                swapOnAaveV3(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].payload);
            } else if (route[i].index == 14) {
                // swap on HashFlow
                swapOnHashFlow(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else {
                revert("Index not supported");
            }
        }
    }
}