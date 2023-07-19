// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Exchange contract from pROOK to USDC
/// @author IANAL
contract ExchangepROOK is Ownable, Pausable {
	using SafeERC20 for IERC20;

	/// @notice pROOK
	IERC20 public immutable tokenPROOK;

	/// @notice USDC
	IERC20 public immutable tokenUSDC;

	/// @notice Exchange Rate
	uint256 public exchangeRate;

	/// @notice emitted when exchange pROOK to USDC
	event Exchange(address indexed user, uint256 amount, uint256 value);
	event ExchangeRateSet(uint256 exchangeRate);

	//
	// @notice constructor
	// @param _tokenPROOK pROOK token address
	// @param _tokenUSDC USDC token address
	// @param _exchangeRate exchange rate of USDC per pROOK value with 4 decimals
	//
	constructor(IERC20 _tokenPROOK, IERC20 _tokenUSDC, uint256 _exchangeRate) Ownable() {
		tokenPROOK = _tokenPROOK;
		tokenUSDC = _tokenUSDC;
		exchangeRate = _exchangeRate;
		_pause();
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * @notice Exchange rate value with 4 decimals, example 455000 = $45.50
	 * @param _exchangeRate amount of USDC per pROOK (USD / pROOK)
	 */
	function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
		exchangeRate = _exchangeRate;
		emit ExchangeRateSet(_exchangeRate);
	}

	/**
	 * @notice Withdraw IERC20 token
	 * @param _token address for withdraw
	 * @param _amount to withdraw
	 */
	function withdrawAssets(IERC20 _token, uint256 _amount) external onlyOwner {
		_token.safeTransfer(owner(), _amount);
	}

	/**
	 * @notice Exchange from pROOK to USDC
	 * @param _amount of pROOK exchanged
	 */
	function exchange(uint256 _amount) external whenNotPaused {
		tokenPROOK.safeTransferFrom(_msgSender(), address(this), _amount);
		uint256 _value = _amount * exchangeRate / 1e16; // @note 1e18 * 1e4 / 1e16 = 1e6
		tokenUSDC.safeTransfer(_msgSender(), _value);

		emit Exchange(_msgSender(), _amount, _value);
	}
}