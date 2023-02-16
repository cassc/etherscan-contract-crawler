// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IStargateRouter {
	struct lzTxObj {
		uint256 dstGasForCall;
		uint256 dstNativeAmount;
		bytes dstNativeAddr;
	}

	function addLiquidity(
		uint256 _poolId, // The stargate poolId representing the specific ERC20 token.
		uint256 _amountLD, // The amount to loan. Quantity in local decimals.
		address _to // Address to receive the LP token. ie: shares of the pool.
	) external;

	function swap(
		uint16 _dstChainId,
		uint256 _srcPoolId,
		uint256 _dstPoolId,
		address payable _refundAddress,
		uint256 _amountLD,
		uint256 _minAmountLD,
		lzTxObj memory _lzTxParams,
		bytes calldata _to,
		bytes calldata _payload
	) external payable;

	function redeemRemote(
		uint16 _dstChainId,
		uint256 _srcPoolId,
		uint256 _dstPoolId,
		address payable _refundAddress,
		uint256 _amountLP,
		uint256 _minAmountLD, // Slippage amount in local decimals.
		bytes calldata _to,
		lzTxObj memory _lzTxParams
	) external payable;

	function instantRedeemLocal(
		uint16 _srcPoolId,
		uint256 _amountLP,
		address _to
	) external returns (uint256);

	function redeemLocal(
		uint16 _dstChainId, // The chainId to remove liquidity.
		uint256 _srcPoolId, // The source poolId.
		uint256 _dstPoolId, // The destination poolId.
		address payable _refundAddress, // Refund extra native gas to this address.
		uint256 _amountLP, // Quantity of LP tokens to redeem.
		bytes calldata _to, // Address to send the redeemed poolId tokens.
		lzTxObj memory _lzTxParams // Adapter parameters.
	) external payable;

	function sendCredits(
		uint16 _dstChainId, // Destination chainId.
		uint256 _srcPoolId, // Source poolId.
		uint256 _dstPoolId, // Destination poolId.
		address payable _refundAddress // Refund extra native gas to this address.
	) external payable;

	function quoteLayerZeroFee(
		uint16 _dstChainId,
		uint8 _functionType,
		bytes calldata _toAddress,
		bytes calldata _transferAndCallPayload,
		lzTxObj memory _lzTxParams
	) external view returns (uint256, uint256);
}