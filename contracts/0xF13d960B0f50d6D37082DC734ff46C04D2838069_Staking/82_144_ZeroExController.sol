// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWallet.sol";
import "./BaseController.sol";

contract ZeroExController is BaseController {
	using SafeERC20 for IERC20;
	using Address for address;
	using Address for address payable;
	using SafeMath for uint256;

	// solhint-disable-next-line
	IWallet public immutable WALLET;

	constructor(
		IWallet wallet,
		address manager,
		address accessControl,
		address addressRegistry
	) public BaseController(manager, accessControl, addressRegistry) {
		require(address(wallet) != address(0), "INVALID_WALLET");
		WALLET = wallet;
	}

	/// @notice Deposits tokens into WALLET
	/// @dev Call to external contract via _approve functions
	/// @param data Bytes containing an array of token addresses and token accounts
	function deploy(bytes calldata data) external onlyManager onlyAddLiquidity {
		(address[] memory tokens, uint256[] memory amounts) = abi.decode(data, (address[], uint256[]));
		uint256 tokensLength = tokens.length;
		for (uint256 i = 0; i < tokensLength; ++i) {
			require(addressRegistry.checkAddress(tokens[i], 0), "INVALID_TOKEN");
			_approve(IERC20(tokens[i]), amounts[i]);
		}
		WALLET.deposit(tokens, amounts);
	}

	/// @notice Withdraws tokens from WALLET
	/// @param data Bytes containing address and uint256 array
	function withdraw(bytes calldata data) external onlyManager onlyRemoveLiquidity {
		(address[] memory tokens, uint256[] memory amounts) = abi.decode(data, (address[], uint256[]));
		for (uint256 i = 0; i < tokens.length; ++i) {
			require(addressRegistry.checkAddress(tokens[i], 0), "INVALID_TOKEN");
		}
		WALLET.withdraw(tokens, amounts);
	}

	function _approve(IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), address(WALLET));
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(address(WALLET), currentAllowance);
		}
		token.safeIncreaseAllowance(address(WALLET), amount);
	}
}