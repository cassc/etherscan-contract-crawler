// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct LoanRecord {
//   uint48 sharesLocked;
//   uint48 actualBorrowAmount;
//   uint48 lenderDebt;
//   uint48 btcFeeForLoanGas;
//   uint32 expiry;
// }
type LoanRecord is uint256;

LoanRecord constant DefaultLoanRecord = LoanRecord
  .wrap(0);

library LoanRecordCoder {
  /*//////////////////////////////////////////////////////////////
                           LoanRecord
//////////////////////////////////////////////////////////////*/

  function decode(LoanRecord encoded)
    internal
    pure
    returns (
      uint256 sharesLocked,
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 btcFeeForLoanGas,
      uint256 expiry
    )
  {
    assembly {
      sharesLocked := shr(
        LoanRecord_sharesLocked_bitsAfter,
        encoded
      )
      actualBorrowAmount := and(
        MaxUint48,
        shr(
          LoanRecord_actualBorrowAmount_bitsAfter,
          encoded
        )
      )
      lenderDebt := and(
        MaxUint48,
        shr(
          LoanRecord_lenderDebt_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint48,
        shr(
          LoanRecord_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      expiry := and(
        MaxUint32,
        shr(LoanRecord_expiry_bitsAfter, encoded)
      )
    }
  }

  function encode(
    uint256 sharesLocked,
    uint256 actualBorrowAmount,
    uint256 lenderDebt,
    uint256 btcFeeForLoanGas,
    uint256 expiry
  ) internal pure returns (LoanRecord encoded) {
    assembly {
      if or(
        gt(sharesLocked, MaxUint48),
        or(
          gt(actualBorrowAmount, MaxUint48),
          or(
            gt(lenderDebt, MaxUint48),
            or(
              gt(btcFeeForLoanGas, MaxUint48),
              gt(expiry, MaxUint32)
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
          LoanRecord_sharesLocked_bitsAfter,
          sharesLocked
        ),
        or(
          shl(
            LoanRecord_actualBorrowAmount_bitsAfter,
            actualBorrowAmount
          ),
          or(
            shl(
              LoanRecord_lenderDebt_bitsAfter,
              lenderDebt
            ),
            or(
              shl(
                LoanRecord_btcFeeForLoanGas_bitsAfter,
                btcFeeForLoanGas
              ),
              shl(
                LoanRecord_expiry_bitsAfter,
                expiry
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 LoanRecord SharesAndDebt coders
//////////////////////////////////////////////////////////////*/

  function getSharesAndDebt(LoanRecord encoded)
    internal
    pure
    returns (
      uint256 sharesLocked,
      uint256 lenderDebt
    )
  {
    assembly {
      sharesLocked := shr(
        LoanRecord_sharesLocked_bitsAfter,
        encoded
      )
      lenderDebt := and(
        MaxUint48,
        shr(
          LoanRecord_lenderDebt_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              LoanRecord.actualBorrowAmount coders
//////////////////////////////////////////////////////////////*/

  function getActualBorrowAmount(
    LoanRecord encoded
  )
    internal
    pure
    returns (uint256 actualBorrowAmount)
  {
    assembly {
      actualBorrowAmount := and(
        MaxUint48,
        shr(
          LoanRecord_actualBorrowAmount_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               LoanRecord.btcFeeForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForLoanGas(LoanRecord encoded)
    internal
    pure
    returns (uint256 btcFeeForLoanGas)
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint48,
        shr(
          LoanRecord_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    LoanRecord.expiry coders
//////////////////////////////////////////////////////////////*/

  function getExpiry(LoanRecord encoded)
    internal
    pure
    returns (uint256 expiry)
  {
    assembly {
      expiry := and(
        MaxUint32,
        shr(LoanRecord_expiry_bitsAfter, encoded)
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  LoanRecord comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(LoanRecord a, LoanRecord b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(LoanRecord a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultLoanRecord);
  }
}