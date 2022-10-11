// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct ModuleState {
//   ModuleType moduleType;
//   uint8 loanGasE4;
//   uint8 repayGasE4;
//   uint64 ethRefundForLoanGas;
//   uint64 ethRefundForRepayGas;
//   uint24 btcFeeForLoanGas;
//   uint24 btcFeeForRepayGas;
//   uint32 lastUpdateTimestamp;
// }
type ModuleState is uint256;

ModuleState constant DefaultModuleState = ModuleState
  .wrap(0);

library ModuleStateCoder {
  /*//////////////////////////////////////////////////////////////
                           ModuleState
//////////////////////////////////////////////////////////////*/

  function decode(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 loanGasE4,
      uint256 repayGasE4,
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  function encode(
    ModuleType moduleType,
    uint256 loanGasE4,
    uint256 repayGasE4,
    uint256 ethRefundForLoanGas,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForLoanGas,
    uint256 btcFeeForRepayGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState encoded) {
    assembly {
      if or(
        gt(loanGasE4, MaxUint8),
        or(
          gt(repayGasE4, MaxUint8),
          or(
            gt(ethRefundForLoanGas, MaxUint64),
            or(
              gt(ethRefundForRepayGas, MaxUint64),
              or(
                gt(btcFeeForLoanGas, MaxUint24),
                or(
                  gt(
                    btcFeeForRepayGas,
                    MaxUint24
                  ),
                  gt(
                    lastUpdateTimestamp,
                    MaxUint32
                  )
                )
              )
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      encoded := or(
        shl(
          ModuleState_moduleType_bitsAfter,
          moduleType
        ),
        or(
          shl(
            ModuleState_loanGasE4_bitsAfter,
            loanGasE4
          ),
          or(
            shl(
              ModuleState_repayGasE4_bitsAfter,
              repayGasE4
            ),
            or(
              shl(
                ModuleState_ethRefundForLoanGas_bitsAfter,
                ethRefundForLoanGas
              ),
              or(
                shl(
                  ModuleState_ethRefundForRepayGas_bitsAfter,
                  ethRefundForRepayGas
                ),
                or(
                  shl(
                    ModuleState_btcFeeForLoanGas_bitsAfter,
                    btcFeeForLoanGas
                  ),
                  or(
                    shl(
                      ModuleState_btcFeeForRepayGas_bitsAfter,
                      btcFeeForRepayGas
                    ),
                    shl(
                      ModuleState_lastUpdateTimestamp_bitsAfter,
                      lastUpdateTimestamp
                    )
                  )
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState LoanParams coders
//////////////////////////////////////////////////////////////*/

  function getLoanParams(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 ethRefundForLoanGas
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                ModuleState BitcoinGasFees coders
//////////////////////////////////////////////////////////////*/

  function getBitcoinGasFees(ModuleState encoded)
    internal
    pure
    returns (
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    )
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 ModuleState RepayParams coders
//////////////////////////////////////////////////////////////*/

  function setRepayParams(
    ModuleState old,
    ModuleType moduleType,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(ethRefundForRepayGas, MaxUint64),
        gt(btcFeeForRepayGas, MaxUint24)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_RepayParams_maskOut),
        or(
          shl(
            ModuleState_moduleType_bitsAfter,
            moduleType
          ),
          or(
            shl(
              ModuleState_ethRefundForRepayGas_bitsAfter,
              ethRefundForRepayGas
            ),
            shl(
              ModuleState_btcFeeForRepayGas_bitsAfter,
              btcFeeForRepayGas
            )
          )
        )
      )
    }
  }

  function getRepayParams(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForRepayGas
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    ModuleState Cached coders
//////////////////////////////////////////////////////////////*/

  function setCached(
    ModuleState old,
    uint256 ethRefundForLoanGas,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForLoanGas,
    uint256 btcFeeForRepayGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(ethRefundForLoanGas, MaxUint64),
        or(
          gt(ethRefundForRepayGas, MaxUint64),
          or(
            gt(btcFeeForLoanGas, MaxUint24),
            or(
              gt(btcFeeForRepayGas, MaxUint24),
              gt(lastUpdateTimestamp, MaxUint32)
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_Cached_maskOut),
        or(
          shl(
            ModuleState_ethRefundForLoanGas_bitsAfter,
            ethRefundForLoanGas
          ),
          or(
            shl(
              ModuleState_ethRefundForRepayGas_bitsAfter,
              ethRefundForRepayGas
            ),
            or(
              shl(
                ModuleState_btcFeeForLoanGas_bitsAfter,
                btcFeeForLoanGas
              ),
              or(
                shl(
                  ModuleState_btcFeeForRepayGas_bitsAfter,
                  btcFeeForRepayGas
                ),
                shl(
                  ModuleState_lastUpdateTimestamp_bitsAfter,
                  lastUpdateTimestamp
                )
              )
            )
          )
        )
      )
    }
  }

  function getCached(ModuleState encoded)
    internal
    pure
    returns (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    )
  {
    assembly {
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState GasParams coders
//////////////////////////////////////////////////////////////*/

  function setGasParams(
    ModuleState old,
    uint256 loanGasE4,
    uint256 repayGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(loanGasE4, MaxUint8),
        gt(repayGasE4, MaxUint8)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_GasParams_maskOut),
        or(
          shl(
            ModuleState_loanGasE4_bitsAfter,
            loanGasE4
          ),
          shl(
            ModuleState_repayGasE4_bitsAfter,
            repayGasE4
          )
        )
      )
    }
  }

  function getGasParams(ModuleState encoded)
    internal
    pure
    returns (
      uint256 loanGasE4,
      uint256 repayGasE4
    )
  {
    assembly {
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.moduleType coders
//////////////////////////////////////////////////////////////*/

  function getModuleType(ModuleState encoded)
    internal
    pure
    returns (ModuleType moduleType)
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
    }
  }

  function setModuleType(
    ModuleState old,
    ModuleType moduleType
  ) internal pure returns (ModuleState updated) {
    assembly {
      updated := or(
        and(old, ModuleState_moduleType_maskOut),
        shl(
          ModuleState_moduleType_bitsAfter,
          moduleType
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.loanGasE4 coders
//////////////////////////////////////////////////////////////*/

  function getLoanGasE4(ModuleState encoded)
    internal
    pure
    returns (uint256 loanGasE4)
  {
    assembly {
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  function setLoanGasE4(
    ModuleState old,
    uint256 loanGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(loanGasE4, MaxUint8) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_loanGasE4_maskOut),
        shl(
          ModuleState_loanGasE4_bitsAfter,
          loanGasE4
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.repayGasE4 coders
//////////////////////////////////////////////////////////////*/

  function getRepayGasE4(ModuleState encoded)
    internal
    pure
    returns (uint256 repayGasE4)
  {
    assembly {
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRepayGasE4(
    ModuleState old,
    uint256 repayGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(repayGasE4, MaxUint8) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_repayGasE4_maskOut),
        shl(
          ModuleState_repayGasE4_bitsAfter,
          repayGasE4
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.ethRefundForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getEthRefundForLoanGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 ethRefundForLoanGas)
  {
    assembly {
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setEthRefundForLoanGas(
    ModuleState old,
    uint256 ethRefundForLoanGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(ethRefundForLoanGas, MaxUint64) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_ethRefundForLoanGas_maskOut
        ),
        shl(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          ethRefundForLoanGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.ethRefundForRepayGas coders
//////////////////////////////////////////////////////////////*/

  function getEthRefundForRepayGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 ethRefundForRepayGas)
  {
    assembly {
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setEthRefundForRepayGas(
    ModuleState old,
    uint256 ethRefundForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(ethRefundForRepayGas, MaxUint64) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_ethRefundForRepayGas_maskOut
        ),
        shl(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          ethRefundForRepayGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               ModuleState.btcFeeForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForLoanGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 btcFeeForLoanGas)
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setBtcFeeForLoanGas(
    ModuleState old,
    uint256 btcFeeForLoanGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(btcFeeForLoanGas, MaxUint24) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_btcFeeForLoanGas_maskOut
        ),
        shl(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          btcFeeForLoanGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              ModuleState.btcFeeForRepayGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForRepayGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 btcFeeForRepayGas)
  {
    assembly {
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setBtcFeeForRepayGas(
    ModuleState old,
    uint256 btcFeeForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(btcFeeForRepayGas, MaxUint24) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_btcFeeForRepayGas_maskOut
        ),
        shl(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          btcFeeForRepayGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.lastUpdateTimestamp coders
//////////////////////////////////////////////////////////////*/

  function getLastUpdateTimestamp(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 lastUpdateTimestamp)
  {
    assembly {
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  function setLastUpdateTimestamp(
    ModuleState old,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(lastUpdateTimestamp, MaxUint32) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_lastUpdateTimestamp_maskOut
        ),
        shl(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          lastUpdateTimestamp
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 ModuleState comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(ModuleState a, ModuleState b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(ModuleState a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultModuleState);
  }
}

enum ModuleType {
  Null,
  LoanOverride,
  LoanAndRepayOverride
}