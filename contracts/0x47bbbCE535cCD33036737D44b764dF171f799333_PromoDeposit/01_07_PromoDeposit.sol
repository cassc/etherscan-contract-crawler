// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Simple contract to store users deposits
contract PromoDeposit is Ownable {
	using SafeERC20 for IERC20;

	address public recipient; // Recipient of deposits
	mapping(address => mapping(uint256 => uint256)) public aprs; // aprs[token][duration] = apr
	bool public finished;

	event RecipientChanged(address newRecipient);
	event Deposit(address indexed depositor, address indexed token, uint256 amount, uint256 duration, uint256 apr);

	modifier operational() {
		require(!finished, "Promo already finished");
		_;
	}

	constructor(
		address _recipient,
		address[] memory _addrs, 
		uint256[][] memory _durations, 
		uint256[][] memory _aprs
	) Ownable() {
		_changeRecipient(_recipient);
		setAprs(_addrs, _durations, _aprs);
	}

	/// @dev Main PromoDeposit function. Sends tokens to recipient. And emit event.
	/// @param token Token address
	/// @param amount Amount of tokens to transfer
	/// @param duration Amount of month 
	function deposit(address token, uint256 amount, uint256 duration) external operational {
		uint256 apr = aprs[token][duration]; 
		require(apr > 0, "This token is not allowed for such duration");
		// Transfer tokens to recipient
		IERC20(token).safeTransferFrom(msg.sender, recipient, amount);
		// Emit event	
		emit Deposit(msg.sender, token, amount, duration, apr);
	}

	function setAprs(address[] memory _addrs, uint256[][] memory _durations, uint256[][] memory _aprs) public onlyOwner {
		for (uint256 i = 0; i < _addrs.length; i++) {
			for (uint256 j = 0; j < _durations[i].length; j++) {
				aprs[_addrs[i]][_durations[i][j]] = _aprs[i][j];
			}
		}
	}

    function finish() external onlyOwner {
        finished = true;
    }

	function setFinished(bool value) external onlyOwner {
		finished = value;
	}

	function changeRecipient(address newRecipient) external onlyOwner {
		_changeRecipient(newRecipient);
	}

	function _changeRecipient(address newRecipient) internal {
		recipient = newRecipient;
		emit RecipientChanged(newRecipient);
	}
}