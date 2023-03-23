// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./library/erc721A/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

error LobstarbotsAiGeneration__SecondarySalesAreNotAllowed();

contract LobstarbotsAiGeneration is ERC721A, Ownable {
	string private s_baseTokenUri = "ipfs://QmUZZEyMMwbK9g8eE693qdwQWmvemMrtaaCPgPD3LE35WD/";

	constructor() ERC721A("The Lobstarbots AI Generation", "LOB-AI") {}

	/**
	 * @dev Airdrop tokens to a list of recipients.
	 * Order of the wallets will determine the order of the token IDs recieved.
	 *
	 * @param airdropTo The list of recipients.
	 */
	function airdrop(address[] calldata airdropTo) external onlyOwner {
		for (uint256 i = 0; i < airdropTo.length; i++) {
			_safeMint(airdropTo[i], 1);
		}
	}

	/**
	 * @dev Set base URI for token metadata.
	 *
	 * @param baseUri The base URI for token metadata.
	 */
	function setBaseUri(string calldata baseUri) external onlyOwner {
		s_baseTokenUri = baseUri;
	}

	// Override ERC721A functions to prevent secondary sales.
	function setApprovalForAll(address operator, bool approved) public pure override {
		revert LobstarbotsAiGeneration__SecondarySalesAreNotAllowed();
	}

	function approve(address operator, uint256 tokenId) public pure override {
		revert LobstarbotsAiGeneration__SecondarySalesAreNotAllowed();
	}

	/**
	 * @dev Starting ID for the tokens.
	 *
	 * @return The starting ID for the tokens.
	 */
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	/**
	 * @dev Get base token URI.
	 *
	 * @return The base token URI.
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return s_baseTokenUri;
	}
}