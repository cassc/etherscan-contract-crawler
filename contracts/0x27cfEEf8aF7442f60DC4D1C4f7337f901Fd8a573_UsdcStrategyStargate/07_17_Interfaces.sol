// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';

/// https://etherscan.io/address/0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56#code
abstract contract LPTokenERC20 is ERC20 {
	function amountLPtoLD(uint256 _lpAmount) external view virtual returns (uint256);

	function totalLiquidity() external view virtual returns (uint256);
}

/// @dev
/// https://etherscan.io/address/0xB0D502E938ed5f4df2E681fE6E419ff29631d62b#code
/// basically a Goose MasterChef
interface ILPStaking {
	function poolInfo(uint256 _pid)
		external
		view
		returns (
			address lpToken,
			uint256 allocPoint,
			uint256 lastRewardBlock,
			uint256 accStargatePerShare
		);

	function userInfo(uint256 _pid, address _address) external view returns (uint256 amount, uint256 rewardDebt);

	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;
}

/// @dev https://etherscan.io/address/0x8731d54E9D02c286767d56ac03e8037C07e01e98#code
interface IStargateRouter {
	struct lzTxObj {
		uint256 dstGasForCall;
		uint256 dstNativeAmount;
		bytes dstNativeAddr;
	}

	function addLiquidity(
		uint256 _poolId,
		uint256 _amountLD,
		address _to
	) external;

	function instantRedeemLocal(
		uint16 _srcPoolId,
		uint256 _amountLP,
		address _to
	) external returns (uint256);

	function redeemLocal(
		uint16 _dstChainId,
		uint256 _srcPoolId,
		uint256 _dstPoolId,
		address payable _refundAddress,
		uint256 _amountLP,
		bytes calldata _to,
		lzTxObj memory _lzTxParams
	) external payable;

	function callDelta(uint256 _poolId, bool _fullMode) external;

	function quoteLayerZeroFee(
		uint16 _dstChainId,
		uint8 _functionType,
		bytes calldata _toAddress,
		bytes calldata _transferAndCallPayload,
		lzTxObj memory _lzTxParams
	) external view returns (uint256, uint256);
}