// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EV3 is ERC721, Ownable, ReentrancyGuard, IERC2981 {
	using Counters for Counters.Counter;
	using Address for address payable;
	using MerkleProof for bytes32[];

	bytes32 public whitelistRoot;
    bytes32 public freeMintRoot;

    string  public baseTokenURI = "";

	uint256 public constant MAX_SUPPLY = 6000;
    uint256 public WHITELIST_MAX_MINT = 2;
	uint256 public constant FREE_MINT_MAX_MINT = 1;
	uint256 public constant PUBLIC_MAX_MINT = 5;
	uint256 public constant WHITELIST_PRICE = 0.01 ether;
	uint256 public constant PUBLIC_PRICE = 0.02 ether;
	uint256 public constant MAX_PUBLIC_SUPPLY = 5750;

	mapping(address => bool) public whitelist;
	mapping(address => uint256) public freeminted;
	mapping(address => uint256) public publicMinted;
	uint256 public publicSupply;

	Counters.Counter private _tokenIdCounter;

    bool public isWhitelistEnabled = false;
    bool public isFreeMintEnabled = false;
    bool public isPublicMintEnabled = false;

    constructor(bytes32 _whitelistRoot, bytes32 _freeMintRoot) ERC721("EV3", "EV3") {
        whitelistRoot = _whitelistRoot;
        freeMintRoot = _freeMintRoot;
    }

    function mintWhitelist(bytes32[] memory proof, uint256 amount) public nonReentrant payable {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of EVLIST");
        require(isWhitelistEnabled, "EVLIST minting is not enabled");
        require(WHITELIST_PRICE * amount == msg.value, "Incorrect amount sent");
        require(publicSupply + amount <= MAX_PUBLIC_SUPPLY, "Exceeds maximum public supply");
        require(publicMinted[msg.sender] + amount <= WHITELIST_MAX_MINT, "Already minted maximum EV3 NFTs");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
        
        publicSupply += amount;
        publicMinted[msg.sender] += amount;
    }


    function mintFree(address to, bytes32[] memory proof) public nonReentrant{
        require(isValidFree(proof, keccak256(abi.encodePacked(to))), "Not a part of EVLIST II");
        require(isFreeMintEnabled, "Free minting is not enabled");
        require(freeminted[msg.sender] == 0, "Already minted EV3 NFT");
        require(publicSupply + 1 <= MAX_PUBLIC_SUPPLY, "Exceeds maximum public supply");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        publicSupply += 1;
        freeminted[msg.sender] += 1;
    }

	function mintPublic(uint256 amount) public nonReentrant payable {
        require(isPublicMintEnabled, "Public minting is not enabled");
	    require(PUBLIC_PRICE * amount == msg.value, "Incorrect amount sent");
	    require(publicSupply + amount <= MAX_PUBLIC_SUPPLY, "Exceeds maximum supply");
	    require(publicMinted[msg.sender] + amount < PUBLIC_MAX_MINT, "Already minted maximum EV3 NFTs");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
	    
	    publicSupply += amount;
	    publicMinted[msg.sender] += amount;
	}

	function mintAirdrop(address[] memory recipients, uint256 numNFT) public onlyOwner {
	    require(numNFT == 1 || numNFT == 2, "Invalid number of NFTs to airdrop");
	    require(publicSupply + recipients.length * numNFT <= MAX_PUBLIC_SUPPLY, "Exceeds maximum public supply");
	    for (uint256 i = 0; i < recipients.length; i++) {
	        for (uint256 j = 0; j < numNFT; j++) {
	            uint256 tokenId = _tokenIdCounter.current();
	            _tokenIdCounter.increment();
	            _safeMint(recipients[i], tokenId);
	            publicSupply += 1;
	        }
	    }
	}

	function ownerMint(address to, uint256 amount) public onlyOwner {
	    require(publicSupply + amount <= MAX_SUPPLY, "Exceeds maximum supply");
	    uint256 tokenId = _tokenIdCounter.current();
	    _tokenIdCounter.increment();
	    _safeMint(to, tokenId);
	    publicSupply += amount;
	}

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, whitelistRoot, leaf);
    }

    function isValidFree(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, freeMintRoot, leaf);
    }

	function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
	    return (owner(), salePrice * 10 / 100);
	}

	function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

	function setWhitelist(address[] memory users) public onlyOwner {
	    for (uint256 i = 0; i < users.length; i++) {
	        whitelist[users[i]] = true;
	    }
	}

    function toggleWhitelistStage() public onlyOwner {
        isWhitelistEnabled = !isWhitelistEnabled;
    }

    function toggleFreemintStage() public onlyOwner {
        isFreeMintEnabled = !isFreeMintEnabled;
    }

    function togglePublicStage() public onlyOwner {
        isPublicMintEnabled  = !isPublicMintEnabled ;
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory tokenIdStr = Strings.toString(tokenId);
        string memory base = _baseURI();
        return bytes(base).length > 0
            ? string(abi.encodePacked(base, tokenIdStr, ".json"))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function updateRoots(bytes32 _whitelistRoot, bytes32 _freeMintRoot) public onlyOwner {
        whitelistRoot = _whitelistRoot;
        freeMintRoot = _freeMintRoot;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


}