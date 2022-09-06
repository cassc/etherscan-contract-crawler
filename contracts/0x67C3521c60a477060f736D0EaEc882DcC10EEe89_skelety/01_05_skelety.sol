// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract skelety is ERC721A, Ownable {
    uint256 public maxMintAmountPerTxn = 5;
    uint256 public maxPerWallet = 5;
    uint256 public maxSupply = 1000;
    uint256 public mintPrice = 0.002 ether;
    bool public reveal = false;
    uint256 public freeSupply = 700;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmSHfk4Vj5a9FgxAR1hvmAkFH4GUYQPcJztVhcjX6A5g1w";
    mapping(address => uint) private _walletMintedCount;

    constructor() ERC721A("Skelety", "SKY") {}

    function airDrop(address to, uint256 count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Too much');
		_safeMint(to, count);
	}
      function publicMint(uint256 count) external payable {
      require(count <= maxMintAmountPerTxn, 'Too many amount');
      require(_totalMinted() + count <= maxSupply, 'Sold out');
      uint256 price = 0;
      if(_totalMinted() + count <= freeSupply && _walletMintedCount[msg.sender] + count <= maxPerWallet) {
        price = 0;
      }
      else {
        price = mintPrice;
      }
        require(msg.value >= count * price, 'Not enough balance');
        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
	}

    function setReveal(bool _reveal) public onlyOwner {
        reveal = _reveal;
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

    function setMaxWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }
}