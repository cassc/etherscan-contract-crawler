// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TrufflePass is ERC721, IERC2981, Ownable{	
	 using ECDSA for bytes32;

	string private blindUri;
	string private baseUri;	
	uint256 private nextTokenId=1;
	uint256 private minSupply=1;	
	uint256 private limitWallet=2;	
	bytes32 public merkleroot=bytes32(0);
	
	uint256 public aliveTime = 2524608000;	                            
	uint256 public royalty = 0;
	uint256 public price = 0.2 ether;
	uint256 public maxSupply=333;		
	bool public revealed = false;   

	mapping(uint256 => string) private tokenURIs;
	mapping(address => uint) private walletMinted;

	constructor(string memory name_, string memory symbol_, string memory blindUri_) ERC721(name_, symbol_) {	
		blindUri = blindUri_;
	}	
	function alive() external view returns (bool) {
        return block.timestamp>=aliveTime;
    }
	function whiteMint() external view returns (bool) {
        return merkleroot!=bytes32(0);
    }
	function totalSupply() external view returns (uint256) {
        return (nextTokenId - 1);
    }
	function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleroot = root;
    }
	function setAliveTime(uint256 epochtime) external onlyOwner {
		aliveTime = epochtime;
	}	
	function setPrice(uint256 weis) external onlyOwner {
		price = weis;
	}
	function setRoyalty(uint256 percent) external onlyOwner {
		royalty = percent;
	}
	function setWalletLimit(uint256 limit) external onlyOwner {
		limitWallet = limit;
	}
	function reveal() external onlyOwner {
		 revealed = true;
	}	
	function setBlindTokenUri(string memory uri) external onlyOwner {
		blindUri = uri;
	}
	function setBaseTokenUri(string memory uri) external onlyOwner {        
		baseUri = uri;
	}
	function setTokenURI(uint256 tokenId, string memory _tokenURI) external virtual onlyOwner {
		require(_exists(tokenId), "nonexistent token");
		
		tokenURIs[tokenId] = _tokenURI;
	}
	function mint(bytes32[] memory proof) external payable {
		require(block.timestamp>=aliveTime, "not alive");
		require(nextTokenId <= maxSupply, "all minted");			    
		require(msg.value >= price, "no enough ether");	  	
		require(balanceOf(msg.sender) < limitWallet, "out of limit");		
		require(walletMinted[msg.sender]<limitWallet, "out of limit");		
 		require(merkleroot==0 || (proof.length>0 && MerkleProof.verify(proof,merkleroot,keccak256(abi.encodePacked(msg.sender)))),  "not on whitelist");

      	_safeMint(msg.sender, nextTokenId);
		nextTokenId += 1;

		walletMinted[msg.sender] = walletMinted[msg.sender] + 1;
	}	
	function burn(uint256 tokenId)  external  {		
		require(_exists(tokenId), 'nonexistent token');
    	require(_isApprovedOrOwner(msg.sender, tokenId));

    	_burn(tokenId);
		if(tokenId == nextTokenId-1){
			nextTokenId-=1;
		}
  	}
	function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
		require(balance > 0, "nothing to withdraw");

        (bool os, ) = payable(owner()).call{value: balance}("");
		require(os, "nothing to withdraw");
	}
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");

		if (revealed || tokenId<minSupply){
			string memory tokenUri = tokenURIs[tokenId];
			if(bytes(baseUri).length == 0 && bytes(tokenUri).length == 0)
				return blindUri;
			if(bytes(tokenUri).length == 0)				
				tokenUri =string(abi.encodePacked(Strings.toString(tokenId), ".json"));
			return string(abi.encodePacked(baseUri, tokenUri));
		}
		else
			return blindUri;
	}	
	function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
		require(_exists(tokenId), "Nonexistent token");
		
		return (address(this), SafeMath.div(SafeMath.mul(salePrice, royalty), 100));
	}
}