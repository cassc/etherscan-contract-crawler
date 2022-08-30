//SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract St4rW4rs is ERC721A, Ownable {
  uint256 public extraPrice = 0.004 ether;
  uint256 public freeSupply = 1000;
  uint256 public maxSupply = 10000;
  uint256 public maxPerTx = 12;

  string public uriPrefix = "ipfs://bafybeid6b6gufopq2nko5fkukrih6jw346gffs6cpmmorj23db347zzpdu/";
  string public uriSuffix = ".json";
  bool public paused = true;
  mapping(address => bool) freeMinted;

  constructor() ERC721A("St4rW4rs", "S4W4") {}

  function mint(uint256 _quantity) external payable {
    require(!paused, "Minting paused");
    uint256 _totalSupply = totalSupply();
    require(msg.sender == tx.origin, "The caller is another contract!");
    require(_totalSupply + _quantity <= maxSupply, "Exceeds supply!");
    require(_quantity > 0 && _quantity <= maxPerTx, "Invalid mint amount!");
    uint256 cost;
    if (_totalSupply > freeSupply) {
      if (freeMinted[msg.sender]) {
          cost = extraPrice * _quantity;
      } else {
          cost = extraPrice * (_quantity - 1);
          freeMinted[msg.sender] = true;
      }
    }
    require(msg.value >= cost, "ETH sent not correct");
    _mint(msg.sender, _quantity);
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