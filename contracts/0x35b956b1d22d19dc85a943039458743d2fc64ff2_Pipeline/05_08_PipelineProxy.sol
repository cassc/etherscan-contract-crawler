// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @dev Contract stores users approvals. Can transfer tokens from user to main account. 
contract PipelineProxy is Ownable, Pausable {
	using SafeERC20 for IERC20;
	address trusted;

	event TrustedChanged(address indexed newTrusted);

	modifier onlyTrusted() {
		require(msg.sender == trusted);
		_;
	}

	constructor(address _trusted) {
		_setTrusted(_trusted);
	}

	/// @dev Transfer tokens to main contract
	/// @param token Address of token that should be transfered
	/// @param from User from who token should be transfered
	/// @param amount Amount of tokens that should be transfered
	function transfer(address token, address from, uint256 amount) onlyTrusted whenNotPaused external {
		IERC20(token).safeTransferFrom(from, msg.sender, amount);
	}

	function _setTrusted(address _trusted) internal {
		trusted = _trusted;
		emit TrustedChanged(_trusted);
	}

	function pause() onlyOwner external {
		_pause();
	}

	function unpause() onlyOwner external {
		_unpause();
	}
}