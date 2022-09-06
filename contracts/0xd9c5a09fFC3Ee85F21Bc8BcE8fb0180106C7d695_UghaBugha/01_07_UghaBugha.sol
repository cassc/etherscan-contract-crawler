// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract UghaBugha is ERC721A, Ownable {

	uint public constant MINT_PRICE = 0.0099 ether;

    uint public publicSupply = 3800;
    uint public wlSupply = 1200;
    uint public maxSupply = publicSupply + wlSupply;


	bool public isPublicSale = false;
	bool public isWhitelistSale = false;

    bool public isMetadataFinal;
    string private _baseURL;

    bytes32 public merkleRoot;

	mapping(address => uint) private _publicWalletMintedCount;
	mapping(address => uint) private _wlWalletMintedCount;

	constructor() ERC721A('UghaBugha', 'UB') {}



    /* Owner functions */



	function withdraw() external onlyOwner { // withdraws all ether balance to owner
   		uint balance = address(this).balance;
		require(balance > 0, 'No balance');
        payable(owner()).transfer(balance);
	}

	function allCaptured(string memory url) external onlyOwner { // sets the baseURI (input metadata CID in ipfs://{cid}/ format)
        require(!isMetadataFinal, "Metadata is finalized");
		_baseURL = url;
	}
   
	function setUghalist(bool value) external onlyOwner { // activates/deactivates the Ughalist mint (1000 supply)
		isWhitelistSale = value;
	}

    function setBugha(bool value) external onlyOwner { // activates/deactivates the Public mint (4000 supply)
		isPublicSale = value;
	}

    function airdrop(address to, uint count) external onlyOwner { // airdrops token or tokens to address (address as argument) 
        require(
            _totalMinted() + count <= maxSupply,
            'Ugha Bugha: Exceeds max supply'
        );
        _safeMint(to, count);
    }

    function changeUghalistSupply(uint newMaxSupply) external onlyOwner { // changes the Ughalist supply 
		wlSupply = newMaxSupply;
	}

    function changeBughaSupply(uint newMaxSupply) external onlyOwner { // changes the public supply 
		publicSupply = newMaxSupply;
	}

   	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{ // sets the Merkle root (used for proof of Ughalist)
        merkleRoot = _merkleRoot;
    }

     function burn(uint256 tokenId) public onlyOwner { // burns a token
        _burn(tokenId, false);
    }



    /* Public functions */



	function _baseURI() internal view override returns (string memory) { // returns the baseURI (metadata CID)
		return _baseURL;
	}

    function addressMintedCount(address owner) external view returns (uint) { // returns the number of tokens minted for a user
        return (_wlWalletMintedCount[owner] + _publicWalletMintedCount[owner]);
    }



	function tokenURI(uint tokenId) public view override returns (string memory) { // returns the tokenURI (in ipfs://{cid}/{tokenId}.json format)
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"))
            : '';
	}

	function ughalistBirth(uint256 quantity, bytes32[] memory _merkleProof) external payable { // mints Ughalist tokens
        require(isWhitelistSale, "WL sale is not open");
        require(quantity > 0, "Quantity of tokens must be bigger than 0");
        require(quantity < 3, "Quantity of tokens must be 1 or 2");
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max Ughalist supply of tokens");
        require(_wlWalletMintedCount[msg.sender] == 0, "You have already minted.");
        require(msg.value >= quantity * MINT_PRICE, "Insufficient ether value");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");


        _wlWalletMintedCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);

    }

	function bughaBirth(uint256 quantity) external payable { // mints public tokens
        require(isPublicSale, "Public sale is not open");
        require(quantity > 0, "Quantity of tokens must be bigger than 0");
        require(quantity < 3, "Quantity of tokens must be 1 or 2");
        require(totalSupply() + quantity <= publicSupply, "Quantity exceeds max public supply of tokens");
        require(_publicWalletMintedCount[msg.sender] == 0, "You have already minted.");
        require(msg.value >= quantity * MINT_PRICE, "Insufficient ether value");


        _publicWalletMintedCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);

    }


}