// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { MultiCall } from "../../utils/MultiCall.sol";
import { StrategyManager } from "../../protocol/lib/StrategyManager.sol";
import { DataTypes } from "../../protocol/earn-protocol-configuration/contracts/libraries/types/DataTypes.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract TestStrategyManager is MultiCall {
    using SafeERC20 for ERC20;
    using StrategyManager for DataTypes.StrategyStep[];

    function testGetDepositInternalTransactionCount(
        DataTypes.StrategyStep[] calldata _strategySteps,
        address _registryContract,
        uint256 _expectedValue
    ) external view returns (bool) {
        return _expectedValue == _strategySteps.getDepositInternalTransactionCount(_registryContract);
    }

    function testOraValueUT(
        DataTypes.StrategyStep[] calldata _strategySteps,
        address _registryContract,
        address payable _vault,
        address _underlyingToken,
        uint256 _expectedAmountUT
    ) external view returns (bool) {
        return _expectedAmountUT == _strategySteps.getOraValueUT(_registryContract, _vault, _underlyingToken);
    }

    function testOraSomeValueLP(
        DataTypes.StrategyStep[] calldata _strategySteps,
        address _registryContract,
        address _underlyingToken,
        uint256 _wantAmountUT,
        uint256 _expectedAmountLP
    ) external view returns (bool) {
        return
            _expectedAmountLP == _strategySteps.getOraSomeValueLP(_registryContract, _underlyingToken, _wantAmountUT);
    }

    function testGetPoolDepositCodes(
        DataTypes.StrategyStep[] calldata _strategySteps,
        DataTypes.StrategyConfigurationParams memory _strategyConfigurationParams
    ) external {
        executeCodes(_strategySteps.getPoolDepositCodes(_strategyConfigurationParams), "!deposit");
    }

    function testGetPoolWithdrawCodes(
        DataTypes.StrategyStep[] calldata _strategySteps,
        DataTypes.StrategyConfigurationParams memory _strategyConfigurationParams
    ) external {
        executeCodes(_strategySteps.getPoolWithdrawCodes(_strategyConfigurationParams), "!withdraw");
    }

    function testGetLastStrategyStepBalanceLP(
        DataTypes.StrategyStep[] memory _strategySteps,
        address _registryContract,
        address payable _vault,
        address _underlyingToken,
        uint256 _expectedBalanceLP
    ) external view returns (bool) {
        return
            _expectedBalanceLP ==
            _strategySteps.getLastStrategyStepBalanceLP(_registryContract, _vault, _underlyingToken);
    }

    function giveAllowances(ERC20[] calldata _tokens, address[] calldata _spenders) external {
        uint256 _tokensLen = _tokens.length;
        require(_tokensLen == _spenders.length, "!LENGTH_MISMATCH");
        for (uint256 _i; _i < _tokens.length; _i++) {
            _tokens[_i].safeApprove(_spenders[_i], type(uint256).max);
        }
    }

    function revokeAllowances(ERC20[] calldata _tokens, address[] calldata _spenders) external {
        uint256 _tokensLen = _tokens.length;
        require(_tokensLen == _spenders.length, "!LENGTH_MISMATCH");
        for (uint256 _i; _i < _tokens.length; _i++) {
            _tokens[_i].safeApprove(_spenders[_i], 0);
        }
    }
}