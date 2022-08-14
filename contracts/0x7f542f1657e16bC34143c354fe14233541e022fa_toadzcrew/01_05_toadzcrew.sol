// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract toadzcrew is ERC721A, Ownable {
    uint256 public maxMintAmountPerTxn = 10;
    uint256 public maxSupply = 3333;
    uint256 public mintPrice = 0.003 ether;
    string public baseURI = "";
    mapping(address => uint) private _walletMintedCount;

    constructor() ERC721A("Toadz Crew", "TZC") {}

    function mintTo(address to, uint256 count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Too much');
		_safeMint(to, count);
	}

    function mint(uint256 count) external payable {
      require(count <= maxMintAmountPerTxn, 'Exceeds NFT per transaction limit');
      require(_totalMinted() + count <= maxSupply, 'Exceeds max supply');
      uint256 payForCount = count;
      uint256 mintedSoFar = _walletMintedCount[msg.sender];
      if(mintedSoFar < 1) {
        uint256 remainingFreeMints = 1 - mintedSoFar;
        if(count > remainingFreeMints) {
            payForCount = count - remainingFreeMints;
        }
        else {
            payForCount = 0;
        }
      }

      require(msg.value >= payForCount * mintPrice, 'Ether value sent is not sufficient');

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}

    function mintedCount(address owner) external view returns (uint256) {
        return _walletMintedCount[owner];
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintAmountPerTxn(uint256 _maxMintAmountPerTxn) public onlyOwner {
        maxMintAmountPerTxn = _maxMintAmountPerTxn;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }
}