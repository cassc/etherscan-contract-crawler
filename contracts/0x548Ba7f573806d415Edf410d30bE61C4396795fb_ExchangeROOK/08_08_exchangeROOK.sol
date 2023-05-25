// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Exchange contract from ROOK to pROOK and USDC
/// @author IANAL
contract ExchangeROOK is Ownable, Pausable {
	using SafeERC20 for IERC20;

	/// @notice ROOK
	IERC20 public immutable tokenROOK;

	/// @notice pROOK
	IERC20 public immutable tokenPROOK;

	/// @notice USDC
	IERC20 public immutable tokenUSDC; //

	/// @notice Exchange Rate
	uint256 public exchangeRate;

	/// @notice emitted when exchange ROOK to pROOK and USDC
	event Exchange(address indexed user, uint256 amount, uint256 value);
	event ExchangeRateSet(uint256 exchangeRate);

	//
	// @notice constructor
	// @param _tokenROOK ROOK token address
	// @param _tokenPROOK pROOK token address
	// @param _tokenUSDC USDC token address
	// @param _exchangeRate exchange rate value of USDC per ROOK with 4 decimals
	//
	constructor(IERC20 _tokenROOK, IERC20 _tokenPROOK, IERC20 _tokenUSDC, uint256 _exchangeRate) Ownable() {
		tokenROOK = _tokenROOK;
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
	 * @param _exchangeRate amount of USDC per ROOK (USD / ROOK)
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
	 * @notice Exchange from ROOK to pROOK and USDC
	 * @param _amount of ROOK exchanged
	 */
	function exchange(uint256 _amount) external whenNotPaused {
		tokenROOK.safeTransferFrom(_msgSender(), address(this), _amount);
		uint256 _value = _amount * exchangeRate / 1e16; // @note 1e18 * 1e4 / 1e16 = 1e6
		tokenPROOK.safeTransfer(_msgSender(), _amount);
		tokenUSDC.safeTransfer(_msgSender(), _value);

		emit Exchange(_msgSender(), _amount, _value);
	}
}