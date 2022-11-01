//SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HarryPotter is ERC721A, Ownable {
  uint256 public extraPrice = 0.0003 ether;
  uint256 public freeSupply = 5000;
  uint256 public maxSupply = 10000;
  uint256 public maxPerTx = 12;

  string public uriPrefix = "ipfs://bafybeif2bwymvgthzqji4oip3qajqawuhi26axw2fymesmp3tnmcvkj324/";
  string public uriSuffix = ".json";
  bool public paused = false;
  mapping(address => uint256) freeMinted;
  uint256 MAX_FREE_PER_WALLET = 1;

  constructor() ERC721A("Harry Potter and the NFTs", "HPNFT") {}

  function mint(uint256 _quantity) external payable {
    require(!paused, "Minting paused");
    uint256 _totalSupply = totalSupply();
    require(msg.sender == tx.origin, "The caller is another contract!");
    require(_totalSupply + _quantity <= maxSupply, "Exceeds supply!");
    require(_quantity > 0 && _quantity <= maxPerTx, "Invalid mint amount!");
    uint256 cost;
    if (_totalSupply >= freeSupply) {
      if (freeMinted[msg.sender] < MAX_FREE_PER_WALLET) {
          uint remains = MAX_FREE_PER_WALLET - freeMinted[msg.sender];
          if (remains <= _quantity) {
              freeMinted[msg.sender] += remains;
              cost = extraPrice * (_quantity - remains);              
          } else {
              freeMinted[msg.sender] += _quantity;
              cost = 0;
          }
      } else {
          cost = extraPrice * _quantity;
      }
    }
    require(msg.value >= cost, "ETH sent not correct");
    _mint(msg.sender, _quantity);
  }

  function setMaxFreePerWallet(uint256 _maxFreePerWallet) external onlyOwner {
    MAX_FREE_PER_WALLET = _maxFreePerWallet;
  }

  function setPrice(uint256 price) external onlyOwner {
    extraPrice = price;
  }

  function setFreeSupply(uint256 _freeSupply) external onlyOwner {
    freeSupply = _freeSupply;
  }

  function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
    maxPerTx = _maxPerTx;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return uriPrefix;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    uriPrefix = _newBaseUri;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)) : '';
    }

  function setPause() external onlyOwner {
    paused = !paused;
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }
}