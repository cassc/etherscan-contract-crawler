// SPDX-License-Identifier: AGPL-1.0-only

pragma solidity ^0.8.4;

// Welcome to Supremacy!
//
// Artwork by Herman K. Lau, 1993 from https://www.eyrie.org/~sw/btech/btechasc.htm
// Battletech Madcat
//       ____          ____
//       |oooo|        |oooo|
//       |oooo| .----. |oooo|
//       |Oooo|/\_||_/\|oooO|
//       `----' / __ \ `----'
//       ,/ |#|/\/__\/\|#| \,
//      /  \|#|| |/\| ||#|/  \
//     / \_/|_|| |/\| ||_|\_/ \
//    |_\/    o\=----=/o    \/_|
//    <_>      |=\__/=|      <_>
//    <_>      |------|      <_>
//    | |   ___|======|___   | |
//   //\\  / |O|======|O| \  //\\
//   |  |  | |O+------+O| |  |  |
//   |\/|  \_+/        \+_/  |\/|
//   \__/  _|||        |||_  \__/
//         | ||        || |
//        [==|]        [|==]
//        [===]        [===]
//         >_<          >_<
//        || ||        || ||
//        || ||        || ||
//        || ||        || ||  -JT
//      __|\_/|__    __|\_/|__
//     /___n_n___\  /___n_n___\

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./Crypto_SignatureVerifier.sol";

/// @custom:security-contact [email protected]
contract NFT is ERC721, ERC721Enumerable, SignatureVerifier, Ownable {
	mapping(address => uint256) public nonces;

	string baseURI;

	constructor(
		address signer,
		string memory name,
		string memory symbol
	) ERC721(name, symbol) SignatureVerifier(signer) {}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function devBurn(uint256 id) public onlyOwner {
		_burn(id);
	}

	function devSetBaseURI(string calldata newURI) public onlyOwner {
		baseURI = newURI;
	}

	// devMint mints an NFT
	function devMint(address to, uint256 id) public onlyOwner {
		_safeMint(to, id);
	}

	// devSetSigner updates the signer
	function devSetSigner(address _signer) public onlyOwner {
		setSigner(_signer);
	}

	// devBatchMint mints multiple NFTs
	function devBatchMint(
		address to,
		uint256 fromID,
		uint256 amount
	) public onlyOwner {
		for (uint256 id = fromID; id < fromID + amount; id++) {
			_safeMint(to, id);
		}
	}

	// signedMint mints an NFT to msg.sender if signature is valid
	function signedMint(
		uint256 tokenID,
		bytes calldata signature,
		uint256 expiry
	) public {
		require(expiry > block.timestamp, "signature expired");
		bytes32 messageHash = getMessageHash(
			msg.sender,
			address(this),
			tokenID,
			nonces[msg.sender]++,
			expiry
		);

		require(verify(messageHash, signature), "Invalid Signature");
		_safeMint(msg.sender, tokenID);
	}

	// getMessageHash builds the hash for signature verification
	function getMessageHash(
		address account,
		address collectionAddr,
		uint256 tokenID,
		uint256 nonce,
		uint256 expiry
	) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encode(account, collectionAddr, tokenID, nonce, expiry)
			);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}