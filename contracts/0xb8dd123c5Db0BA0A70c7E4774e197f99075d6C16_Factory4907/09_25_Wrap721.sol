// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '../interfaces/IMarket.sol';
import '../interfaces/IVault.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

contract Wrap721 is ERC721 {
  constructor(
    string memory _name,
    string memory _symbol,
    address _marketAddress
  ) ERC721(_name, _symbol) {
    _vault = msg.sender;
    _market = _marketAddress;
  }

  address private _vault;
  address private _market;
  uint256[] private _tokens;

  // tokenId => lockId
  mapping(uint256 => uint256) private _tokenToLocks;

  modifier onlyVault() {
    require(msg.sender == _vault, 'onlyVault');
    _;
  }

  function _exists(uint256 _tokenId) internal view override returns (bool) {
    // Check Lend existence
    uint256 _lockId = _tokenToLocks[_tokenId];
    if (_lockId == 0) return false;

    // Check Rent existence
    IMarket.LendRent memory _lendRent = IMarket(_market).getLendRent(_lockId);
    if (_lendRent.rent.length == 0) return false;

    // Check Rent validity
    uint256 _rentalExpireTime = _lendRent.rent[0].rentalExpireTime;
    return _rentalExpireTime > block.timestamp;
  }

  function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
    uint256 _now = block.timestamp;
    IMarket.Rent[] memory _rents = IMarket(_market).getLendRent(_tokenToLocks[_tokenId]).rent;

    if (_rents.length == 0) return address(0);

    if (_rents[0].rentalStartTime <= _now && _now <= _rents[0].rentalExpireTime) {
      return _rents[0].renterAddress;
    } else {
      return address(0);
    }
  }

  //ownerOfに依存する.ownerOfが正しければ、これも正しい
  function balanceOf(address owner) public view override returns (uint256) {
    uint256 _balance;
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (ownerOf(_tokens[i]) == owner) _balance++;
    }
    return _balance;
  }

  function emitTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _lockId
  ) public onlyVault {
    _tokenToLocks[_tokenId] = _lockId;
    _tokens.push(_tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return IERC721Metadata(IVault(_vault).originalCollection()).tokenURI(_tokenId);
  }

  modifier disabled() {
    require(false, 'Disabled function');
    _;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override disabled {}

  function approve(address to, uint256 tokenId) public override disabled {}

  function getApproved(uint256 tokenId) public view override disabled returns (address) {}

  function setApprovalForAll(address operator, bool _approved) public override disabled {}

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    disabled
    returns (bool)
  {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override disabled {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) public override disabled {}
}