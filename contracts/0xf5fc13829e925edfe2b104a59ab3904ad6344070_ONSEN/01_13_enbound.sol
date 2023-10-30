// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract ONSEN is ERC721, Ownable {
  using Strings for uint256;

  // Royarlty
  bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;
  uint256 public secondarySaleRoyaltyRatio = 1000; // 10.0%
  uint256 public ratioCalculateNum = 10000;
  address public royaltyReceiver;

  // URI
  string public baseURI;
  string public extension = '.json';

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initialBaseURI,
    address _royaltyReciver
  ) ERC721(_name, _symbol) {
    setBaseURI(_initialBaseURI);
    setRoyaltyReceiver(_royaltyReciver);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function bulkmint(
    address _to,
    uint256 _startIndex,
    uint256 _num
  ) public onlyOwner {
    for (uint256 i = 0; i < _num; i++) {
      uint256 tokenId = _startIndex + i;
      _safeMint(_to, tokenId);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), extension));
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setRoyaltyReceiver(address _newRoyaltyReceiver) public onlyOwner {
    royaltyReceiver = _newRoyaltyReceiver;
  }

  function setRatioCalculateNum(uint256 _newRatioCalculateNum) public onlyOwner {
    ratioCalculateNum = _newRatioCalculateNum;
  }

  function setSecondarySaleRoyaltyRatio(uint256 _newSecondarySaleRoyaltyRatio) public onlyOwner {
    secondarySaleRoyaltyRatio = _newSecondarySaleRoyaltyRatio;
  }

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = royaltyReceiver;
    royaltyAmount = (_salePrice * secondarySaleRoyaltyRatio) / ratioCalculateNum;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId) || interfaceId == INTERFACE_ID_ERC2981;
  }
}