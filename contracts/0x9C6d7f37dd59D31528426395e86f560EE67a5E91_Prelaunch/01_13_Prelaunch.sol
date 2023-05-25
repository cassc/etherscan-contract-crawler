// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WhiteListCustom.sol";

contract Prelaunch is Ownable, WhitelistCustom, ReentrancyGuard {
	using SafeERC20 for IERC20;
	mapping(address => uint256) public claimed;
	address public token;

	constructor(address _signer) WhitelistCustom(_signer) {}

	function payday(uint256 nonce, uint256 amount, uint256 maxAmount, bytes memory signature) external nonReentrant {
		require(token != address(0), "Set token first");
		require(claimed[msg.sender] + amount <= maxAmount, "Over limit");

		_checkWhitelist(msg.sender, maxAmount, nonce, signature);
		claimed[msg.sender] += amount;
		IERC20(token).safeTransfer(msg.sender, amount);
	}

	// RESTRICTED SECTION
	function setToken(address _token) external onlyOwner {
		require(token == address(0), "Token already set");
		token = _token;
	}

	function start() external onlyOwner {
		_startPrelaunchMint();
	}

	function stop() external onlyOwner {
		_pausePrelaunchMint();
	}

	function updateSigner(address _signer) external onlyOwner {
		_changeSigner(_signer);
	}

	function removeSig(uint256 _nonce) external onlyOwner {
		_removeFromWhitelist(_nonce);
	}

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success);
	}
}