// SPDX-License-Identifier: GPL-3.0
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.8.16;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISCYVault } from "./ISCYVault.sol";

interface ISuperComposableYield is ISCYVault {
	/// @dev Emitted whenever the exchangeRate is updated
	event ExchangeRateUpdated(uint256 oldExchangeRate, uint256 newExchangeRate);

	/// @dev Emitted when any base tokens is deposited to mint shares
	event Deposit(
		address indexed caller,
		address indexed receiver,
		address indexed tokenIn,
		uint256 amountDeposited,
		uint256 amountScyOut
	);

	/// @dev Emitted when any shares are redeemed for base tokens
	event Redeem(
		address indexed caller,
		address indexed receiver,
		address indexed tokenOut,
		uint256 amountScyToRedeem,
		uint256 amountTokenOut
	);

	/// @dev check assetInfo for more information
	enum AssetType {
		TOKEN,
		LIQUIDITY
	}

	/**
	 * @notice mints an amount of shares by depositing a base token.
	 * @param receiver shares recipient address
	 * @param tokenIn address of the base tokens to mint shares
	 * @param amountTokenToPull amount of base tokens to be transferred from (`msg.sender`)
	 * @param minSharesOut reverts if amount of shares minted is lower than this
	 * @return amountSharesOut amount of shares minted
	 * @dev
	 *
	 * This contract receives base tokens using these two (possibly both) methods:
	 * - The tokens have been transferred directly to this contract prior to calling deposit().
	 * - Exactly `amountTokenToPull` are transferred to this contract using `transferFrom()` upon calling deposit().
	 *
	 * The amount of shares minted will be based on the combined amount of base tokens deposited
	 * using the given two methods.
	 *
	 * Emits a {Deposit} event
	 *
	 * Requirements:
	 * - (`baseTokenIn`) must be a valid base token.
	 * - There must be an ongoing approval from (`msg.sender`) for this contract with
	 * at least `amountTokenToPull` base tokens.
	 */
	function deposit(
		address receiver,
		address tokenIn,
		uint256 amountTokenToPull,
		uint256 minSharesOut
	) external payable returns (uint256 amountSharesOut);

	/**
	 * @notice redeems an amount of base tokens by burning some shares
	 * @param receiver recipient address
	 * @param amountSharesToPull amount of shares to be transferred from (`msg.sender`)
	 * @param tokenOut address of the base token to be redeemed
	 * @param minTokenOut reverts if amount of base token redeemed is lower than this
	 * @return amountTokenOut amount of base tokens redeemed
	 * @dev
	 *
	 * This contract receives shares using these two (possibly both) methods:
	 * - The shares have been transferred directly to this contract prior to calling redeem().
	 * - Exactly `amountSharesToPull` are transferred to this contract using `transferFrom()` upon calling redeem().
	 *
	 * The amount of base tokens redeemed based on the combined amount of shares deposited
	 * using the given two methods
	 *
	 * Emits a {Redeem} event
	 *
	 * Requirements:
	 * - (`tokenOut`) must be a valid base token.
	 * - There must be an ongoing approval from (`msg.sender`) for this contract with
	 * at least `amountSharesToPull` shares.
	 */
	function redeem(
		address receiver,
		uint256 amountSharesToPull,
		address tokenOut,
		uint256 minTokenOut
	) external returns (uint256 amountTokenOut);

	/**
	 * @notice returns the address of the underlying yield token
	 */
	function yieldToken() external view returns (address);

	/**
	 * @notice returns a list of all the base tokens that can be deposited to mint shares
	 */
	function getBaseTokens() external view returns (address[] memory res);

	/**
	 * @notice checks whether a token is a valid base token
	 * @notice returns a boolean indicating whether this is a valid token
	 */
	function isValidBaseToken(address token) external view returns (bool);

	/**
    * @notice This function contains information to interpret what the asset is
    * @notice decimals is the decimals to format asset balances
    * @notice if asset is an ERC20 token, assetType = 0, assetAddress is the address of the token
    * @notice if asset is liquidity of an AMM (like sqrt(k) in UniswapV2 forks), assetType = 1,
    assetAddress is the address of the LP token
    * @notice assetDecimals is the decimals of the asset
    */
	function assetInfo()
		external
		view
		returns (
			AssetType assetType,
			address assetAddress,
			uint8 assetDecimals
		);
}