// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

enum EnumType {
    SourceTokenInteraction,
    TargetTokenInteraction,
    CallType
}

error EthValueAmountMismatch();
error EthValueSourceTokenMismatch();
error MinReturnError(uint256, uint256);
error EmptySwapOnExecutor();
error EmptySwap();
error TransactionExpired(uint256, uint256);
error NotEnoughApprovedFundsForSwap(uint256, uint256);
error PermitNotAllowedForEthSwap();
error AmountExceedsQuote(uint256, uint256);
error SwapTotalAmountCannotBeZero();
error SwapAmountCannotBeZero();
error DirectEthDepositIsForbidden();
error MStableInvalidSwapType(uint256);
error AddressCannotBeZero();
error EnumOutOfRangeValue(EnumType, uint256);