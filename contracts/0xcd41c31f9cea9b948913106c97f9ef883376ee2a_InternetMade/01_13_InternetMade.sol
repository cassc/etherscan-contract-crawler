// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

/*
          _____                    _____          
         /\    \                  /\    \         
        /::\    \                /::\____\        
        \:::\    \              /::::|   |        
         \:::\    \            /:::::|   |        
          \:::\    \          /::::::|   |        
           \:::\    \        /:::/|::|   |        
           /::::\    \      /:::/ |::|   |        
  ____    /::::::\    \    /:::/  |::|___|______  
 /\   \  /:::/\:::\    \  /:::/   |::::::::\    \ 
/::\   \/:::/  \:::\____\/:::/    |:::::::::\____\
\:::\  /:::/    \::/    /\::/    / ~~~~~/:::/    /
 \:::\/:::/    / \/____/  \/____/      /:::/    / 
  \::::::/    /                       /:::/    /  
   \::::/____/                       /:::/    /   
    \:::\    \                      /:::/    /    
     \:::\    \                    /:::/    /     
      \:::\    \                  /:::/    /      
       \:::\____\                /:::/    /       
        \::/    /                \::/    /        
         \/____/                  \/____/         
                                                  
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract InternetMade is ERC721, Ownable, ReentrancyGuard {
	using Strings for uint256;

	string public baseURI_0;
	string public baseURI_1;
	string public baseURI_2;

	string public notRevealedURI;
	string public PROVENANCE_0;
	string public PROVENANCE_1;
	string public PROVENANCE_2;
	string public baseExtension = ".json";

	bytes32 public merkleRoot;

	mapping(address => bool) mintedFF;
	mapping(address => uint8) amountMintedWhitelistPhase0;
	mapping(address => uint8) amountMintedWhitelistPhase1;
	mapping(address => uint8) amountMintedWhitelistPhase2;

	uint256 public costWhitelistedFF = 0.00 ether;
	uint256 public costWhitelisted = 0.10 ether;
	uint256 public costPublicSale = 0.15 ether;

	uint16 public totalSupply = 0;
	uint16 public maxSupply = 9999;
	uint16 public phaseMaxSupply0 = 3333;
	uint16 public phaseMaxSupply1 = 3333;

	uint16 public maxMintAmountWhitelistFF = 1;
	uint16 public maxMintAmountWhitelist = 2;
	uint16 public maxMintAmount = 2;
	uint8 public revealedPhasesCount = 0; // amount of revealed phases, possible values: 0, 1, 2, 3
	uint8 public phase = 0;

	bool public paused = false;
	bool public frozenMetadata = false;

	bool public onlyWhitelistedFF = true;
	bool public onlyWhitelisted = false;
	bool public onlyPublicSale = false;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initNotRevealedURI
	) ERC721(_name, _symbol) {
		setNotRevealedURI(_initNotRevealedURI);
	}

	//MINTING for onlyWhitelistedFF
	function mintWhitelistedFF(uint8 _mintAmount, bytes32[] calldata _merkleProof) external payable {
		require(onlyWhitelistedFF, "onlyWhitelistedFF is not active");
		require(isWhitelisted(msg.sender, _merkleProof), "You are not FF whitelisted");
		require(mintedFF[msg.sender] == false, "You already minted");
		require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountWhitelistFF, "Max allowed mint amount exceeded for FF whitelist");
		require(msg.value >= costWhitelistedFF * _mintAmount, "Insufficient ETH amount");

		mintedFF[msg.sender] = true;

		_mint(_mintAmount);
	}

	//MINTING for onlyWhitelisted
	function mintWhitelisted(uint8 _mintAmount, bytes32[] calldata _merkleProof) external payable {
		require(onlyWhitelisted, "onlyWhitelisted is not active");
		require(isWhitelisted(msg.sender, _merkleProof), "You are not whitelisted");
		uint8 amountMinted = 0;
		uint8 _phase = phase;
		if (_phase == 0) {
			amountMinted = amountMintedWhitelistPhase0[msg.sender];
		} else if (_phase == 1) {
			amountMinted = amountMintedWhitelistPhase1[msg.sender];
		} else {
			amountMinted = amountMintedWhitelistPhase2[msg.sender];
		}
		require(amountMinted + _mintAmount <= maxMintAmountWhitelist, "Max allowed mint amount exceeded for whitelist");

		require(msg.value >= costWhitelisted * _mintAmount, "Insufficient ETH amount");

		if (_phase == 0) {
			amountMintedWhitelistPhase0[msg.sender] += _mintAmount;
		} else if (_phase == 1) {
			amountMintedWhitelistPhase1[msg.sender] += _mintAmount;
		} else {
			amountMintedWhitelistPhase2[msg.sender] += _mintAmount;
		}

		_mint(_mintAmount);
	}

	//MINTING for PublicSale
	function mintPublicSale(uint8 _mintAmount) external payable {
		require(onlyPublicSale, "onlyPublicSale is not active");

		require(_mintAmount <= maxMintAmount, "Max allowed mint amount exceeded for PublicSale");
		require(msg.value >= costPublicSale * _mintAmount, "Insufficient ETH amount");

		_mint(_mintAmount);
	}

	//MINTING for onlyOwner
	function mintOnlyOwner(uint8 _mintAmount) external payable onlyOwner {
		_mint(_mintAmount);
	}

	//isWhitelisted
	function isWhitelisted(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(_user));
		return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "tokenId does not exist");
		if (!isPhaseRevealed(getPhaseForTokenId(tokenId))) {
			return notRevealedURI;
		}
		string memory baseURI = _baseURI(getPhaseForTokenId(tokenId));
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
	}

	//INTERNAL mint
	function _mint(uint8 _mintAmount) internal {
		require(!paused, "Please wait until unpaused");
		require(_mintAmount > 0, "Need to mint more than 0");
		require(totalSupply + _mintAmount <= phaseMaxSupply(), "Max allowed supply exceeded");
		require(totalSupply + _mintAmount <= maxSupply, "Not enough NFTs left to mint that many!");
		for (uint8 i = 1; i <= _mintAmount; i++) {
			incrementTotalSupply();
			_safeMint(msg.sender, totalSupply);
		}
	}

	function getPhaseForTokenId(uint256 tokenId) public view returns (uint8) {
		if (tokenId <= phaseMaxSupply0) return 0;
		if (tokenId <= phaseMaxSupply0 + phaseMaxSupply1) return 1;
		return 2;
	}

	function isPhaseRevealed(uint8 _phase) internal view returns (bool) {
		return _phase < revealedPhasesCount;
	}

	function _baseURI(uint8 _phase) internal view returns (string memory) {
		if (_phase == 0) {
			return baseURI_0;
		}
		if (_phase == 1) {
			return baseURI_1;
		}
		return baseURI_2;
	}

	function incrementTotalSupply() internal {
		totalSupply += 1;
	}

	//--------ONLY OWNER--------//

	//SETTERS FOR STRINGS
	function setBaseURI(string memory _newBaseURI, uint8 _phase) public onlyOwner validPhase(_phase) {
		require(!frozenMetadata, "Metadata is frozen");

		if (_phase == 0) {
			baseURI_0 = _newBaseURI;
		} else if (_phase == 1) {
			baseURI_1 = _newBaseURI;
		} else if (_phase == 2) {
			baseURI_2 = _newBaseURI;
		}
	}

	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedURI = _notRevealedURI;
	}

	function setProvenanceHash(string memory _provenanceHash, uint8 _phase) public onlyOwner {
		if (_phase == 0) {
			PROVENANCE_0 = _provenanceHash;
		} else if (_phase == 1) {
			PROVENANCE_1 = _provenanceHash;
		} else if (_phase == 2) {
			PROVENANCE_2 = _provenanceHash;
		}
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	//SETTERS FOR PAUSED, REVEALED, FREEZE METADATA AND PHASE
	function setPaused(bool _state) public onlyOwner {
		paused = _state;
	}

	function unreveal() public onlyOwner {
		revealedPhasesCount = 0;
	}

	function revealPhase0(string memory _baseURI_0) public onlyOwner {
		revealedPhasesCount = 1;
		if (!frozenMetadata) {
			baseURI_0 = _baseURI_0;
		}
	}

	function revealPhase1(string memory _baseURI_1) public onlyOwner {
		revealedPhasesCount = 2;
		if (!frozenMetadata) {
			baseURI_1 = _baseURI_1;
		}
	}

	function revealPhase2(string memory _baseURI_2) public onlyOwner {
		revealedPhasesCount = 3;
		if (!frozenMetadata) {
			baseURI_2 = _baseURI_2;
		}
	}

	function freezeMetadata() public onlyOwner {
		require(bytes(baseURI_0).length > 0, "Base URI 0 is not set");
		require(bytes(baseURI_1).length > 0, "Base URI 1 is not set");
		require(bytes(baseURI_2).length > 0, "Base URI 2 is not set");

		frozenMetadata = true;
	}

	function setPhase(uint8 _phase) public onlyOwner validPhase(_phase) {
		phase = _phase;
	}

	modifier validPhase(uint8 _phase) {
		require(_phase <= 2, "Phase must be 0, 1 or 2");
		_;
	}

	//SETTERS FOR SALE PHASE
	function setOnlyWhitelistedFF() public onlyOwner {
		onlyWhitelistedFF = true;
		onlyWhitelisted = false;
		onlyPublicSale = false;
	}

	function setOnlyWhitelisted() public onlyOwner {
		onlyWhitelistedFF = false;
		onlyWhitelisted = true;
		onlyPublicSale = false;
	}

	function setOnlyPublicSale() public onlyOwner {
		onlyWhitelistedFF = false;
		onlyWhitelisted = false;
		onlyPublicSale = true;
	}

	//SETTERS FOR COSTS
	function setCostWhitelistedFF(uint256 _newCostWhitelistedFF) public onlyOwner {
		costWhitelistedFF = _newCostWhitelistedFF;
	}

	function setCostWhitelisted(uint256 _newCostWhitelisted) public onlyOwner {
		costWhitelisted = _newCostWhitelisted;
	}

	function setCostPublicSale(uint256 _newCostPublicSale) public onlyOwner {
		costPublicSale = _newCostPublicSale;
	}

	//SETTERS FOR MAXMINTAMOUNT
	function setMaxMintAmountWhitelistFF(uint16 _newMaxMintAmountWhitelistFF) public onlyOwner {
		maxMintAmountWhitelistFF = _newMaxMintAmountWhitelistFF;
	}

	function setMaxMintAmountWhitelist(uint16 _newMaxMintAmountWhitelist) public onlyOwner {
		maxMintAmountWhitelist = _newMaxMintAmountWhitelist;
	}

	function setMaxMintAmount(uint16 _newMaxMintAmount) public onlyOwner {
		maxMintAmount = _newMaxMintAmount;
	}

	//SETTER FOR PHASE MAXSUPPLY
	function setPhaseMaxSupply(uint8 _phase, uint16 _newPhaseMaxSupply) public onlyOwner {
		if (_phase == 0) {
			phaseMaxSupply0 = _newPhaseMaxSupply;
		} else if (_phase == 1) {
			phaseMaxSupply1 = _newPhaseMaxSupply;
		}
	}

	//view phaseMaxSupply for current Phase
	function phaseMaxSupply() public view returns (uint16) {
		return phase == 0 ? phaseMaxSupply0 : (phase == 1 ? phaseMaxSupply0 + phaseMaxSupply1 : maxSupply);
	}

	//SET WHITELIST
	function setWhitelist(bytes32 _merkleRoot) external onlyOwner {
		merkleRoot = _merkleRoot;
	}

	//WITHDRAWALS
	function withdraw() public payable onlyOwner nonReentrant {
		// ================This will pay 6%====================================
		(bool phunsuccess, ) = payable(0xdeF952AF6722e6b8af66Ceac00e0Bc1E1B32a447).call{value: (address(this).balance * 6) / 100}("");
		require(phunsuccess);
		// ====================================================================

		// ================This will pay remaining 94%=========================
		(bool coldsuccess, ) = payable(0xa68e3E7861596646A8Dac4406D39677dEE099387).call{value: address(this).balance}("");
		require(coldsuccess);
		// ====================================================================

		// This will payout the OWNER the remainder of the contract balance if any left.
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
		// =====================================================================
	}
}