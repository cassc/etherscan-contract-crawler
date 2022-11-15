// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DigiNationTokenClaim is 
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable
{
	using ECDSAUpgradeable for bytes32;
	using ECDSAUpgradeable for bytes;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	function initialize(address msgSigner) public virtual initializer {
		__Context_init_unchained();
		__Ownable_init_unchained();

		setMsgSigner(msgSigner);
	}

	address public _msgSigner;

	mapping(address => mapping(address => uint256)) private _claimNonce;

	event Claimed(address indexed sender, address indexed tokenContract, uint256 amount, uint256 nonce);
	event MsgSignerChanged(address indexed oldMsgSigner, address indexed newMsgSigner);

	function fetchETH() external onlyOwner {
		payable(_msgSender()).transfer(address(this).balance);
	}

	function fetchToken(address tokenContract) external onlyOwner {
		IERC20Upgradeable claimToken = IERC20Upgradeable(tokenContract);
		claimToken.safeTransfer(_msgSender(), claimToken.balanceOf(address(this)));
	}
	
	function setMsgSigner(address newMsgSigner) public onlyOwner {
		require(newMsgSigner != address(0), "msgSigner can't be address(0)");
		address oldMsgSigner = _msgSigner;
		_msgSigner = newMsgSigner;
		emit MsgSignerChanged(oldMsgSigner, newMsgSigner);
	}

	function getClaimNonce(address sender, address tokenContract) public view returns (uint256) {
		return _claimNonce[sender][tokenContract];
	}

	function claim(
		address tokenContract,
		uint256 amount,
		uint256 nonce,
		bytes memory sig
	) external {
		// Check Signature
		bytes32 message = keccak256(abi.encodePacked(_msgSender(), tokenContract, amount, nonce));
		require(message.recover(sig) == _msgSigner, "Signature verification failed");

		// Check nonce
		require(nonce > getClaimNonce(_msgSender(), tokenContract), "Nonce error");

		// Check token balance
		IERC20Upgradeable claimToken = IERC20Upgradeable(tokenContract);

		// Transfer
		claimToken.safeTransfer(_msgSender(), amount);

		// Set nonce
		_claimNonce[_msgSender()][tokenContract] = nonce;

		// Emit event
		emit Claimed(_msgSender(), tokenContract, amount, nonce);
	}

	uint256[50] private __gap;
}