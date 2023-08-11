// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { Errors } from "../../utils/Errors.sol";
import { DataTypes } from "../earn-protocol-configuration/contracts/libraries/types/DataTypes.sol";

// interfaces
import { IAdapterFull } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterFull.sol";
import { IRegistry } from "../earn-protocol-configuration/contracts/interfaces/opty/IRegistry.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title StrategyManager Library
 * @author Opty.fi
 * @notice Central processing unit of the earn protocol
 * @dev Contains the functionality for getting the codes to deposit/withdraw/claim tokens,
 * from the adapters and pass it onto vault contract
 */
library StrategyManager {
    function getDepositInternalTransactionCount(
        DataTypes.StrategyStep[] memory _strategySteps,
        address _registryContract
    ) public view returns (uint256) {
        uint256 _strategyStepCount = _strategySteps.length;
        address _lastStepLiquidityPool = _strategySteps[_strategyStepCount - 1].pool;
        bool _isSwap = _strategySteps[_strategyStepCount - 1].isSwap;
        IRegistry _registry = IRegistry(_registryContract);
        IAdapterFull _adapter =
            _isSwap
                ? IAdapterFull(_registry.getSwapPoolToAdapter(_lastStepLiquidityPool))
                : IAdapterFull(_registry.getLiquidityPoolToAdapter(_lastStepLiquidityPool));
        if (_adapter.canStake(_lastStepLiquidityPool)) {
            return (_strategyStepCount + 1);
        }
        return _strategyStepCount;
    }

    function getOraValueUT(
        DataTypes.StrategyStep[] memory _strategySteps,
        address _registryContract,
        address payable _vault,
        address _underlyingToken
    ) public view returns (uint256 _amountUT) {
        uint256 _nStrategySteps = _strategySteps.length;
        uint256 _outputTokenAmount;
        IRegistry _registry = IRegistry(_registryContract);
        for (uint256 _i; _i < _nStrategySteps; _i++) {
            uint256 _iterator = _nStrategySteps - 1 - _i;
            address _liquidityPool = _strategySteps[_iterator].pool;
            bool _isSwap = _strategySteps[_iterator].isSwap;
            IAdapterFull _adapter =
                _isSwap
                    ? IAdapterFull(_registry.getSwapPoolToAdapter(_liquidityPool))
                    : IAdapterFull(_registry.getLiquidityPoolToAdapter(_liquidityPool));
            address _inputToken = _underlyingToken;
            address _outputToken = _strategySteps[_iterator].outputToken;
            if (_iterator != 0) {
                _inputToken = _strategySteps[_iterator - 1].outputToken;
            }
            if (_iterator == (_nStrategySteps - 1)) {
                if (_adapter.canStake(_liquidityPool)) {
                    _amountUT = _adapter.getAllAmountInTokenStake(_vault, _inputToken, _liquidityPool);
                } else {
                    _amountUT = _isSwap
                        ? _adapter.getAllAmountInToken(_vault, _inputToken, _liquidityPool, _outputToken)
                        : _adapter.getAllAmountInToken(_vault, _inputToken, _liquidityPool);
                }
            } else {
                _amountUT = _isSwap
                    ? _adapter.getSomeAmountInToken(_inputToken, _liquidityPool, _outputToken, _outputTokenAmount)
                    : _adapter.getSomeAmountInToken(_inputToken, _liquidityPool, _outputTokenAmount);
            }
            _outputTokenAmount = _amountUT;
        }
    }

    function getOraSomeValueLP(
        DataTypes.StrategyStep[] memory _strategySteps,
        address _registryContract,
        address _underlyingToken,
        uint256 _wantAmountUT
    ) public view returns (uint256 _amountLP) {
        uint256 _nStrategySteps = _strategySteps.length;
        IRegistry _registry = IRegistry(_registryContract);
        for (uint256 _i; _i < _nStrategySteps; _i++) {
            address _liquidityPool = _strategySteps[_i].pool;
            bool _isSwap = _strategySteps[_i].isSwap;
            IAdapterFull _adapter =
                _isSwap
                    ? IAdapterFull(_registry.getSwapPoolToAdapter(_liquidityPool))
                    : IAdapterFull(_registry.getLiquidityPoolToAdapter(_liquidityPool));
            address _inputToken = _underlyingToken;
            if (_i != 0) {
                _inputToken = _strategySteps[_i - 1].outputToken;
            }
            _amountLP = _isSwap
                ? _adapter.calculateAmountInLPToken(
                    _inputToken,
                    _liquidityPool,
                    _strategySteps[_i].outputToken,
                    _i == 0 ? _wantAmountUT : _amountLP
                )
                : _adapter.calculateAmountInLPToken(_inputToken, _liquidityPool, _i == 0 ? _wantAmountUT : _amountLP);
            // the _amountLP will be actually _wantAmountUT for _i+1th step
        }
    }

    function getPoolDepositCodes(
        DataTypes.StrategyStep[] memory _strategySteps,
        DataTypes.StrategyConfigurationParams memory _strategyConfigurationParams
    ) public view returns (bytes[] memory _codes) {
        IRegistry _registryContract = IRegistry(_strategyConfigurationParams.registryContract);
        address _underlyingToken = _strategyConfigurationParams.underlyingToken;
        uint256 _depositAmountUT = _strategyConfigurationParams.initialStepInputAmount;
        uint256 _stepCount = _strategySteps.length;
        if (_strategyConfigurationParams.internalTransactionIndex == _stepCount) {
            address _liquidityPool = _strategySteps[_strategyConfigurationParams.internalTransactionIndex - 1].pool;
            IAdapterFull _adapter = IAdapterFull(_registryContract.getLiquidityPoolToAdapter(_liquidityPool));
            _underlyingToken = _strategySteps[_strategyConfigurationParams.internalTransactionIndex - 1].outputToken;
            _depositAmountUT = IERC20(_strategyConfigurationParams.underlyingToken).balanceOf(
                _strategyConfigurationParams.vault
            );
            _codes = _adapter.getStakeAllCodes(
                _strategyConfigurationParams.vault,
                _strategyConfigurationParams.underlyingToken,
                _liquidityPool
            );
        } else {
            address _liquidityPool = _strategySteps[_strategyConfigurationParams.internalTransactionIndex].pool;
            bool _isSwap = _strategySteps[_strategyConfigurationParams.internalTransactionIndex].isSwap;
            IAdapterFull _adapter =
                _isSwap
                    ? IAdapterFull(_registryContract.getSwapPoolToAdapter(_liquidityPool))
                    : IAdapterFull(_registryContract.getLiquidityPoolToAdapter(_liquidityPool));
            if (_strategyConfigurationParams.internalTransactionIndex != 0) {
                _underlyingToken = _strategySteps[_strategyConfigurationParams.internalTransactionIndex - 1]
                    .outputToken;
                _depositAmountUT = IERC20(_underlyingToken).balanceOf(_strategyConfigurationParams.vault);
            }
            _codes = _isSwap
                ? _adapter.getDepositSomeCodes(
                    _strategyConfigurationParams.vault,
                    _underlyingToken,
                    _liquidityPool,
                    _strategySteps[_strategyConfigurationParams.internalTransactionIndex].outputToken,
                    _depositAmountUT
                )
                : _adapter.getDepositSomeCodes(
                    _strategyConfigurationParams.vault,
                    _underlyingToken,
                    _liquidityPool,
                    _depositAmountUT
                );
        }
    }

    function getPoolWithdrawCodes(
        DataTypes.StrategyStep[] memory _strategySteps,
        DataTypes.StrategyConfigurationParams memory _strategyConfigurationParams
    ) public view returns (bytes[] memory _codes) {
        address _liquidityPool = _strategySteps[_strategyConfigurationParams.internalTransactionIndex].pool;
        IRegistry _registryContract = IRegistry(_strategyConfigurationParams.registryContract);
        bool _isSwap = _strategySteps[_strategyConfigurationParams.internalTransactionIndex].isSwap;
        IAdapterFull _adapter =
            _isSwap
                ? IAdapterFull(_registryContract.getSwapPoolToAdapter(_liquidityPool))
                : IAdapterFull(_registryContract.getLiquidityPoolToAdapter(_liquidityPool));
        address _underlyingToken = _strategyConfigurationParams.underlyingToken;
        uint256 _redeemAmountLP = _strategyConfigurationParams.initialStepInputAmount;
        if (_strategyConfigurationParams.internalTransactionIndex != 0) {
            _underlyingToken = _strategySteps[_strategyConfigurationParams.internalTransactionIndex - 1].outputToken;
        }
        if (
            _strategyConfigurationParams.internalTransactionIndex !=
            (_strategyConfigurationParams.internalTransactionCount - 1)
        ) {
            _redeemAmountLP = IERC20(_strategySteps[_strategyConfigurationParams.internalTransactionIndex].outputToken)
                .balanceOf(_strategyConfigurationParams.vault);
        }
        _codes = (_strategyConfigurationParams.internalTransactionIndex ==
            (_strategyConfigurationParams.internalTransactionCount - 1) &&
            _adapter.canStake(_liquidityPool))
            ? _adapter.getUnstakeAndWithdrawSomeCodes(
                _strategyConfigurationParams.vault,
                _underlyingToken,
                _liquidityPool,
                _redeemAmountLP
            )
            : _isSwap
            ? _adapter.getWithdrawSomeCodes(
                _strategyConfigurationParams.vault,
                _underlyingToken,
                _liquidityPool,
                _strategySteps[_strategyConfigurationParams.internalTransactionIndex].outputToken,
                _redeemAmountLP
            )
            : _adapter.getWithdrawSomeCodes(
                _strategyConfigurationParams.vault,
                _underlyingToken,
                _liquidityPool,
                _redeemAmountLP
            );
    }

    function getLastStrategyStepBalanceLP(
        DataTypes.StrategyStep[] memory _strategySteps,
        address _registryContract,
        address payable _vault,
        address _underlyingToken
    ) public view returns (uint256) {
        IRegistry _registry = IRegistry(_registryContract);
        uint256 _strategyStepsLen = _strategySteps.length;
        address _liquidityPool = _strategySteps[_strategySteps.length - 1].pool;
        bool _isSwap = _strategySteps[_strategySteps.length - 1].isSwap;
        IAdapterFull _adapter =
            _isSwap
                ? IAdapterFull(_registry.getSwapPoolToAdapter(_liquidityPool))
                : IAdapterFull(_registry.getLiquidityPoolToAdapter(_liquidityPool));
        address _outputToken = _strategySteps[_strategySteps.length - 1].outputToken;
        if (_strategyStepsLen > 1) {
            // underlying token for last step is previous step's output token
            _underlyingToken = _strategySteps[_strategyStepsLen - 2].outputToken;
        }
        return
            _adapter.canStake(_liquidityPool)
                ? _adapter.getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool)
                : _isSwap
                ? _adapter.getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool, _outputToken)
                : _adapter.getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool);
    }

    function getClaimRewardTokenCode(
        address _liquidityPool,
        address _registryContract,
        address payable _vault
    ) public view returns (bytes[] memory _codes) {
        IAdapterFull _adapter = _getAdapter(_registryContract, _liquidityPool);
        _checkRewardToken(_adapter, _liquidityPool);
        _codes = _adapter.getClaimRewardTokenCode(_vault, _liquidityPool);
    }

    function getUnclaimedRewardTokenAmount(
        address _liquidityPool,
        address _registryContract,
        address payable _vault,
        address _underlyingToken
    ) public view returns (uint256) {
        IAdapterFull _adapter = _getAdapter(_registryContract, _liquidityPool);
        return
            _adapter.getRewardToken(_liquidityPool) == address(0)
                ? uint256(0)
                : _adapter.getUnclaimedRewardTokenAmount(_vault, _liquidityPool, _underlyingToken);
    }

    function getRewardToken(address _liquidityPool, address _registryContract) public view returns (address) {
        IAdapterFull _adapter = _getAdapter(_registryContract, _liquidityPool);
        return _adapter.getRewardToken(_liquidityPool);
    }

    function _getAdapter(address _registryContract, address _liquidityPool) private view returns (IAdapterFull) {
        IAdapterFull _adapter = IAdapterFull(IRegistry(_registryContract).getLiquidityPoolToAdapter(_liquidityPool));
        return _adapter;
    }

    function _checkRewardToken(IAdapterFull _adapter, address _liquidityPool) private view {
        require(_adapter.getRewardToken(_liquidityPool) != address(0), Errors.NOTHING_TO_CLAIM);
    }
}