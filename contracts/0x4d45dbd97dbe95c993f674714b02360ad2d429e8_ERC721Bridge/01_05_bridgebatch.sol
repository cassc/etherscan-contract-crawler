pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Bridge is Ownable {
	address public claimFeeReceiver;
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

	function bridgeERC721Batch(
		uint256[] calldata tokenIds,
		string calldata bitcoinAddress
	) external payable {
		uint256 numTokens = tokenIds.length;
		require(numTokens > 0, "No tokens to bridge");
		require(
			msg.value == claimFee * numTokens,
			"Incorrect claim fee amount"
		);

		(bool success, ) = claimFeeReceiver.call{ value: msg.value }("");
		require(success, "Failed to transfer claim fee to receiver");

		IERC721 tokenContract = IERC721(
			0xcBA890b4718Fc3f67821EecE841BA314fF554A8f
		);

		for (uint256 i = 0; i < numTokens; i++) {
			uint256 tokenId = tokenIds[i];

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
		}
	}

	function setClaimFee(uint256 newFee) external onlyOwner {
		claimFee = newFee;
	}
}