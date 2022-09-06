// SPDX-License-Identifier: MIT
// Created by [email protected]


pragma solidity ^0.8.11;

import "contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Reflectionshch is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
    using MerkleProof for bytes32[];
	
	uint256 public constant maxSupply = 333;

    bool public publicMintStarted = false;
    bool public privateMintStarted = true;
	bool private revealedState = false;

	string public baseURI;
	string private notRevealedURI;
    bytes32 private presaleMerkleRoot;

	string public baseExtension = ".json";
	uint256 public mintCount = 0;
	uint256 public cost = 0.2 ether;

    address public BGAddress = payable(0x26bD46e3804DA5e0801C6c9AFB39F05696f1E943);
    address public RSAddress = payable(0x5039CDa148fDd50818D5Eb8dBfd8bE0c0Bd1B082);
    address public HCAddress = payable(0x9A2288188Dd47b8b42f2f0957d1C405D3BF59444);
    address public DPAddress = payable(0xB3c1D528E5eaDd83AD6f76885a354d1B589F3E3E);
    
    mapping(address => uint) private userMintCount;
    
    constructor(string memory _initBaseURI, string memory _initNotRevealedURI, bytes32 _root) ERC721A("Reflections at the Headcrash Hotel", "RHH") {
        setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedURI);
        presaleMerkleRoot = _root;
    }


    // ===== Modifiers =====
    modifier whenPrivateMint() {
        require(privateMintStarted, "[Mint Status Error] Private mint not active.");
        _;
    }

    modifier whenPublicMint() {
        require(publicMintStarted, "[Mint Status Error] Public mint not active.");
        _;
    }
    
    function devMint(uint8 quantity) external onlyOwner {
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");

        _mint(msg.sender, quantity);        
    }

    // ===== Private mint =====
    function privateMint(bytes32[] memory proof, uint8 quantity) external payable nonReentrant whenPrivateMint {
        require(msg.value >= cost * quantity, "[Value Error] Not enough funds supplied for mint");
        require(isAddressWhitelisted(proof, msg.sender), "[Whitelist Error] You are not on the whitelist");
        require(userMintCount[msg.sender] <= 3, "[Max Per Wallet Error] You can only own 3 per wallett."); 

        _mint(msg.sender, quantity);     

        mintCount += quantity;   
        userMintCount[msg.sender]++; 

        sendFunds(msg.value);
    }
    
    function mint(uint8 quantity) external payable nonReentrant whenPublicMint {
        require(msg.value >= cost * quantity, "[Value Error] Not enough funds supplied for mint");
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");
        require(userMintCount[msg.sender] <= 3, "[Max Per Wallet Error] You can only own 3 per wallett."); 

        _mint(msg.sender, quantity);     

        mintCount += quantity;   
        userMintCount[msg.sender]++;   

        sendFunds(msg.value);
    }
    
    function isAddressWhitelisted(bytes32[] memory proof, address _address) internal view returns (bool) {
        return proof.verify(presaleMerkleRoot, keccak256(abi.encodePacked(_address)));
    }

	// override _startTokenId() function ~ line 100 of ERC721A
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	// override _baseURI() function  ~ line 240 of ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

	// override tokenURI() function ~ line 228 of ERC721A
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		if (revealedState == true) {
			return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
		} else {
			return bytes(notRevealedURI).length > 0 ? string(abi.encodePacked(notRevealedURI, tokenId.toString(), baseExtension)) : "";
		}
	}

	// ---Helper Functions / Modifiers---
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
	function sendFunds(uint256 _totalMsgValue) public payable {
		(bool s1,) = payable(BGAddress).call{value: (_totalMsgValue * 5) / 100}("");
		(bool s2,) = payable(RSAddress).call{value: (_totalMsgValue * 50) / 100}("");
        (bool s3,) = payable(HCAddress).call{value: (_totalMsgValue * 30) / 100}("");
        (bool s4,) = payable(DPAddress).call{value: (_totalMsgValue * 15) / 100}("");
		require(s1 && s2 && s3 && s4, "Transfer failed.");
	}

    function stopPublicMint() external onlyOwner {
        publicMintStarted = false;
        privateMintStarted = true;
    }

    function startPublicMint() external onlyOwner {
        publicMintStarted = true;
        privateMintStarted = false;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        presaleMerkleRoot = _root;
    }

    function setRevealed(bool _revealedState) external onlyOwner {
        revealedState = _revealedState;
    }

    function setMintPrice(uint256 value) external onlyOwner {
        cost = value;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }
    
	function withdraw() external onlyOwner nonReentrant {
		sendFunds(address(this).balance);
	}
    
	receive() external payable {
		sendFunds(address(this).balance);
	}

	fallback() external payable {
		sendFunds(address(this).balance);
	}

}