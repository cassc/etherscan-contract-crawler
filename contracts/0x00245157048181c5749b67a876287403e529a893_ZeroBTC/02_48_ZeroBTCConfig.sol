// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ZeroBTCCache.sol";
import "../utils/Math.sol";
import { IStrategy } from "../../interfaces/IStrategy.sol";

abstract contract ZeroBTCConfig is ZeroBTCCache {
  using ModuleStateCoder for ModuleState;
  using GlobalStateCoder for GlobalState;
  using LoanRecordCoder for LoanRecord;
  using Math for uint256;

  /*//////////////////////////////////////////////////////////////
                         Governance Actions
  //////////////////////////////////////////////////////////////*/

  function setGlobalFees(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) external onlyGovernance nonReentrant {
    _setFees(zeroBorrowFeeBips, renBorrowFeeBips, zeroBorrowFeeStatic, renBorrowFeeStatic, zeroFeeShareBips);
  }

  function setModuleGasFees(
    address module,
    uint256 loanGas,
    uint256 repayGas
  ) external onlyGovernance nonReentrant {
    (GlobalState state, ) = _getUpdatedGlobalState();
    ModuleState moduleState = _getExistingModuleState(module);
    // Divide loan and repay gas by 10000
    uint256 loanGasE4 = loanGas.uncheckedDivUpE4();
    uint256 repayGasE4 = repayGas.uncheckedDivUpE4();
    moduleState = moduleState.setGasParams(loanGasE4, repayGasE4);
    _updateModuleCache(state, moduleState, module);
  }

  function addModule(
    address module,
    ModuleType moduleType,
    uint256 loanGas,
    uint256 repayGas
  ) external onlyGovernance nonReentrant {
    if (module != address(0)) {
      address moduleAsset = IZeroModule(module).asset();
      if (moduleAsset != asset) {
        revert ModuleAssetDoesNotMatch(moduleAsset);
      }
    }

    if (loanGas == 0 || repayGas == 0) {
      revert InvalidNullValue();
    }

    // Module type can not be null unless address is 0
    // If address is 0, module type must be null
    if ((moduleType == ModuleType.Null) != (module == address(0))) {
      revert InvalidModuleType();
    }

    // Divide loan and repay gas by 10000
    uint256 loanGasE4 = loanGas.uncheckedDivUpE4();
    uint256 repayGasE4 = repayGas.uncheckedDivUpE4();

    // Get updated global state, with cache refreshed if it had expired
    (GlobalState state, ) = _getUpdatedGlobalState();

    // Calculate the new gas refunds for the module
    (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    ) = _calculateModuleGasFees(state, loanGasE4, repayGasE4);

    // Write the module data to storage
    _moduleFees[module] = ModuleStateCoder.encode(
      moduleType,
      loanGasE4,
      repayGasE4,
      ethRefundForLoanGas,
      ethRefundForRepayGas,
      btcFeeForLoanGas,
      btcFeeForRepayGas,
      block.timestamp
    );

    // delegatecall initialize on the module
    (bool success, ) = module.delegatecall(abi.encodeWithSelector(IZeroModule.initialize.selector));
    require(success, "module uninitialized");

    emit ModuleStateUpdated(module, moduleType, loanGasE4, repayGasE4);
  }

  function removeModule(address module) external onlyGovernance nonReentrant {
    _moduleFees[module] = DefaultModuleState;
  }

  function setHarvesters(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _isHarvester[users[i]] = true;
  }

  function removeHarvesters(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _isHarvester[users[i]] = false;
  }

  function setAuthorizedUsers(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _authorized[users[i]] = true;
  }

  function removeAuthorizedUsers(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _authorized[users[i]] = false;
  }
}