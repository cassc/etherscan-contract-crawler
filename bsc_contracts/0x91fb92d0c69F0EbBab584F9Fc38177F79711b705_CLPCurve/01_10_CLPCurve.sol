// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "ICryptoPool.sol";
import "ICurvePool.sol";
import "ICLPCurve.sol";
import "ICurveDepositZap.sol";
import "ICurveDepositMetapoolZap.sol";
import "CLPBase.sol";

contract CLPCurve is CLPBase, ICLPCurve {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _getContractName() internal pure override returns (string memory) {
        return "CLPCurve";
    }

    function deposit(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        CurveLPDepositParams calldata params
    ) external payable {
        _requireMsg(amounts.length == tokens.length, "amounts+tokens length not equal");
        uint256 ethAmount = 0;
        // for loop `i` cannot overflow, so we use unchecked block to save gas
        unchecked {
            for (uint256 i; i < tokens.length; ++i) {
                if (amounts[i] > 0) {
                    if (address(tokens[i]) == ETH_ADDRESS) {
                        ethAmount = amounts[i];
                    } else {
                        _approveToken(tokens[i], params.curveDepositAddress, amounts[i]);
                    }
                }
            }
        }
        if (amounts.length == 2) {
            uint256[2] memory _tokenAmounts = [amounts[0], amounts[1]];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (amounts.length == 3) {
            uint256[3] memory _tokenAmounts = [amounts[0], amounts[1], amounts[2]];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (amounts.length == 4) {
            uint256[4] memory _tokenAmounts = [amounts[0], amounts[1], amounts[2], amounts[3]];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (amounts.length == 5) {
            uint256[5] memory _tokenAmounts = [
                amounts[0],
                amounts[1],
                amounts[2],
                amounts[3],
                amounts[4]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            }
        } else if (amounts.length == 6) {
            uint256[6] memory _tokenAmounts = [
                amounts[0],
                amounts[1],
                amounts[2],
                amounts[3],
                amounts[4],
                amounts[5]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            }
        } else {
            _revertMsg("unsupported length");
        }
    }

    function withdraw(
        IERC20 LPToken,
        uint256 liquidity,
        CurveLPWithdrawParams calldata params
    ) external payable {
        if (params.lpType == CurveLPType.HELPER || params.lpType == CurveLPType.METAPOOL_HELPER) {
            _approveToken(LPToken, params.curveWithdrawAddress, liquidity);
        }
        if (params.minimumReceived.length == 2) {
            uint256[2] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 3) {
            uint256[3] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 4) {
            uint256[4] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2],
                params.minimumReceived[3]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 5) {
            uint256[5] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2],
                params.minimumReceived[3],
                params.minimumReceived[4]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 6) {
            uint256[6] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2],
                params.minimumReceived[3],
                params.minimumReceived[4],
                params.minimumReceived[5]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else {
            _revertMsg("unsupported length");
        }
    }
}