// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721A.sol";

contract AnonymousRebels is ERC721A, Ownable {
	using Strings for uint256;
	string private _collectionURI;
	string public baseURI;
	string public baseExtension = ".json";
	string public unrevealedUri;
	bool public isRevealed = false;
	uint public PRICE = 0.25 ether;
	uint public WHITELIST_PRICE = 0.2 ether;
	uint public MAX_SUPPLY = 777;

	address public _crossmintAddress =
		0xdAb1a1854214684acE522439684a145E62505233;
	bytes32 public merkleRoot =
		0xc81da8743d5c4ee6e9f070f5cd0fd03232faf4c321a96f51eabc7747a51fd5c2;
	bool public _paused = false;
	bool public _isPresale = false;
	bool public _isPublicsale = false;

	mapping(address => uint) public addressMintedBalance;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initNotRevealedUri
	) ERC721A(_name, _symbol) {
		setUnrevealedURI(_initNotRevealedUri);
	}

	receive() external payable {}

	fallback() external payable {}

	// public
	function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        if (!isRevealed) {
            return unrevealedUri;
        }

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

	function setUnrevealedURI(string memory _unrevealedUri) public onlyOwner {
        unrevealedUri = _unrevealedUri;
    }

	function mint(uint _mintAmount, bytes32[] memory proof) external payable {
		require(!_paused, "the contract is paused");
		require(_mintAmount > 0, "need to mint at least 1 NFT");

		uint supply = totalSupply();
		require(supply + _mintAmount <= MAX_SUPPLY, "max NFT limit exceeded");

		if (msg.sender != owner()){
			bool isMerkleWhitelisted = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
			if (isMerkleWhitelisted) {
				require(_isPresale || _isPublicsale, "Sale not started");
				require(
					msg.value >= WHITELIST_PRICE * _mintAmount,
					"insufficient funds"
				);
				_safeMint(msg.sender, _mintAmount);
			} else {
				require(_isPublicsale, "Public sale not started");
				require(
					msg.value >= PRICE * _mintAmount,
					"insufficient funds"
				);
				_safeMint(msg.sender, _mintAmount);
			}
			} else {
				_safeMint(msg.sender, _mintAmount);
			}
		}
		

	function crossmint(address to, uint _count) public payable {
		require(!_paused, "Sale is currently paused.");
		require(_isPublicsale, "Public sale has not started.");
		require(
			msg.sender == _crossmintAddress,
			"This function is for Crossmint only."
		);
		require(msg.value >= PRICE * _count, "Ether sent is not correct.");
		require(to != address(0x0), "Destination address should be valid");

		uint supply = totalSupply();
		require(supply + _count <= MAX_SUPPLY, "Exceeds max supply.");
		_safeMint(to, _count);
	}

	// internal

	function reveal() public onlyOwner {
		isRevealed = true;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	function setPrice(uint256 _newPrice) public onlyOwner {
		PRICE = _newPrice;
	}

	function setWhitelistPrice(uint256 _newWhitelistPrice) public onlyOwner {
		WHITELIST_PRICE = _newWhitelistPrice;
	}

	function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
		// Needs 0x infront of it!
		merkleRoot = _newMerkleRoot;
	}
	function pause(bool _state) public onlyOwner {
		_paused = _state;
	}

	function setIsPresale(bool _state) public onlyOwner {
		_isPresale = _state;
	}

	function setIsPublicSale(bool _state) public onlyOwner {
		_isPublicsale = _state;
	}

	/**
	 * @dev set collection URI for marketplace display
	 */
	function setCollectionURI(string memory collectionURI)
		internal
		virtual
		onlyOwner
	{
		_collectionURI = collectionURI;
	}

	function withdraw() public payable {
		require(msg.sender == 0x223b473C2166025b07Ee91959313F4f7cF499AA7);
		(bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(os);
	}

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}