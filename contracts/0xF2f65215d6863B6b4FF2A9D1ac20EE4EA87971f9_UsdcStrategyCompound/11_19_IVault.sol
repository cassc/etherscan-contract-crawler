// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/// https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8#code

interface IAsset {

}

interface IVault {
	enum SwapKind {
		GIVEN_IN,
		GIVEN_OUT
	}

	/**
	 * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
	 * `assets` array passed to that function, and ETH assets are converted to WETH.
	 *
	 * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
	 * from the previous swap, depending on the swap kind.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	/**
	 * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
	 * `recipient` account.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
	 * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
	 * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
	 * `joinPool`.
	 *
	 * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
	 * transferred. This matches the behavior of `exitPool`.
	 *
	 * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
	 * revert.
	 */
	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	/**
	 * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
	 * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
	 *
	 * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
	 * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
	 * the same index in the `assets` array.
	 *
	 * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
	 * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
	 * `amountOut` depending on the swap kind.
	 *
	 * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
	 * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
	 * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
	 *
	 * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
	 * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
	 * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
	 * or unwrapped from WETH by the Vault.
	 *
	 * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
	 * the minimum or maximum amount of each token the vault is allowed to transfer.
	 *
	 * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
	 * equivalent `swap` call.
	 *
	 * Emits `Swap` events.
	 */
	function batchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds,
		int256[] memory limits,
		uint256 deadline
	) external payable returns (int256[] memory);
}