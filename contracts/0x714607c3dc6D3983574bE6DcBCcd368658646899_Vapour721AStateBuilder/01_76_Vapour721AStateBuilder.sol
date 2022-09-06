// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "@beehiveinnovation/rain-protocol/contracts/vm/StandardStateBuilder.sol";
import "@beehiveinnovation/rain-protocol/contracts/vm/ops/AllStandardOps.sol";
import "./Vapour721A.sol";

contract Vapour721AStateBuilder is StandardStateBuilder {
	using LibFnPtrs for bytes;

	function localStackPopsFnPtrs()
		internal
		pure
		virtual
		override
		returns (bytes memory fnPtrs_)
	{
		unchecked {
			fnPtrs_ = new bytes(LOCAL_OPS_LENGTH * 0x20);
			function(uint256) pure returns (uint256)[LOCAL_OPS_LENGTH] memory fns_ = [
				// totalSupplly
				AllStandardOps.zero,
				// totalMinted
				AllStandardOps.zero,
				// number minted
				AllStandardOps.one,
				// number burned
				AllStandardOps.one
			];
			for (uint256 i_ = 0; i_ < LOCAL_OPS_LENGTH; i_++) {
				fnPtrs_.insertStackMovePtr(i_, fns_[i_]);
			}
		}
	}

	function localStackPushesFnPtrs()
		internal
		pure
		virtual
		override
		returns (bytes memory fnPtrs_)
	{
		unchecked {
			fnPtrs_ = new bytes(LOCAL_OPS_LENGTH * 0x20);
			function(uint256) pure returns (uint256)[LOCAL_OPS_LENGTH] memory fns_ = [
				// totalSupplly
				AllStandardOps.one,
				// totalMinted
				AllStandardOps.one,
				// number minted
				AllStandardOps.one,
				// number burned
				AllStandardOps.one
			];
			for (uint256 i_ = 0; i_ < LOCAL_OPS_LENGTH; i_++) {
				fnPtrs_.insertStackMovePtr(i_, fns_[i_]);
			}
		}
	}
}