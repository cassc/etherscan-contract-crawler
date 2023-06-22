// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './ERC721Enumerable.sol';

contract LoanToken is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  address public lendingPool;

  Counters.Counter internal _ids;
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while
  address public royaltyAddress;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  uint256[] _openedLoans;
  // tokenId => _openedLoans idx
  mapping(uint256 => uint256) _openedIndex;
  // token IDs owned by user
  mapping(address => uint256[]) public allUserOwned;
  // tokenId => allUserOwned idx
  mapping(uint256 => uint256) public ownedIndex;

  event Burn(uint256 indexed tokenId, address indexed owner);
  event Mint(uint256 indexed tokenId, address indexed owner);
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);

  modifier onlyLendingPool() {
    require(msg.sender == lendingPool, 'ONLYLENDINGPOOL');
    _;
  }

  constructor(
    string memory _baseTokenURI
  ) ERC721('Hyperbolic Protocol Loan', 'lHYPE') {
    baseTokenURI = _baseTokenURI;
    lendingPool = msg.sender;
  }

  function getAllOpenedLoans() external view returns (uint256[] memory) {
    return _openedLoans;
  }

  function mint(address owner) external onlyLendingPool returns (uint256) {
    _ids.increment();
    _safeMint(owner, _ids.current());
    emit Mint(_ids.current(), owner);
    return _ids.current();
  }

  function burn(uint256 _tokenId) external onlyLendingPool {
    address _user = ownerOf(_tokenId);
    require(_exists(_tokenId));
    _burn(_tokenId);
    emit Burn(_tokenId, _user);
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(
    uint256,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 1000);
  }

  function tokenURI(
    uint256 _tokenId
  ) public view virtual override returns (string memory) {
    require(_exists(_tokenId));
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(
    bytes4 _interfaceId
  ) public view virtual override(ERC721Enumerable) returns (bool) {
    return super.supportsInterface(_interfaceId);
  }

  function getLastMintedTokenId() external view returns (uint256) {
    return _ids.current();
  }

  function doesTokenExist(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
    emit SetRoyaltyAddress(_address);
  }

  function setRoyaltyBasisPoints(uint256 _points) external onlyOwner {
    royaltyBasisPoints = _points;
    emit SetRoyaltyBasisPoints(_points);
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
    emit SetBaseTokenURI(_uri);
  }

  function setLendingPool(address _addy) external onlyOwner {
    lendingPool = _addy;
  }

  function getAllUserOwned(
    address _user
  ) external view returns (uint256[] memory) {
    return allUserOwned[_user];
  }

  function _baseURI() internal view returns (string memory) {
    return baseTokenURI;
  }

  function _mint(address to, uint256 tokenId) internal virtual override {
    super._mint(to, tokenId);
    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override {
    address _owner = ERC721.ownerOf(tokenId);
    super._burn(tokenId);
    _afterTokenTransfer(_owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._transfer(from, to, tokenId);
    _afterTokenTransfer(from, to, tokenId);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual {
    // ensure token not being minted
    if (_from != address(0)) {
      // update user owned
      uint256 _currIndex = ownedIndex[_tokenId];
      uint256 _tokenIdMovingIndices = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from][_currIndex] = _tokenIdMovingIndices;
      allUserOwned[_from].pop();
      ownedIndex[_tokenIdMovingIndices] = _currIndex;

      // update all opened
      uint256 _curOpenedIdx = _openedIndex[_tokenId];
      uint256 _tokenIdMoveOpened = _openedLoans[_openedLoans.length - 1];
      _openedLoans[_curOpenedIdx] = _tokenIdMoveOpened;
      _openedLoans.pop();
      _openedIndex[_tokenIdMoveOpened] = _curOpenedIdx;
    }

    // ensure token not being burned
    if (_to != address(0)) {
      // update user owned
      ownedIndex[_tokenId] = allUserOwned[_to].length;
      allUserOwned[_to].push(_tokenId);

      // update all opened
      _openedIndex[_tokenId] = _openedLoans.length;
      _openedLoans.push(_ids.current());
    }
  }
}