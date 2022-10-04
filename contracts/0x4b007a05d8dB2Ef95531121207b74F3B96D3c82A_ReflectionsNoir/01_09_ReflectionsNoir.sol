// SPDX-License-Identifier: MIT
// Reflections Noir by Rich Simmons - Testnet
// Created by Robert McMenemy & Steven Isaac Founders of blockgeni3.com

pragma solidity ^0.8.11;

import "contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ReflectionsNoir is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
    using MerkleProof for bytes32[];
	
	uint256 public constant maxSupply = 999;
    uint256 public constant maxPerWallet = 3;

	string public baseURI;
	string private notRevealedURI;
    bytes32 private presaleMerkleRoot;

	uint256 public cost = 0.08 ether;
    bool public publicMintStarted = false;
    bool public privateMintStarted = false;
	bool private revealedState = false;

    address public BGAddress = payable(0x26bD46e3804DA5e0801C6c9AFB39F05696f1E943);
    address public RSAddress = payable(0x5039CDa148fDd50818D5Eb8dBfd8bE0c0Bd1B082);
    
    constructor(string memory _initBaseURI, string memory _initNotRevealedURI, bytes32 _root) ERC721A("Reflections Noir", "RNR") {
        setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedURI);
        presaleMerkleRoot = _root;
    }

    // ===== Check Caller Is User =====
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ===== Check Mint Compliance =====
    modifier whenMint(uint8 quantity) {
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");
        require(balanceOf(msg.sender) <= maxPerWallet, "[Max Per Wallet Error] You have max minte the amount for this wallet");

        if(privateMintStarted) {
            require(privateMintStarted, "[Mint Status Error] Private mint not active.");
        } else {
            require(publicMintStarted, "[Mint Status Error] Public mint not active.");
        }

        if(balanceOf(msg.sender) < 1 && privateMintStarted) {
            if(quantity != 1) {
                require(msg.value >= (cost * (quantity - 1)), "[Value Error] Not enough funds supplied for mint"); 
            } else {
                require(msg.value == 0, "[Value Error] First mint is free"); 
            }
        } else {
            require(msg.value >= (cost * quantity), "[Value Error] Not enough funds supplied for mint"); 
        }

        sendFunds(msg.value);
        _;
    }

    // ===== Stop Mint =====
    function stopMint() external onlyOwner {
        publicMintStarted = false;
        privateMintStarted = false;
    }

    // ===== Turn on public mint =====
    function turnOnPublicMint() external onlyOwner {
        publicMintStarted = true;
        privateMintStarted = false;
    }

    // ===== Turn on private mint =====
    function turnOnPrivateMint() external onlyOwner {
        publicMintStarted = false;
        privateMintStarted = true;
    }

    // ===== Toggle Revealed State =====
    function toggleReveal() external onlyOwner {
        revealedState = !revealedState;
    }

    // ===== Update Merkle Root =====
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        presaleMerkleRoot = _root;
    }
    
    // ===== Change Mint Price =====
    function setMintPrice(uint256 value) external onlyOwner {
        cost = value;
    }
    
    // ===== Change Base URI ===== 
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // ===== Change Not Revealed URI ===== 
    function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }
    
    // ===== Change Not Revealed URI ===== 
	function withdraw() external onlyOwner nonReentrant {
		sendFunds(address(this).balance);
	}
    
    // ===== Dev Mint =====
    function devMint(uint8 quantity) external onlyOwner {
        require(totalSupply() + quantity < maxSupply, "[Supply Error] Not enough left for this mint amount");
        _mint(msg.sender, quantity);        
    }

    // ===== Private Mint =====
    function privateMint(bytes32[] memory proof, uint8 quantity) external payable nonReentrant whenMint(quantity) {
        require(isAddressWhitelisted(proof, msg.sender), "[Whitelist Error] You are not on the whitelist");
        _mint(msg.sender, quantity);    
    }
    
    // ===== Mint =====
    function mint(uint8 quantity) external payable nonReentrant whenMint(quantity) {
        _mint(msg.sender, quantity);  
    }
    
    // ===== Is Whitelisted =====
    function isAddressWhitelisted(bytes32[] memory proof, address _address) internal view returns (bool) {
        return proof.verify(presaleMerkleRoot, keccak256(abi.encodePacked(_address)));
    }

    // ===== Set Start Token ID =====
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

    // ===== Set Base URI =====
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ===== Set Token URI =====
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory currentUri = (revealedState == true) ? baseURI : notRevealedURI;
        return bytes(currentUri).length > 0 ? string(abi.encodePacked(currentUri, tokenId.toString(), ".json")) : "";
	}
    
    // ===== Split Funds =====
	function sendFunds(uint256 _totalMsgValue) public payable {
		(bool s1,) = payable(BGAddress).call{value: (_totalMsgValue * 10) / 100}("");
		(bool s2,) = payable(RSAddress).call{value: (_totalMsgValue * 90) / 100}("");
		require(s1 && s2, "Transfer failed.");
	}

    // ===== Fallbacks =====
	receive() external payable {
		sendFunds(address(this).balance);
	}

	fallback() external payable {
		sendFunds(address(this).balance);
	}
}