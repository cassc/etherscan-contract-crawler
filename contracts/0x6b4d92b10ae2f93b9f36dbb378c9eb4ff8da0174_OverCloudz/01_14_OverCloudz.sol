// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OverCloudz is ERC721Enumerable, Ownable {
	using Strings for uint256;
    using ECDSA for bytes32;
	
	uint256 public constant OVCD_GIFT = 77;
	uint256 public constant OVCD_PUBLIC = 7700;
	uint256 public constant OVCD_MAX = OVCD_GIFT + OVCD_PUBLIC;
	uint256 public constant OVCD_PRICE = 0.07 ether;
	uint256 public constant PURCHASE_LIMIT = 5;
	
	uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;
    
	bool public isPresale;
	bool public isPublic;
    bool public locked;
	
	string public proof;
	string private _contractURI;
    string private _tokenBaseURI;
    
    address private _partnerAddress = 0xA49fe1C6369015020999A5bEAf464b18e6BB6c18;
	address private _signerAddress;
	mapping(string => bool) private _usedNonces;
	mapping(address => uint256) public presalerListPurchases;
	
	constructor(string memory bURI, string memory cURI, address sAddress) ERC721("OverCloudz", "OVCD") {
	    _tokenBaseURI = bURI;
	    _contractURI = cURI;
	    _signerAddress = sAddress;
	}
	
	modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
	
	function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
		bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(sender, qty, nonce))));

		return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    
    function matchNonces(string memory nonce) public view returns(bool) {
        return _usedNonces[nonce];
    }
    
    function mintGift() external onlyOwner {
        require(totalGiftSupply < OVCD_GIFT, "All gifts have been minted");
		
		for (uint256 i = 0; i < OVCD_GIFT; i++) {
			uint256 tokenId = totalSupply() + 1;
			
            totalGiftSupply++;
            _safeMint(owner(), tokenId);
        }
    }
	
	function purchaseWhitelist(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity, uint256 hashQuantity) external payable {
        require(isPresale, "Presale is not active");
        require(matchAddresSigner(hash, signature), "No direct mint");
        
        require(hashTransaction(msg.sender, hashQuantity, nonce) == hash, "Unable to verify hash");
        require(tokenQuantity <= hashQuantity, "Unable to mint more than determined number");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= hashQuantity, "Purchase would exceed presale limit");
        
        require(totalSupply() < OVCD_MAX, "All tokens have been minted");
        require(totalPublicSupply + tokenQuantity <= OVCD_PUBLIC, "Purchase would exceed public limit");
        require(tokenQuantity <= PURCHASE_LIMIT, "Purchase would exceed purchase limit");
        require(OVCD_PRICE * tokenQuantity <= msg.value, "Insufficient ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            
            presalerListPurchases[msg.sender]++;
            totalPublicSupply++;
            _safeMint(msg.sender, tokenId);
        }
        
        _usedNonces[nonce] = true;
    }
	
	function purchase(uint256 tokenQuantity) external payable {
        require(isPublic, "Public sale is not active");
        require(totalSupply() < OVCD_MAX, "All tokens have been minted");
        require(totalPublicSupply + tokenQuantity <= OVCD_PUBLIC, "Purchase would exceed public limit");
        require(tokenQuantity <= PURCHASE_LIMIT, "Purchase would exceed purchase limit");
        require(OVCD_PRICE * tokenQuantity <= msg.value, "Insufficient ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
			uint256 tokenId = totalSupply() + 1;
			
            totalPublicSupply++;
            _safeMint(msg.sender, tokenId);
        }
    }
	
	function withdraw() external onlyOwner {
	    payable(_partnerAddress).transfer(address(this).balance * 10 / 125);
        payable(msg.sender).transfer(address(this).balance);
    }
	
	function setIsPresale() external onlyOwner {
		isPresale = !isPresale;
	}
	
	function setIsPublic() external onlyOwner {
		isPublic = !isPublic;
	}
	
	function lockMetadata() external onlyOwner {
        locked = true;
    }
	
	function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
	
	function setProof(string calldata proofString) external onlyOwner notLocked {
        proof = proofString;
    }
	
	function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }
	
	function contractURI() public view returns (string memory) {
        return _contractURI;
    }
	
	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}