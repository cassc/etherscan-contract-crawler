// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CloudChaserGenesisNFT is ERC721, Ownable {
	using Counters for Counters.Counter;

	uint256 public constant totalSupply = 72;
	string public constant contractURI = "https://cdn.cloud-chasers.com/genesis-contract.json";

	Counters.Counter private currentTokenId;

	/// @dev Base token URI used as a prefix by tokenURI().
	string public baseTokenURI;

	constructor() ERC721("CloudChaserGenesisNFT", "CCGN") {
		baseTokenURI = "";
	}

	function mintTo(address recipient) public onlyOwner returns (uint256) {
		uint256 tokenId = currentTokenId.current();
		require(tokenId < totalSupply, "Max supply reached");

		currentTokenId.increment();
		uint256 newItemId = currentTokenId.current();
		_safeMint(recipient, newItemId);
		return newItemId;
	}

	function mintArray(address[] calldata recipients) external onlyOwner {
		for (uint i = 0; i < recipients.length; i++) {
			mintTo(recipients[i]);
		}
	}

	/// @dev Returns an URI for a given token ID
	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}

	/// @dev Sets the base token URI prefix.
	function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
		baseTokenURI = _baseTokenURI;
	}
}

contract CloudChaserNFT is ERC721, Ownable {
	using Counters for Counters.Counter;

	uint256 public constant totalSupply = 7272;
	uint256 public constant PUBLIC_MINT_PRICE = 0.10 ether; //tmp
	uint256 public constant WHITELIST_MINT_PRICE = 0.08 ether; //tmp
	bool public whitelist_only = true;
	mapping(address => bool) public whitelist;
	mapping(uint256 => uint8) public benefits_used;

	CloudChaserGenesisNFT GenesisContract = CloudChaserGenesisNFT(0x0000000000000000000000000000000000000000);

	Counters.Counter private currentTokenId;

	/// @dev Base token URI used as a prefix by tokenURI().
	string public baseTokenURI;

	constructor() ERC721("CloudChaserNFT", "CCN") {
		baseTokenURI = "";
	}

	function contractURI() external pure returns (string memory) {
		return "https://cdn.cloud-chasers.com/contract.json";
	}

	function addToWhitelist(address _address) external onlyOwner {
		whitelist[_address] = true;
	}

	function addArrayToWhitelist(address[] calldata addresses) external onlyOwner {
		for (uint i = 0; i < addresses.length; i++) {
			whitelist[addresses[i]] = true;
		}
	}

	function removeFromWhitelist(address _address) external onlyOwner {
		whitelist[_address] = false;
	}

	function mintTo(address recipient, uint256 benefit_token_id) external payable returns (uint256) {
		if (whitelist_only) {
			if (benefit_token_id == 0) {// set benefit_token_id to 0 if you are in the whitelist
				require(whitelist[msg.sender], "You must be whitelisted to mint an NFT");
				require(msg.value == WHITELIST_MINT_PRICE, "Transaction value did not equal the whitelist mint price");
				whitelist[msg.sender] = false;
			} else {// set benefit_token_id to the genesis token Id you want to use
				require(GenesisContract.ownerOf(benefit_token_id) == msg.sender);
				require(benefits_used[benefit_token_id] < 3, "This token is used up");
				if (benefits_used[benefit_token_id] == 2) {//the first two are free, the third one is paid
					require(msg.value == WHITELIST_MINT_PRICE, "Transaction value did not equal the whitelist mint price");
				}
				benefits_used[benefit_token_id] ++;
			}
		}
		// also set benefit_token_id to 0 if we have gone public
		uint256 tokenId = currentTokenId.current();
		require(tokenId < totalSupply, "Max supply reached");
		require(msg.value == PUBLIC_MINT_PRICE, "Transaction value did not equal the mint price");

		currentTokenId.increment();
		uint256 newItemId = currentTokenId.current();
		_safeMint(recipient, newItemId);
		return newItemId;
	}

	/// @dev Returns an URI for a given token ID
	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}

	/// @dev Sets the base token URI prefix.
	function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
		baseTokenURI = _baseTokenURI;
	}

	function goPublic() external onlyOwner {
		whitelist_only = false;
	}

	function withdraw(address payable _recipient, uint256 _amount) public onlyOwner {
		require(_amount <= address(this).balance, "Amount to withdraw is greater than the available balance");
		(bool success,) = _recipient.call{value : _amount}("");
		require(success, "Failed to send ether");
	}

	function split(uint256 totalAmount, address payable[] calldata recipients, uint256[] calldata permilles) external onlyOwner {
		require(recipients.length == permilles.length, "Array lengths unequal");
		require(totalAmount <= address(this).balance, "Amount to withdraw is greater than the available balance");
		//check if total permillage does not exceed 1000 promile
		uint total_permillage = 0;
		for (uint i = 0; i < permilles.length; i++) {
			total_permillage += permilles[i];
		}
		require(total_permillage <= 1000, "Sum of permilles exceeds 1000 permille");

		//send each recipient their respective permille of the total amount
		for (uint i = 0; i < recipients.length; i++) {
			withdraw(recipients[i], totalAmount * permilles[i] / 1000);
		}
	}
}