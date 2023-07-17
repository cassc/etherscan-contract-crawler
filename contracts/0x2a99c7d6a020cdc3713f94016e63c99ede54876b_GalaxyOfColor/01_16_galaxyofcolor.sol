// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract GalaxyOfColor is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer, ERC721AQueryable {
	using Strings for uint;

    bytes32 public root;

	uint public maxSupply = 821;

	uint public maxPerWalletWhitelist = 2;
	uint public maxPerWalletPublic = 4;
    uint public maxPerTransaction = 2;

	uint public whitelistPrice = 0.02 ether;
	uint public publicPrice = 0.02 ether;

	bool public isPublicMint = false;
    bool public isWhitelistMint = false;

    string public _baseURL = "ipfs://bafybeifev363e23d5qwxofur5txt3brfojhdlq5ibdz3gdx4o4s4isdgii/";
	string public suffix = ".json";

	string public prerevealURL = "";

    //**                          WITHDRAW WALLET                          **//
    address public withdrawAddress = 0x928E29d8fA345FFb8149E50c5A9DbD1acd779D55;

	mapping(address => uint) private _walletMintedCount;

	constructor()
	ERC721A("Galaxy Of Color", "COLOR") {
    }
    
    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "";
	}

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

	function tokenURI(uint tokenId)
		public
		view
		override(ERC721A, IERC721A)
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), suffix))
            : prerevealURL;
	}

	function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

	/*
			"SET VARIABLE" FUNCTIONS
	*/

	// Metadata Prefix/Suffix
	function setBaseURI(string memory url) external onlyOwner {
		_baseURL = url;
	}

	function setSuffix(string memory _suffix) external onlyOwner {
		suffix = _suffix;
	}

	// Merkle Root
    function setRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}

	// Max Pers
	function setMaxPerWalletWhitelist(uint _max) external onlyOwner {
		maxPerWalletWhitelist = _max;
	}

	function setMaxPerWalletPublic(uint _max) external onlyOwner {
		maxPerWalletPublic = _max;
	}

	function setMaxPerTransaction(uint _max) external onlyOwner {
		maxPerTransaction = _max;
	}

	// Prices
    function setPublicPrice(uint _price) external onlyOwner {
		publicPrice = _price;
	}

    function setWhitelistPrice(uint _price) external onlyOwner {
		whitelistPrice = _price;
	}

	// Mint States
	function setPublicState(bool value) external onlyOwner {
		isPublicMint = value;
	}

    function setWhitelistState(bool value) external onlyOwner {
		isWhitelistMint = value;
	}

	// Supplies
	function setMaxSupply(uint newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
	}

	/*
			AIRDROP FUNCTIONS
	*/

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			"Exceeds max supply"
		);
		_safeMint(to, count);
	}

    function airdropMultiAddress(address[] memory receivers, uint256 count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			"Exceeds max supply"
		);
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], count);
        }
    }

	/*
			MINT FUNCTIONS
	*/

    function whitelistMint(uint count, bytes32[] memory proof) external payable {
		require(isWhitelistMint, "Whitelist mint has not started");
		require(_totalMinted() + count <= maxSupply,"Exceeds max supply");
		require(count <= maxPerTransaction,"Exceeds NFT per transaction limit");
        require(_walletMintedCount[msg.sender] + count <= maxPerWalletWhitelist,"Exceeds max per wallet");

        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Wallet not on the allowlist");

        require(
			msg.value >= count * whitelistPrice,
			"Ether value sent is not sufficient"
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
    
    function publicMint(uint count) external payable {
		require(isPublicMint, "Public mint has not started");
		require(_totalMinted() + count <= maxSupply, "Exceeds max supply");
		require(count <= maxPerTransaction, "Exceeds NFT per transaction limit");
        require(_walletMintedCount[msg.sender] + count <= maxPerWalletPublic, "Exceeds max per wallet");

		require(
			msg.value >= count * publicPrice,
			"Ether value sent is not sufficient"
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}

	/*
			OPENSEA OPERATOR OVERRIDES (ROYALTIES)
	*/

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    string public DEV = unicode"Viperware Labs 🧪";

}