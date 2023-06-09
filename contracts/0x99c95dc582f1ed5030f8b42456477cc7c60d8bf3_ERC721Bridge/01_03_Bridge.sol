pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Bridge {
	event OrdinalBridged(
		address indexed sender,
		uint256 tokenId,
		string bitcoinAddress
	);

	function bridgeERC721(
		uint256 tokenId,
		string calldata bitcoinAddress
	) external {
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
	}
}