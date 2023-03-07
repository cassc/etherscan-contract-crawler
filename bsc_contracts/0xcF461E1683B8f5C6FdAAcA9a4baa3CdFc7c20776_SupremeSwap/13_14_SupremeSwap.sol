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
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint256 private MAX_DEPTH;
    uint256 private MAX_MIDTOKEN_LENGTH;

    function initialize(uint256 _MAX_MIDTOKEN_LENGTH, uint256 _MAX_DEPTH)
        external
        initializer
    {
        MAX_MIDTOKEN_LENGTH = _MAX_MIDTOKEN_LENGTH;
        MAX_DEPTH = _MAX_DEPTH;
    }

    receive() external payable {}

    // Swap tokens that is give in path
    function swap(SwapParams[] memory _sParams) external payable {
        uint256 pathLength = _sParams.length;
        if (pathLength == 1) {
            _sParams[0].to = address(this);
            singleSwap(_sParams[0], msg.sender);
        }
        require(
            pathLength <= MAX_DEPTH,
            "SupremeSwap: Max path length exceeded"
        );
        for (uint64 i = 0; i < pathLength; ) {
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
        if (_params.isETHSwap == true) {
            swapEthAndToken(_params);
        } else {
            require(msg.value == 0, "SupremeSwap: Invalid currency");

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
                // Check if the token supports fee on transfer or not
                if ((afterBalance - beforeBalance) != _params.amountIn) {
                    require(
                        _params.supportFee,
                        "SupremeSwap: Invalid fee flag"
                    );
                }
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
        if (_params.path[0] == WETH && _params.supportFee) {
            _params.router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: _params.amountIn
            }(_params.amountOutMin, _params.path, _params.to, _params.deadline);
        } else if (
            _params.path[0] != WETH &&
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
            _params.path[0] == WETH && !_params.supportFee && _params.inputExact
        ) {
            _params.router.swapExactETHForTokens{value: _params.amountIn}(
                _params.amountOutMin,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else if (
            _params.path[0] != WETH &&
            !_params.supportFee &&
            !_params.inputExact
        ) {
            _params.router.swapTokensForExactETH(
                _params.amountOutMin,
                _params.amountIn,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else if (
            _params.path[0] == WETH &&
            !_params.supportFee &&
            !_params.inputExact
        ) {
            _params.router.swapETHForExactTokens{value: _params.amountIn}(
                _params.amountOutMin,
                _params.path,
                _params.to,
                _params.deadline
            );
        } else {
            revert("SupremeSwap: Invalid Params");
        }
    }

    function swapTokenAndToken(SwapParams memory _params) private {
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
        require(
            midTokens.length <= MAX_MIDTOKEN_LENGTH,
            "SupremeSwap: Exceeped depth list"
        );
        // TODO: require for DexList too
        (uint256 amount1, address router1) = getMaxAmount(
            dexList,
            _amountIn,
            [_inToken, _outToken]
        );
        if (response.maxAmt < amount1) {
            response.maxAmt = amount1;
            response.router[0] = router1;
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
        uint256 amountOut1;
        address router1;
        uint256 amountOut2;
        address router2;

        if (_amountIn > 0) {
            (amountOut1, router1) = getMaxAmount(
                dexList,
                _amountIn,
                [_inToken, midToken]
            );
        }

        if (amountOut1 > 0) {
            (amountOut2, router2) = getMaxAmount(
                dexList,
                amountOut1,
                [midToken, _outToken]
            );
        }

        if (response.maxAmt < amountOut2) {
            response.pathAddr1 = midToken;
            response.maxAmt1 = amountOut1;
            response.maxAmt = amountOut2;
            response.router[0] = router1;
            response.router[1] = router2;
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
        uint256[3] memory amountOut;
        address[3] memory router;

        if (_amountIn > 0) {
            (amountOut[0], router[0]) = getMaxAmount(
                dexList,
                _amountIn,
                [_inToken, midTokens_i]
            );
        }

        if (amountOut[0] > 0) {
            (amountOut[1], router[1]) = getMaxAmount(
                dexList,
                amountOut[0],
                [midTokens_i, midTokens_j]
            );
        }
        if (amountOut[1] > 0) {
            (amountOut[2], router[2]) = getMaxAmount(
                dexList,
                amountOut[1],
                [midTokens_j, _outToken]
            );
        }

        if (response.maxAmt < amountOut[2]) {
            response.pathAddr1 = midTokens_i;
            response.pathAddr2 = midTokens_j;
            response.maxAmt1 = amountOut[0];
            response.maxAmt2 = amountOut[1];
            response.maxAmt = amountOut[2];
            response.router[0] = router[0];
            response.router[1] = router[1];
            response.router[2] = router[2];
        }
    }

    // View Function
    function getMaxAmount(
        DEXParams[] calldata _param,
        uint256 _amountIn,
        address[2] memory path
    ) public view returns (uint256 maxAmount, address maxRouter) {
        address[] memory path_ = new address[](2);
        path_[0] = (path[0]);
        path_[1] = (path[1]);
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

                    if (amountOut > maxAmount) {
                        maxAmount = amountOut;
                        maxRouter = address(_param[i].router);
                    }
                }
            }
            unchecked {
                i++;
            }
        }

        return (maxAmount, maxRouter);
    }
}