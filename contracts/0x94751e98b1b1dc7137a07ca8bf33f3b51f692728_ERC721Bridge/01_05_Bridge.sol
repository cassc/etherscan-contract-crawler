pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Bridge is Ownable {
	address public claimFeeReceiver;
	mapping(address => bool) public isClaimFeePaid;
	uint256 public claimFee;

	constructor(address _claimFeeReceiver) {
		claimFeeReceiver = _claimFeeReceiver;
		claimFee = 0.0055 ether;
	}

	event OrdinalBridged(
		address indexed sender,
		uint256 tokenId,
		string bitcoinAddress
	);

	function payClaimFee() external payable {
		require(msg.value == claimFee, "Incorrect claim fee amount");
		require(!isClaimFeePaid[msg.sender], "Claim fee already paid");

		(bool success, ) = claimFeeReceiver.call{ value: msg.value }("");
		require(success, "Failed to transfer claim fee to receiver");

		isClaimFeePaid[msg.sender] = true;
	}

	function bridgeERC721(
		uint256 tokenId,
		string calldata bitcoinAddress
	) external {
		require(isClaimFeePaid[msg.sender], "Claim fee not paid");

		IERC721 tokenContract = IERC721(
			0xcBA890b4718Fc3f67821EecE841BA314fF554A8f
		);
		require(
			tokenContract.ownerOf(tokenId) == msg.sender,
			"You are not the owner of the token"
		);
		tokenContract.transferFrom(
			msg.sender,
			0x000000000000000000000000000000000000dEaD,
			tokenId
		);
		emit OrdinalBridged(msg.sender, tokenId, bitcoinAddress);

		// After token is bridged reset the claim fee, as user needs to pay for next token
		isClaimFeePaid[msg.sender] = false;
	}

	function setClaimFee(uint256 newFee) external onlyOwner {
		claimFee = newFee;
	}

	// This function is used entirely for development purposes, it's supposed to emit the log so we can debug
	// It emits that token with ID > 5000 has been bridged (No inscriptions are tied with this, so it's safe to test with this)
	function testCall(
		uint256 tokenId,
		string calldata bitcoinAddress
	) external onlyOwner {
		require(tokenId >= 5000, "Use non-existant Ordinal ID");

		emit OrdinalBridged(msg.sender, tokenId, bitcoinAddress);
	}
}