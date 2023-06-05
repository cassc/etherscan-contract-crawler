// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract ThugCity is ERC721A, Ownable {

	uint public constant MINT_THREE_PRICE = 0.02 ether;
	uint public constant MINT_FIVE_PRICE = 0.035 ether;
	uint public maxSupply = 5000;

	bool public isPublicSale = false;
	bool public isWhitelistSale = false;

    bool public isMetadataFinal;
    string private _baseURL;

    bytes32 public merkleRoot;

	mapping(address => uint) private _walletMintedCount;


	constructor() ERC721A('Thug City', 'XXX') {}

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}



	function allCaptured(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Metadata is finalized");
		_baseURL = url;
	}

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function releaseAllPrisoners(bool value) external onlyOwner {
		isPublicSale = value;
	}

	function releasePrisoners(bool value) external onlyOwner {
		isWhitelistSale = value;
	}



	function withdraw() external onlyOwner {
   		uint balance = address(this).balance;
		require(balance > 0, 'No balance');
        payable(owner()).transfer(balance);
	}



	function callForHelp(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'Thug City: Exceeds max supply'
		);
		_safeMint(to, count);
	}

	function reduceSupply(uint newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
	}

	function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"))
            : '';
	}

   	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }



	function prisonEscapeLive(uint256 quantity, bytes32[] memory _merkleProof) external payable {

        require(isWhitelistSale, "WL sale is not open");
        require(quantity > 0, "Quantity of tokens must be bigger than 0");
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max supply of tokens");
        require(_walletMintedCount[msg.sender] == 0, "You have already minted.");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");
        
        if (quantity == 1)
        {
            require(msg.value >= 0, "Insufficient ether value");
        }
        else if (quantity == 3)
        {
            require(msg.value >= MINT_THREE_PRICE, "Insufficient ether value");

        }
        else if (quantity == 5)
        {
            require(msg.value >= MINT_FIVE_PRICE, "Insufficient ether value");
        }
        else{
            require(false, "You can only make 1, 3, or 5.");
        }

        _walletMintedCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);

    }
    
    
    function arrested(uint256 tokenId) public onlyOwner {
        _burn(tokenId, false);
    }

	function remainingPrisoners(uint256 quantity) external payable {

        require(isPublicSale, "Public sale is not open");
     	require(quantity > 0, "Quantity of tokens must be bigger than 0");
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max supply of tokens");
        require(_walletMintedCount[msg.sender] == 0, "You have already minted.");
           
      	if (quantity == 1)
        {
            require(msg.value >= 0, "Insufficient ether value");
        }
        else if (quantity == 3)
        {
            require(msg.value >= MINT_THREE_PRICE, "Insufficient ether value");

        }
        else if (quantity == 5)
        {
            require(msg.value >= MINT_FIVE_PRICE, "Insufficient ether value");
        }
        else{
            require(false, "You can only make 1, 3, or 5.");
        }

        _walletMintedCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);

    }



}