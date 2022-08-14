// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract degenduck is ERC721A, Ownable {
    uint256 public maxMintAmountPerTxn = 10;
    uint256 public maxSupply = 1555;
    uint256 public mintPrice = 0.003 ether;
    uint256 public freeSupply = 1300;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmaKQoPqMuZEdE5TCEMN9SEjXcTvF8YArKUpymbJuGL9pN/";
    mapping(address => uint) private _walletMintedCount;

    constructor() ERC721A("Degen Duck NFT", "DD") {}

    function mintTo(address to, uint256 count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Too much');
		_safeMint(to, count);
	}

      function mint(uint256 count) external payable {
      require(count <= maxMintAmountPerTxn, 'Too many amount');
      require(_totalMinted() + count <= maxSupply, 'Sold out');
      uint256 price = 0;
      if(_totalMinted() + count <= freeSupply && _walletMintedCount[msg.sender] + count <= maxMintAmountPerTxn) {
        price = 0;
      }
      else {
        price = mintPrice;
      }
        require(msg.value >= count * price, 'Not enough balance');
        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
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