// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct GlobalState {
//   uint11 zeroBorrowFeeBips;
//   uint11 renBorrowFeeBips;
//   uint13 zeroFeeShareBips;
//   uint23 zeroBorrowFeeStatic;
//   uint23 renBorrowFeeStatic;
//   uint30 satoshiPerEth;
//   uint16 gweiPerGas;
//   uint32 lastUpdateTimestamp;
//   uint40 totalBitcoinBorrowed;
//   uint28 unburnedGasReserveShares;
//   uint28 unburnedZeroFeeShares;
// }
type GlobalState is uint256;

GlobalState constant DefaultGlobalState = GlobalState
  .wrap(0);

library GlobalStateCoder {
  /*//////////////////////////////////////////////////////////////
                           GlobalState
//////////////////////////////////////////////////////////////*/

  function decode(GlobalState encoded)
    internal
    pure
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroFeeShareBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic,
      uint256 satoshiPerEth,
      uint256 gweiPerGas,
      uint256 lastUpdateTimestamp,
      uint256 totalBitcoinBorrowed,
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    )
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
      zeroFeeShareBips := and(
        MaxUint13,
        shr(
          GlobalState_zeroFeeShareBips_bitsAfter,
          encoded
        )
      )
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          GlobalState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function encode(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroFeeShareBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 satoshiPerEth,
    uint256 gweiPerGas,
    uint256 lastUpdateTimestamp,
    uint256 totalBitcoinBorrowed,
    uint256 unburnedGasReserveShares,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState encoded) {
    assembly {
      if or(
        gt(zeroBorrowFeeStatic, MaxUint23),
        or(
          gt(renBorrowFeeStatic, MaxUint23),
          or(
            gt(satoshiPerEth, MaxUint30),
            or(
              gt(gweiPerGas, MaxUint16),
              or(
                gt(
                  lastUpdateTimestamp,
                  MaxUint32
                ),
                or(
                  gt(
                    totalBitcoinBorrowed,
                    MaxUint40
                  ),
                  or(
                    gt(
                      unburnedGasReserveShares,
                      MaxUint28
                    ),
                    gt(
                      unburnedZeroFeeShares,
                      MaxUint28
                    )
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
          GlobalState_zeroBorrowFeeBips_bitsAfter,
          zeroBorrowFeeBips
        ),
        or(
          shl(
            GlobalState_renBorrowFeeBips_bitsAfter,
            renBorrowFeeBips
          ),
          or(
            shl(
              GlobalState_zeroFeeShareBips_bitsAfter,
              zeroFeeShareBips
            ),
            or(
              shl(
                GlobalState_zeroBorrowFeeStatic_bitsAfter,
                zeroBorrowFeeStatic
              ),
              or(
                shl(
                  GlobalState_renBorrowFeeStatic_bitsAfter,
                  renBorrowFeeStatic
                ),
                or(
                  shl(
                    GlobalState_satoshiPerEth_bitsAfter,
                    satoshiPerEth
                  ),
                  or(
                    shl(
                      GlobalState_gweiPerGas_bitsAfter,
                      gweiPerGas
                    ),
                    or(
                      shl(
                        GlobalState_lastUpdateTimestamp_bitsAfter,
                        lastUpdateTimestamp
                      ),
                      or(
                        shl(
                          GlobalState_totalBitcoinBorrowed_bitsAfter,
                          totalBitcoinBorrowed
                        ),
                        or(
                          shl(
                            GlobalState_unburnedGasReserveShares_bitsAfter,
                            unburnedGasReserveShares
                          ),
                          shl(
                            GlobalState_unburnedZeroFeeShares_bitsAfter,
                            unburnedZeroFeeShares
                          )
                        )
                      )
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
                   GlobalState LoanInfo coders
//////////////////////////////////////////////////////////////*/

  function setLoanInfo(
    GlobalState old,
    uint256 totalBitcoinBorrowed
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(totalBitcoinBorrowed, MaxUint40) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, GlobalState_LoanInfo_maskOut),
        shl(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          totalBitcoinBorrowed
        )
      )
    }
  }

  function getLoanInfo(GlobalState encoded)
    internal
    pure
    returns (uint256 totalBitcoinBorrowed)
  {
    assembly {
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                     GlobalState Fees coders
//////////////////////////////////////////////////////////////*/

  function setFees(
    GlobalState old,
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(zeroBorrowFeeBips, MaxUint11),
        or(
          gt(renBorrowFeeBips, MaxUint11),
          or(
            gt(zeroBorrowFeeStatic, MaxUint23),
            or(
              gt(renBorrowFeeStatic, MaxUint23),
              gt(zeroFeeShareBips, MaxUint13)
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
        and(old, GlobalState_Fees_maskOut),
        or(
          shl(
            GlobalState_zeroBorrowFeeBips_bitsAfter,
            zeroBorrowFeeBips
          ),
          or(
            shl(
              GlobalState_renBorrowFeeBips_bitsAfter,
              renBorrowFeeBips
            ),
            or(
              shl(
                GlobalState_zeroBorrowFeeStatic_bitsAfter,
                zeroBorrowFeeStatic
              ),
              or(
                shl(
                  GlobalState_renBorrowFeeStatic_bitsAfter,
                  renBorrowFeeStatic
                ),
                shl(
                  GlobalState_zeroFeeShareBips_bitsAfter,
                  zeroFeeShareBips
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  GlobalState BorrowFees coders
//////////////////////////////////////////////////////////////*/

  function getBorrowFees(GlobalState encoded)
    internal
    pure
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic
    )
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    GlobalState Cached coders
//////////////////////////////////////////////////////////////*/

  function setCached(
    GlobalState old,
    uint256 satoshiPerEth,
    uint256 gweiPerGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(satoshiPerEth, MaxUint30),
        or(
          gt(gweiPerGas, MaxUint16),
          gt(lastUpdateTimestamp, MaxUint32)
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
        and(old, GlobalState_Cached_maskOut),
        or(
          shl(
            GlobalState_satoshiPerEth_bitsAfter,
            satoshiPerEth
          ),
          or(
            shl(
              GlobalState_gweiPerGas_bitsAfter,
              gweiPerGas
            ),
            shl(
              GlobalState_lastUpdateTimestamp_bitsAfter,
              lastUpdateTimestamp
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState ParamsForModuleFees coders
//////////////////////////////////////////////////////////////*/

  function setParamsForModuleFees(
    GlobalState old,
    uint256 satoshiPerEth,
    uint256 gweiPerGas
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(satoshiPerEth, MaxUint30),
        gt(gweiPerGas, MaxUint16)
      ) {
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
          GlobalState_ParamsForModuleFees_maskOut
        ),
        or(
          shl(
            GlobalState_satoshiPerEth_bitsAfter,
            satoshiPerEth
          ),
          shl(
            GlobalState_gweiPerGas_bitsAfter,
            gweiPerGas
          )
        )
      )
    }
  }

  function getParamsForModuleFees(
    GlobalState encoded
  )
    internal
    pure
    returns (
      uint256 satoshiPerEth,
      uint256 gweiPerGas
    )
  {
    assembly {
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                GlobalState UnburnedShares coders
//////////////////////////////////////////////////////////////*/

  function setUnburnedShares(
    GlobalState old,
    uint256 unburnedGasReserveShares,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(unburnedGasReserveShares, MaxUint28),
        gt(unburnedZeroFeeShares, MaxUint28)
      ) {
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
          GlobalState_UnburnedShares_maskOut
        ),
        or(
          shl(
            GlobalState_unburnedGasReserveShares_bitsAfter,
            unburnedGasReserveShares
          ),
          shl(
            GlobalState_unburnedZeroFeeShares_bitsAfter,
            unburnedZeroFeeShares
          )
        )
      )
    }
  }

  function getUnburnedShares(GlobalState encoded)
    internal
    pure
    returns (
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    )
  {
    assembly {
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              GlobalState.zeroBorrowFeeBips coders
//////////////////////////////////////////////////////////////*/

  function getZeroBorrowFeeBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroBorrowFeeBips)
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
    }
  }

  function setZeroBorrowFeeBips(
    GlobalState old,
    uint256 zeroBorrowFeeBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_zeroBorrowFeeBips_maskOut
        ),
        shl(
          GlobalState_zeroBorrowFeeBips_bitsAfter,
          zeroBorrowFeeBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               GlobalState.renBorrowFeeBips coders
//////////////////////////////////////////////////////////////*/

  function getRenBorrowFeeBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 renBorrowFeeBips)
  {
    assembly {
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRenBorrowFeeBips(
    GlobalState old,
    uint256 renBorrowFeeBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_renBorrowFeeBips_maskOut
        ),
        shl(
          GlobalState_renBorrowFeeBips_bitsAfter,
          renBorrowFeeBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               GlobalState.zeroFeeShareBips coders
//////////////////////////////////////////////////////////////*/

  function getZeroFeeShareBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroFeeShareBips)
  {
    assembly {
      zeroFeeShareBips := and(
        MaxUint13,
        shr(
          GlobalState_zeroFeeShareBips_bitsAfter,
          encoded
        )
      )
    }
  }

  function setZeroFeeShareBips(
    GlobalState old,
    uint256 zeroFeeShareBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_zeroFeeShareBips_maskOut
        ),
        shl(
          GlobalState_zeroFeeShareBips_bitsAfter,
          zeroFeeShareBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.zeroBorrowFeeStatic coders
//////////////////////////////////////////////////////////////*/

  function getZeroBorrowFeeStatic(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroBorrowFeeStatic)
  {
    assembly {
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  function setZeroBorrowFeeStatic(
    GlobalState old,
    uint256 zeroBorrowFeeStatic
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(zeroBorrowFeeStatic, MaxUint23) {
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
          GlobalState_zeroBorrowFeeStatic_maskOut
        ),
        shl(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          zeroBorrowFeeStatic
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              GlobalState.renBorrowFeeStatic coders
//////////////////////////////////////////////////////////////*/

  function getRenBorrowFeeStatic(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 renBorrowFeeStatic)
  {
    assembly {
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRenBorrowFeeStatic(
    GlobalState old,
    uint256 renBorrowFeeStatic
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(renBorrowFeeStatic, MaxUint23) {
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
          GlobalState_renBorrowFeeStatic_maskOut
        ),
        shl(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          renBorrowFeeStatic
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                GlobalState.satoshiPerEth coders
//////////////////////////////////////////////////////////////*/

  function getSatoshiPerEth(GlobalState encoded)
    internal
    pure
    returns (uint256 satoshiPerEth)
  {
    assembly {
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  GlobalState.gweiPerGas coders
//////////////////////////////////////////////////////////////*/

  function getGweiPerGas(GlobalState encoded)
    internal
    pure
    returns (uint256 gweiPerGas)
  {
    assembly {
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.lastUpdateTimestamp coders
//////////////////////////////////////////////////////////////*/

  function getLastUpdateTimestamp(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 lastUpdateTimestamp)
  {
    assembly {
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          GlobalState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.totalBitcoinBorrowed coders
//////////////////////////////////////////////////////////////*/

  function getTotalBitcoinBorrowed(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 totalBitcoinBorrowed)
  {
    assembly {
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
    }
  }

  function setTotalBitcoinBorrowed(
    GlobalState old,
    uint256 totalBitcoinBorrowed
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(totalBitcoinBorrowed, MaxUint40) {
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
          GlobalState_totalBitcoinBorrowed_maskOut
        ),
        shl(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          totalBitcoinBorrowed
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
           GlobalState.unburnedGasReserveShares coders
//////////////////////////////////////////////////////////////*/

  function getUnburnedGasReserveShares(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 unburnedGasReserveShares)
  {
    assembly {
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function setUnburnedGasReserveShares(
    GlobalState old,
    uint256 unburnedGasReserveShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(unburnedGasReserveShares, MaxUint28) {
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
          GlobalState_unburnedGasReserveShares_maskOut
        ),
        shl(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          unburnedGasReserveShares
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
            GlobalState.unburnedZeroFeeShares coders
//////////////////////////////////////////////////////////////*/

  function getUnburnedZeroFeeShares(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 unburnedZeroFeeShares)
  {
    assembly {
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function setUnburnedZeroFeeShares(
    GlobalState old,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(unburnedZeroFeeShares, MaxUint28) {
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
          GlobalState_unburnedZeroFeeShares_maskOut
        ),
        shl(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          unburnedZeroFeeShares
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 GlobalState comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(GlobalState a, GlobalState b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(GlobalState a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultGlobalState);
  }
}