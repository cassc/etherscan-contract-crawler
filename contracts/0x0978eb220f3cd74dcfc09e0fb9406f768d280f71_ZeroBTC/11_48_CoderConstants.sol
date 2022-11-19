// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

uint256 constant GlobalState_BorrowFees_maskOut = 0x000003ffe000000000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_Cached_maskOut = 0xffffffffffffffffffff80000000000000000001ffffffffffffffffffffffff;
uint256 constant GlobalState_Fees_maskOut = 0x000000000000000000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_LoanInfo_maskOut = 0xfffffffffffffffffffffffffffffffffffffffe0000000001ffffffffffffff;
uint256 constant GlobalState_ParamsForModuleFees_maskOut = 0xffffffffffffffffffff800000000001ffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_UnburnedShares_maskOut = 0xfffffffffffffffffffffffffffffffffffffffffffffffffe00000000000001;
uint256 constant GlobalState_gweiPerGas_bitsAfter = 0x81;
uint256 constant GlobalState_gweiPerGas_maskOut = 0xfffffffffffffffffffffffffffe0001ffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_lastUpdateTimestamp_bitsAfter = 0x61;
uint256 constant GlobalState_lastUpdateTimestamp_maskOut = 0xfffffffffffffffffffffffffffffffe00000001ffffffffffffffffffffffff;
uint256 constant GlobalState_renBorrowFeeBips_bitsAfter = 0xea;
uint256 constant GlobalState_renBorrowFeeBips_maskOut = 0xffe003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_renBorrowFeeStatic_bitsAfter = 0xaf;
uint256 constant GlobalState_renBorrowFeeStatic_maskOut = 0xffffffffffffffc000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_satoshiPerEth_bitsAfter = 0x91;
uint256 constant GlobalState_satoshiPerEth_maskOut = 0xffffffffffffffffffff80000001ffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_totalBitcoinBorrowed_bitsAfter = 0x39;
uint256 constant GlobalState_totalBitcoinBorrowed_maskOut = 0xfffffffffffffffffffffffffffffffffffffffe0000000001ffffffffffffff;
uint256 constant GlobalState_unburnedGasReserveShares_bitsAfter = 0x1d;
uint256 constant GlobalState_unburnedGasReserveShares_maskOut = 0xfffffffffffffffffffffffffffffffffffffffffffffffffe0000001fffffff;
uint256 constant GlobalState_unburnedZeroFeeShares_bitsAfter = 0x01;
uint256 constant GlobalState_unburnedZeroFeeShares_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0000001;
uint256 constant GlobalState_zeroBorrowFeeBips_bitsAfter = 0xf5;
uint256 constant GlobalState_zeroBorrowFeeBips_maskOut = 0x001fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_zeroBorrowFeeStatic_bitsAfter = 0xc6;
uint256 constant GlobalState_zeroBorrowFeeStatic_maskOut = 0xffffffffe000003fffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_zeroFeeShareBips_bitsAfter = 0xdd;
uint256 constant GlobalState_zeroFeeShareBips_maskOut = 0xfffffc001fffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant LoanRecord_SharesAndDebt_maskOut = 0x000000000000ffffffffffff000000000000ffffffffffffffffffffffffffff;
uint256 constant LoanRecord_actualBorrowAmount_bitsAfter = 0xa0;
uint256 constant LoanRecord_actualBorrowAmount_maskOut = 0xffffffffffff000000000000ffffffffffffffffffffffffffffffffffffffff;
uint256 constant LoanRecord_btcFeeForLoanGas_bitsAfter = 0x40;
uint256 constant LoanRecord_btcFeeForLoanGas_maskOut = 0xffffffffffffffffffffffffffffffffffff000000000000ffffffffffffffff;
uint256 constant LoanRecord_expiry_bitsAfter = 0x20;
uint256 constant LoanRecord_expiry_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffffff;
uint256 constant LoanRecord_lenderDebt_bitsAfter = 0x70;
uint256 constant LoanRecord_lenderDebt_maskOut = 0xffffffffffffffffffffffff000000000000ffffffffffffffffffffffffffff;
uint256 constant LoanRecord_sharesLocked_bitsAfter = 0xd0;
uint256 constant LoanRecord_sharesLocked_maskOut = 0x000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant MaxUint11 = 0x07ff;
uint256 constant MaxUint13 = 0x1fff;
uint256 constant MaxUint16 = 0xffff;
uint256 constant MaxUint2 = 0x03;
uint256 constant MaxUint23 = 0x7fffff;
uint256 constant MaxUint24 = 0xffffff;
uint256 constant MaxUint28 = 0x0fffffff;
uint256 constant MaxUint30 = 0x3fffffff;
uint256 constant MaxUint32 = 0xffffffff;
uint256 constant MaxUint40 = 0xffffffffff;
uint256 constant MaxUint48 = 0xffffffffffff;
uint256 constant MaxUint64 = 0xffffffffffffffff;
uint256 constant MaxUint8 = 0xff;
uint256 constant ModuleState_BitcoinGasFees_maskOut = 0xffffffffffffffffffffffffffffffffffffc000000000003fffffffffffffff;
uint256 constant ModuleState_Cached_maskOut = 0xffffc0000000000000000000000000000000000000000000000000003fffffff;
uint256 constant ModuleState_GasParams_maskOut = 0xc0003fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_LoanParams_maskOut = 0x3fffc0000000000000003fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_RepayParams_maskOut = 0x3fffffffffffffffffffc0000000000000003fffffc000003fffffffffffffff;
uint256 constant ModuleState_btcFeeForLoanGas_bitsAfter = 0x56;
uint256 constant ModuleState_btcFeeForLoanGas_maskOut = 0xffffffffffffffffffffffffffffffffffffc000003fffffffffffffffffffff;
uint256 constant ModuleState_btcFeeForRepayGas_bitsAfter = 0x3e;
uint256 constant ModuleState_btcFeeForRepayGas_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffc000003fffffffffffffff;
uint256 constant ModuleState_ethRefundForLoanGas_bitsAfter = 0xae;
uint256 constant ModuleState_ethRefundForLoanGas_maskOut = 0xffffc0000000000000003fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_ethRefundForRepayGas_bitsAfter = 0x6e;
uint256 constant ModuleState_ethRefundForRepayGas_maskOut = 0xffffffffffffffffffffc0000000000000003fffffffffffffffffffffffffff;
uint256 constant ModuleState_lastUpdateTimestamp_bitsAfter = 0x1e;
uint256 constant ModuleState_lastUpdateTimestamp_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffffc00000003fffffff;
uint256 constant ModuleState_loanGasE4_bitsAfter = 0xf6;
uint256 constant ModuleState_loanGasE4_maskOut = 0xc03fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_moduleType_bitsAfter = 0xfe;
uint256 constant ModuleState_moduleType_maskOut = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_repayGasE4_bitsAfter = 0xee;
uint256 constant ModuleState_repayGasE4_maskOut = 0xffc03fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant Panic_arithmetic = 0x11;
uint256 constant Panic_error_length = 0x24;
uint256 constant Panic_error_offset = 0x04;
uint256 constant Panic_error_signature = 0x4e487b7100000000000000000000000000000000000000000000000000000000;