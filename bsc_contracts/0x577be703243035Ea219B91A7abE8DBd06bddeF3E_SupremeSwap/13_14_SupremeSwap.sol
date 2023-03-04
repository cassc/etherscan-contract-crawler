// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit} from "./interfaces/IPermit.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router.sol";
import "./interfaces/ISupport.sol";
import {SwapParams, DEXParams, Response} from "./Types/types.sol";

contract SupremeSwap is OwnableUpgradeable, PausableUpgradeable {
    event Swap(address token1, address token2, uint256 amount);
    address public WETH;

    function initialize(address _WETH) external initializer {
        WETH = _WETH;
    }

    receive() external payable {}

    // Swap tokens that is give in path
    function swap(SwapParams[] memory _sParams) external payable {
        uint256 pathLength = _sParams.length;
        if (pathLength == 1) {
            _sParams[0].to = address(this);
            singleSwap(_sParams[0], msg.sender);
        }
        require(pathLength <= 3, "Max path length exceeded");
        uint256 amountOut = _sParams[0].amountIn;
        for (uint64 i = 0; i < pathLength; ) {
            _sParams[i].amountIn = amountOut;
            if (i == pathLength - 1) {
                _sParams[i].to = address(this);
                singleSwap(_sParams[i], msg.sender);
            } else if (i == 0) {
                _sParams[i].to = msg.sender;
                singleSwap(_sParams[i], address(this));
            } else {
                _sParams[i].to = address(this);
                singleSwap(_sParams[i], _sParams[i].to);
            }
            amountOut = IERC20(_sParams[i].path[i + 1]).balanceOf(
                address(this)
            );
            unchecked {
                i++;
            }
        }
        emit Swap(
            _sParams[0].path[0],
            _sParams[pathLength - 1].path[1],
            _sParams[0].amountIn
        );
    }

    function singleSwap(SwapParams memory _params, address _to) public payable {
        if (_params.path[0] == WETH || _params.path[1] == WETH) {
            swapEthAndToken(_params);
        } else {
            require(msg.value == 0, "Invalid currency");

            if (_to != address(this)) {
                uint256 beforeBalance = IERC20(_params.path[0]).balanceOf(
                    address(this)
                );
                IERC20(_params.path[0]).transferFrom(
                    _to,
                    address(this),
                    _params.amountIn
                );
                // Use the amount that got in the contract
                uint256 afterBalance = IERC20(_params.path[0]).balanceOf(
                    address(this)
                );
                _params.amountIn = afterBalance - beforeBalance;
            }
            // this contract approving the router contract to spend _amountIn
            IERC20(_params.path[0]).approve(
                address(_params.router),
                _params.amountIn
            );
            swapTokenAndToken(_params);
        }
    }

    // Helper Functions
    function swapEthAndToken(SwapParams memory _params) public payable {
        // Eth and token pair combinations
        if (!_params.tokenForETH && _params.supportFee) {
            _params.router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: _params.amountIn
            }(_params.amountOutMin, _params.path, _params.to, _params.deadline);
        } else if (
            _params.tokenForETH == true &&
            _params.supportFee == true &&
            _params.inputExact == true
        ) {
            _params.router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _params.amountIn,
                _params.amountOutMin,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else if (
            _params.tokenForETH == false &&
            _params.supportFee == false &&
            _params.inputExact == true
        ) {
            _params.router.swapExactETHForTokens{value: _params.amountIn}(
                _params.amountOutMin,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else if (
            _params.tokenForETH == true &&
            _params.supportFee == false &&
            _params.inputExact == false
        ) {
            _params.router.swapTokensForExactETH(
                _params.amountOutMin,
                _params.amountIn,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else if (
            !_params.tokenForETH && !_params.supportFee && !_params.inputExact
        ) {
            _params.router.swapETHForExactTokens{value: _params.amountIn}(
                _params.amountOutMin,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else {
            revert("Didn't fall in any case");
        }
    }

    function swapTokenAndToken(SwapParams memory _params) internal {
        // Token to token combinations
        if (_params.supportFee) {
            _params
                .router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _params.amountIn,
                    _params.amountOutMin,
                    _params.path,
                    _params.to,
                    _params.deadline
                );
        } else if (!_params.supportFee && !_params.inputExact) {
            _params.router.swapTokensForExactTokens(
                _params.amountIn,
                _params.amountOutMin,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else if (!_params.supportFee && _params.inputExact) {
            _params.router.swapExactTokensForTokens(
                _params.amountIn,
                _params.amountOutMin,
                _params.path,
                _params.to,
                _params.deadline
            );
        }
    }

    function getBestPath(
        uint256 _amountIn,
        address _inToken,
        address _outToken,
        address[] calldata midTokens,
        DEXParams[] calldata dexList
    ) external view returns (Response memory response) {
        require(midTokens.length <= 10, "Midtoken list too big");
        // TODO: require for DexList too

        uint256[2] memory r = getMaxAmount(
            dexList,
            _amountIn,
            [_inToken, _outToken]
        );
        if (response.maxAmt < r[0]) {
            response.maxAmt = r[0];
            response.router1 = uint8(r[1]);
        }
        uint8 len = uint8(midTokens.length);

        for (uint8 i = 0; i < len; i++) {
            if (midTokens[i] != _inToken && midTokens[i] != _outToken) {
                singleCalcHelper(
                    _amountIn,
                    _inToken,
                    _outToken,
                    midTokens[i],
                    dexList,
                    response
                );
                for (uint8 j = 0; j < len; j++) {
                    if (
                        midTokens[i] != _inToken &&
                        midTokens[i] != midTokens[j] &&
                        midTokens[j] != _outToken
                    ) {
                        multiCalcHelper(
                            _amountIn,
                            _inToken,
                            _outToken,
                            midTokens[i],
                            midTokens[j],
                            dexList,
                            response
                        );
                    }
                }
            }
        }
        return response;
    }

    function singleCalcHelper(
        uint256 _amountIn,
        address _inToken,
        address _outToken,
        address midToken,
        DEXParams[] calldata dexList,
        Response memory response
    ) private view {
        uint256[2] memory amountOut1;
        uint256[2] memory amountOut2;

        (amountOut1) = getMaxAmount(dexList, _amountIn, [_inToken, midToken]);
        (amountOut2) = getMaxAmount(
            dexList,
            amountOut1[0],
            [midToken, _outToken]
        );

        if (response.maxAmt < amountOut2[0]) {
            response.pathAddr1 = midToken;
            response.maxAmt = amountOut2[0];
            response.router1 = uint8(amountOut1[1]);
            response.router2 = uint8(amountOut2[1]);
        }
    }

    function multiCalcHelper(
        uint256 _amountIn,
        address _inToken,
        address _outToken,
        address midTokens_i,
        address midTokens_j,
        DEXParams[] calldata dexList,
        Response memory response
    ) private view {
        uint256[2] memory amountOut1;
        uint256[2] memory amountOut2;
        uint256[2] memory amountOut3;

        (amountOut1) = getMaxAmount(
            dexList,
            _amountIn,
            [_inToken, midTokens_i]
        );
        (amountOut2) = getMaxAmount(
            dexList,
            amountOut1[0],
            [midTokens_i, midTokens_j]
        );
        (amountOut3) = getMaxAmount(
            dexList,
            amountOut2[0],
            [midTokens_j, _outToken]
        );

        if (response.maxAmt < amountOut3[0]) {
            response.pathAddr1 = midTokens_i;
            response.pathAddr2 = midTokens_j;
            response.maxAmt = amountOut3[0];
            response.router1 = uint8(amountOut1[1]);
            response.router2 = uint8(amountOut2[1]);
            response.router3 = uint8(amountOut3[1]);
        }
    }

    // View Function
    function getMaxAmount(
        DEXParams[] calldata _param,
        uint256 _amountIn,
        address[2] memory path
    ) public view returns (uint256[2] memory) {
        address[] memory path_;
        path_[0] = (path[0]);
        path_[1] = (path[1]);
        uint256 maxAmount;
        uint256 maxRouter;
        for (uint8 i = 0; i < _param.length; ) {
            // step1 : get pair
            address pair = _param[i].factory.getPair(path[0], path_[1]);
            if (pair != address(0)) {
                // step2 : get reserve
                (uint112 reserve0, uint112 reserve1, ) = IPair(pair)
                    .getReserves();

                //step3 : get token0 for reserve compare
                address token0 = IPair(pair).token0();

                //step4 : reserve compare
                uint256 reserve = (token0 == path_[0])
                    ? uint256(reserve0)
                    : uint256(reserve1);
                // if we have amountIn > reserves then do:
                if (reserve > _amountIn) {
                    uint256 amountOut = (
                        _param[i].router.getAmountsOut(_amountIn, path_)
                    )[1];
                    uint256 priceImpact = (amountOut * 100) /
                        (
                            (reserve == reserve0)
                                ? (reserve1 - amountOut)
                                : (reserve0 - amountOut)
                        );
                    if (priceImpact > 10) continue;
                    if (amountOut > maxAmount) {
                        maxAmount = amountOut;
                        maxRouter = i;
                    }
                }
            }
            unchecked {
                i++;
            }
        }

        return ([maxAmount, maxRouter]);
    }
}