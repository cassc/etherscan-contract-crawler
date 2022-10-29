// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract Beowulf is ERC721A, Ownable {

	uint public maxPerWallet = 1;

    uint public constant mintPrice = 0.01 ether;


	uint public maxSupply = 999;
	uint public wlSupply = 300;
	uint public publicSupply = 699;


    uint public mintedWLSupply = 0;
    uint public mintedPublicSupply = 0;


	bool public isSale = false;

    bool public isMetadataFinal;
    string private _baseURL;

    bytes32 public merkleRoot;

	mapping(address => uint) private _walletPublicMintedCount;
	mapping(address => uint) private _walletWLMintedCount;


	constructor() ERC721A('Beowulf', 'WULF') {}

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
    }

	function setMetadata(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Metadata is finalized");
		_baseURL = url;
	}

    function mintedPublicCount(address owner) external view returns (uint) {
        return _walletPublicMintedCount[owner];
    }

     function mintedWLCount(address owner) external view returns (uint) {
        return _walletWLMintedCount[owner];
    }

	function setSale(bool value) external onlyOwner {
		isSale = value;
	}
 

	function withdraw() external onlyOwner {
   		uint balance = address(this).balance;
		require(balance > 0, 'No balance');
        payable(owner()).transfer(balance);
	}


	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'WULF: Exceeds max supply'
		);
		_safeMint(to, count);
	}

	

	function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId + 1), ".json"))
            : '';
	}

   	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

	function publicMint(uint256 quantity) external payable {
   
   
        require(isSale, "Sale not live");
        require(quantity > 0, "Quantity of tokens must be bigger than 0");
        require(quantity <= maxPerWallet, "Quantity of tokens must be 1");
        require(mintedPublicSupply + quantity <= publicSupply, "Quantity exceeds max supply of tokens");
        require(_walletPublicMintedCount[msg.sender] + quantity == 1, "You have already minted.");

        require(msg.value >= mintPrice * quantity, "Insufficient ether value");

        mintedPublicSupply += quantity;
        _walletPublicMintedCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    
    
    }

    function wlMint(uint256 quantity, bytes32[] memory _merkleProof) external payable {

        require(isSale, "Sale not live");
        require(quantity > 0, "Quantity of tokens must be bigger than 0");
        require(quantity <= maxPerWallet, "Quantity of tokens must be 1");
        require(mintedWLSupply + quantity <= wlSupply, "Quantity exceeds max supply of tokens");
        require(_walletWLMintedCount[msg.sender] + quantity == 1, "You have already minted.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");
        require(msg.value >= mintPrice * quantity, "Insufficient ether value");

        mintedWLSupply += quantity;
        _walletWLMintedCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);

    }
    
    
    
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId, false);
    }

}