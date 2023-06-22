// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

enum EnumType {
    SourceTokenInteraction,
    TargetTokenInteraction,
    CallType
}

enum UniswapV3LikeProtocol {
    Uniswap,
    Kyber,
    Maverick
}

error EthValueAmountMismatch();
error EthValueSourceTokenMismatch();
error MinReturnError(uint256, uint256);
error EmptySwapOnExecutor();
error EmptySwap();
error ZeroInput();
error ZeroRecipient();
error TransactionExpired(uint256, uint256);
error PermitNotAllowedForEthSwap();
error SwapTotalAmountCannotBeZero();
error SwapAmountCannotBeZero();
error DirectEthDepositIsForbidden();
error MStableInvalidSwapType(uint256);
error AddressCannotBeZero();
error TransferFromNotAllowed();
error EnumOutOfRangeValue(EnumType, uint256);
error BadUniswapV3LikePool(UniswapV3LikeProtocol);
error ERC1820InterfactionForbidden();