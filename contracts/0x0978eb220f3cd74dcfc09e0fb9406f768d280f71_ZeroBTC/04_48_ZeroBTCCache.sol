// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ZeroBTCBase.sol";

abstract contract ZeroBTCCache is ZeroBTCBase {
  using ModuleStateCoder for ModuleState;
  using GlobalStateCoder for GlobalState;
  using LoanRecordCoder for LoanRecord;
  using Math for uint256;

  /*//////////////////////////////////////////////////////////////
                          External Updaters
  //////////////////////////////////////////////////////////////*/

  function pokeGlobalCache() external nonReentrant {
    _updateGlobalCache(_state);
  }

  function pokeModuleCache(address module) external nonReentrant {
    _getUpdatedGlobalAndModuleState(module);
  }

  /*//////////////////////////////////////////////////////////////
                  Internal Fee Getters and Updaters               
  //////////////////////////////////////////////////////////////*/

  function _updateGlobalCache(GlobalState state) internal returns (GlobalState) {
    uint256 satoshiPerEth = _getSatoshiPerEth();
    uint256 gweiPerGas = _getGweiPerGas();
    state = state.setCached(satoshiPerEth, gweiPerGas, block.timestamp);
    _state = state;
    emit GlobalStateCacheUpdated(satoshiPerEth, gweiPerGas);
    return state;
  }

  function _updateModuleCache(
    GlobalState state,
    ModuleState moduleState,
    address module
  ) internal returns (ModuleState) {
    // Read the gas parameters
    (uint256 loanGasE4, uint256 repayGasE4) = moduleState.getGasParams();
    // Calculate the new gas refunds for the module
    (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    ) = _calculateModuleGasFees(state, loanGasE4, repayGasE4);
    // Update the module's cache and write it to storage
    moduleState = moduleState.setCached(
      ethRefundForLoanGas,
      ethRefundForRepayGas,
      btcFeeForLoanGas,
      btcFeeForRepayGas,
      block.timestamp
    );
    _moduleFees[module] = moduleState;
    return moduleState;
  }

  function _getUpdatedGlobalState() internal returns (GlobalState state, uint256 lastUpdateTimestamp) {
    state = _state;
    lastUpdateTimestamp = state.getLastUpdateTimestamp();
    if (block.timestamp - lastUpdateTimestamp > _cacheTimeToLive) {
      state = _updateGlobalCache(state);
    }
  }

  function _getUpdatedGlobalAndModuleState(address module)
    internal
    returns (GlobalState state, ModuleState moduleState)
  {
    // Get updated global state, with cache refreshed if it had expired
    uint256 lastGlobalUpdateTimestamp;
    (state, lastGlobalUpdateTimestamp) = _getUpdatedGlobalState();
    // Read module state from storage
    moduleState = _getExistingModuleState(module);
    // Check if module's cache is older than global cache
    if (moduleState.getLastUpdateTimestamp() < lastGlobalUpdateTimestamp) {
      moduleState = _updateModuleCache(state, moduleState, module);
    }
  }

  /*//////////////////////////////////////////////////////////////
                      Internal Fee Calculators
  //////////////////////////////////////////////////////////////*/

  function _calculateModuleGasFees(
    GlobalState state,
    uint256 loanGasE4,
    uint256 repayGasE4
  )
    internal
    pure
    returns (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    )
  {
    (uint256 satoshiPerEth, uint256 gasPrice) = state.getParamsForModuleFees();
    // Unchecked because gasPrice can not exceed 60 bits,
    // refunds can not exceed 68 bits and the numerator for
    // borrowGasFeeBitcoin can not exceed 108 bits
    unchecked {
      // Multiply gasPrice (expressed in gwei) by 1e9 to convert to wei, and by 1e4 to convert
      // the gas values (expressed as gas * 1e-4) to ETH
      gasPrice *= 1e13;
      // Compute ETH cost of running loan function
      ethRefundForLoanGas = loanGasE4 * gasPrice;
      // Compute ETH cost of running repay function
      ethRefundForRepayGas = repayGasE4 * gasPrice;
      // Compute BTC value of `ethRefundForLoanGas`
      btcFeeForLoanGas = (satoshiPerEth * ethRefundForLoanGas) / OneEth;
      // Compute BTC value of `ethRefundForRepayGas`
      btcFeeForRepayGas = (satoshiPerEth * ethRefundForRepayGas) / OneEth;
    }
  }

  function _calculateRenAndZeroFees(GlobalState state, uint256 borrowAmount)
    internal
    pure
    returns (uint256 renFees, uint256 zeroFees)
  {
    (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic
    ) = state.getBorrowFees();

    renFees = renBorrowFeeStatic + borrowAmount.uncheckedMulBipsUp(renBorrowFeeBips);
    zeroFees = zeroBorrowFeeStatic + borrowAmount.uncheckedMulBipsUp(zeroBorrowFeeBips);
  }

  function _calculateLoanFees(
    GlobalState state,
    ModuleState moduleState,
    uint256 borrowAmount
  )
    internal
    pure
    returns (
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 btcFeeForLoanGas
    )
  {
    (uint256 renFees, uint256 zeroFees) = _calculateRenAndZeroFees(state, borrowAmount);
    uint256 btcFeeForRepayGas;
    (btcFeeForLoanGas, btcFeeForRepayGas) = moduleState.getBitcoinGasFees();

    // Lender is responsible for actualBorrowAmount, zeroFees and gas refunds.
    lenderDebt = borrowAmount - renFees;

    // Subtract ren, zero and gas fees
    actualBorrowAmount = lenderDebt - (zeroFees + btcFeeForLoanGas + btcFeeForRepayGas);
  }

  function _ethToBtc(uint256 ethAmount, uint256 satoshiPerEth) internal pure returns (uint256 btcAmount) {
    return (ethAmount * satoshiPerEth) / OneEth;
  }

  function _btcToEth(uint256 btcAmount, uint256 satoshiPerEth) internal pure returns (uint256 ethAmount) {
    return (btcAmount * OneEth) / satoshiPerEth;
  }
}