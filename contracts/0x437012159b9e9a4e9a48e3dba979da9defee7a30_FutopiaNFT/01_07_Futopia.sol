// SPDX-License-Identifier: MIT

/*
  _____      _              _       
 |  ___|   _| |_ ___  _ __ (_) __ _ 
 | |_ | | | | __/ _ \| '_ \| |/ _` |
 |  _|| |_| | || (_) | |_) | | (_| |
 |_|   \__,_|\__\___/| .__/|_|\__,_|
                     |_|            

*/
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FutopiaNFT is ERC721A, Ownable {
    using Strings for uint256;

	uint256 public constant MaxNftsCreated = 4444;

	string public MetaUri;
	string public EndUri; 

	uint256 public PriceToPayForWl;
	uint256 public PriceToPayForPub;

	uint256 public MintTimeForWL;
	uint256 public MintTimeForPUB;

	uint256 public MaxNftCreationsPerWlUser;
	uint256 public MaxNftCreationsPerPublicUser;

	bool public STOP; 
	
	mapping(address => uint256) public madeNFTsinWl;
	mapping(address => uint256) public madeNFTsinPub;

	bytes32 public MerkleThingy;

	constructor() ERC721A("Futopia", "FT") {
		MetaUri = "ipfs://QmepL5uZsMhhf1wThEKTT2zAgMgAvwfxxUox9opK4RRQ4F/";
		EndUri = ".json";

		PriceToPayForWl = 0.0069 ether;
		PriceToPayForPub = 0.0089 ether;
		
		MaxNftCreationsPerWlUser = 2;
		MaxNftCreationsPerPublicUser = 3;

		MintTimeForWL = 1664481600;
		MintTimeForPUB = 1664568000;

		STOP = true;
		MerkleThingy = 0x33af86fccee6a1479d4b218c714291491812719ee42ff6b718fc72157418a250;
		_safeMint(msg.sender, 44);
	}
	
	modifier CheckCheckDoubleCheck { 
		require(!STOP, "contract is stopped, what are you doing???");
		require(msg.sender == tx.origin, "why be like that, no contracts dude, no contracts.");
		_;
	}

	function makeNftGoAway(uint256 tokenId) external CheckCheckDoubleCheck {
		require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
		require(ownerOf(tokenId) == msg.sender, "you cannot make someone elses nft go away!!! Not cool man");
		_burn(tokenId);
	}

	function PublicMint(uint256 _amount) external payable CheckCheckDoubleCheck {
		require(block.timestamp >= MintTimeForPUB, "it's not time yet to shine...");
		require(madeNFTsinPub[msg.sender] + _amount <= MaxNftCreationsPerPublicUser, "you cannot mint that much man");
		require(totalSupply() + _amount <= MaxNftsCreated, "that's too much-- we only have 4444 nfts dude");
		require(msg.value == PriceToPayForPub * _amount, "you are underpaying, we don't like that here!!!");
		_safeMint(msg.sender, _amount);
		madeNFTsinPub[msg.sender] += _amount; 
	}

	function WhitelistMint(uint256 _amount, bytes32[] calldata _proof) external payable CheckCheckDoubleCheck {
		require(block.timestamp >= MintTimeForWL, "it's not time yet to shine...");
        require(msg.value == PriceToPayForWl * _amount, "no man that's not gonna cut it, that amount is wrong!");
        require(madeNFTsinWl[msg.sender] + _amount <= MaxNftCreationsPerWlUser, "nonono thats not happening you are above your quota ");
        require(totalSupply() + _amount <= MaxNftsCreated, "that's too much-- we only have 4444 nfts dude");
        require(MerkleProof.verify(_proof, MerkleThingy, keccak256(abi.encodePacked(msg.sender))), "you dont have wl bro what are you doing");
        madeNFTsinWl[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

	function DropNFTsInSomeoneElsesBasket(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
       	for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }
	
	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
	
	function setMetas(string memory _MetaUri, string memory _EndUri) external onlyOwner {
		MetaUri = _MetaUri;
		EndUri = _EndUri;
	}

	function setPriceToPay(uint256 _PriceToPayForWl, uint256 _PriceToPayForPub) external onlyOwner {
		PriceToPayForWl = _PriceToPayForWl;
		PriceToPayForPub = _PriceToPayForPub;
	}

	function setMaxMints(uint256 _MaxNftCreationsPerWlUser, uint256  _MaxNftCreationsPerPublicUser) external onlyOwner {
		MaxNftCreationsPerWlUser = _MaxNftCreationsPerWlUser;
		MaxNftCreationsPerPublicUser = _MaxNftCreationsPerPublicUser;
	}

	function setSTOP(bool _STOP) external onlyOwner {
		STOP = _STOP;
	}

	function setMerkleThingy(bytes32 _merkleThingy) external onlyOwner {
		MerkleThingy = _merkleThingy;
	}

	function setMintTimings(uint256 _MintTimeForWL, uint256 _MintTimeForPUB) external onlyOwner {
		MintTimeForWL = _MintTimeForWL;
		MintTimeForPUB = _MintTimeForPUB;
	}
    
	function withdrawal() external onlyOwner {
        (bool os, ) = payable(owner()).call {
            value: address(this).balance
        } ("");
        require(os);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(MetaUri).length > 0
                ? string(abi.encodePacked(MetaUri, _tokenId.toString(), EndUri))
                : "";
    }
}