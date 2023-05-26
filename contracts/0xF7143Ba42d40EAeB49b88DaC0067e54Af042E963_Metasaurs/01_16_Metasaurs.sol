// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
       ___ ___       __             __   __
 |\/| |__   |   /\  /__`  /\  |  | |__) /__`
 |  | |___  |  /~~\ .__/ /~~\ \__/ |  \ .__/

*/
contract Metasaurs is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;
	using ECDSA for bytes32;

	string private _baseTokenURI = "https://api.metasaurs.com/metadata/";
	string private _contractURI = "ipfs://QmeHMkGomVni2f4jPj3zHZykCsJqvi5PzC2VysFaXhXQ5A";

	//this points to the initial IPFS provenance hashes
	string private ipfsProvenance;

	uint256 public maxSupply = 9999;
	uint256 public maxPresale = 8000;

	mapping(string => bool) private _usedNonces;
	address private _signerAddress = 0xEAa3fD5F542b0c3501958F792028ED16aFA84e34; //Metasaur Signer

	uint256 public pricePerToken = 70000000000000000; //0.07 ETH

	bool public saleLive = false;
	bool public saleLiveX2 = false;
	bool public presaleLive = false;
	bool public locked;

	//triggers on gamification event
	event CustomThing(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor() ERC721("Metasaurs", "MTS") {}

	//for anti-bot/whale checks, the transaction MUST pass though our backend
	function publicBuy(
		bytes32 hash,
		bytes memory sig,
		string memory nonce
	) external payable {
		require(saleLive, "not live");
		require(matchAddresSigner(hash, sig), "no direct mint");
		require(totalSupply() + 1 <= maxSupply, "out of stock");
		require(pricePerToken == msg.value, "exact amount needed");
		require(!_usedNonces[nonce], "nonce already used");
		require(hashTransaction(msg.sender, 1, nonce) == hash, "hash check failed");
		_usedNonces[nonce] = true;
		_safeMint(msg.sender, totalSupply() + 1);
	}

	//X2 version...probably never to be used
	function publicBuyX2(uint256 qty) external payable {
		require(saleLiveX2, "not live X2");
		require(qty <= 5, "no more than 5");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	//teh presale
	function presaleBuy(
		bytes32 hash,
		bytes memory sig,
		uint256 qty,
		string memory nonce
	) external payable nonReentrant {
		require(presaleLive, "presale not live");
		require(matchAddresSigner(hash, sig), "no direct mint");
		require(qty <= 5, "no more than 5");
		require(hashTransaction(msg.sender, qty, nonce) == hash, "hash check failed");
		require(totalSupply() + qty <= maxPresale, "presale out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		require(!_usedNonces[nonce], "nonce already used");

		_usedNonces[nonce] = true;
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) public onlyOwner {
		require(qty > 0, "minimum 1 token");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(to, totalSupply() + 1);
		}
	}

	//custom thingy for future games
	function customThing(
		uint256 nftID,
		uint256 id,
		string memory what
	) external payable {
		require(ownerOf(nftID) == msg.sender, "NFT ownership required");
		emit CustomThing(nftID, msg.value, id, what);
	}

	//------------------------------------
	//----------- signing code -----------
	//------------------------------------
	function setSignerAddress(address addr) external onlyOwner {
		_signerAddress = addr;
	}

	function hashTransaction(
		address sender,
		uint256 qty,
		string memory nonce
	) private pure returns (bytes32) {
		bytes32 hash = keccak256(
			abi.encodePacked(
				"\x19Ethereum Signed Message:\n32",
				keccak256(abi.encodePacked(sender, qty, nonce))
			)
		);
		return hash;
	}

	function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
		return _signerAddress == hash.recover(signature);
	}

	//----------------------------------
	//----------- other code -----------
	//----------------------------------
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
		_burn(tokenId);
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		require(!locked, "locked functions");
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function togglePresaleStatus() external onlyOwner {
		presaleLive = !presaleLive;
	}

	function toggleSaleStatus() external onlyOwner {
		saleLive = !saleLive;
	}

	function toggleSaleStatusX2() external onlyOwner {
		saleLiveX2 = !saleLiveX2;
	}

	function changePrice(uint256 newPrice) external onlyOwner {
		pricePerToken = newPrice;
	}

	function changeMaxPresale(uint256 _newMaxPresale) external onlyOwner {
		maxPresale = _newMaxPresale;
	}

	function setIPFSProvenance(string memory _ipfsProvenance) external onlyOwner {
		bytes memory tempEmptyStringTest = bytes(ipfsProvenance);
		require(tempEmptyStringTest.length == 0, "ipfs provenance already set");
		ipfsProvenance = _ipfsProvenance;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "you can only decrease it");
		maxSupply = newMaxSupply;
	}

	// and for the eternity....
	function lockMetadata() external onlyOwner {
		locked = true;
	}
}