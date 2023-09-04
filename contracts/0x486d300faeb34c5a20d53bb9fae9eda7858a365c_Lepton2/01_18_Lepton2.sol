// SPDX-License-Identifier: MIT

// Lepton2.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.12;

import "../lib/ERC721Basic.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

import "../interfaces/ILepton.sol";
import "../lib/BlackholePrevention.sol";

contract Lepton2 is ILepton, ERC721Basic, Ownable, ReentrancyGuard, BlackholePrevention {
  using SafeMath for uint256;
  using Address for address payable;

  Classification[] internal _leptonTypes;

  uint256 internal _typeIndex;
  uint256 internal _maxSupply;
  uint256 internal _maxMintPerTx;
  uint256 internal _migratedCount;

  bool internal _paused;
  bool internal _migrationComplete;


  /***********************************|
  |          Initialization           |
  |__________________________________*/

  constructor() public ERC721Basic("Charged Particles - Lepton2", "LEPTON2") {
    _paused = true;
    _migrationComplete = false;
    _migratedCount = 0;
  }


  /***********************************|
  |              Public               |
  |__________________________________*/

  function mintLepton() external payable override nonReentrant whenNotPaused returns (uint256 newTokenId) {
    newTokenId = _mintLepton(msg.sender);
  }

  function batchMintLepton(uint256 count) external payable override nonReentrant whenNotPaused {
    _batchMintLepton(msg.sender, count);
  }

  function totalSupply() public view returns (uint256) {
    return _tokenCount;
  }

  function maxSupply() external view returns (uint256) {
    return _maxSupply;
  }

  function getNextType() external view override returns (uint256) {
    if (_typeIndex >= _leptonTypes.length) { return 0; }
    return _typeIndex;
  }

  function getNextPrice() external view override returns (uint256) {
    if (_typeIndex >= _leptonTypes.length) { return 0; }
    return _leptonTypes[_typeIndex].price;
  }

  function getMultiplier(uint256 tokenId) external view override returns (uint256) {
    require(_exists(tokenId), "LPT:E-405");
    return _getLepton(tokenId).multiplier;
  }

  function getBonus(uint256 tokenId) external view override returns (uint256) {
    require(_exists(tokenId), "LPT:E-405");
    return _getLepton(tokenId).bonus;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "LPT:E-405");
    return _getLepton(tokenId).tokenUri;
  }

  /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

  function addLeptonType(
    string calldata tokenUri,
    uint256 price,
    uint32 supply,
    uint32 multiplier,
    uint32 bonus
  )
    external
    onlyOwner
  {
    _maxSupply = _maxSupply.add(uint256(supply));

    Classification memory lepton = Classification({
      tokenUri: tokenUri,
      price: price,
      supply: supply,
      multiplier: multiplier,
      bonus: bonus,
      _upperBounds: uint128(_maxSupply)
    });
    _leptonTypes.push(lepton);

    emit LeptonTypeAdded(tokenUri, price, supply, multiplier, bonus, _maxSupply);
  }

  function updateLeptonType(
    uint256 leptonIndex,
    string calldata tokenUri,
    uint256 price,
    uint32 supply,
    uint32 multiplier,
    uint32 bonus
  )
    external
    onlyOwner
  {
    _leptonTypes[leptonIndex].tokenUri = tokenUri;
    _leptonTypes[leptonIndex].price = price;
    _leptonTypes[leptonIndex].supply = supply;
    _leptonTypes[leptonIndex].multiplier = multiplier;
    _leptonTypes[leptonIndex].bonus = bonus;

    emit LeptonTypeUpdated(leptonIndex, tokenUri, price, supply, multiplier, bonus, _maxSupply);
  }

  function setMaxMintPerTx(uint256 maxAmount) external onlyOwner {
    _maxMintPerTx = maxAmount;
    emit MaxMintPerTxSet(maxAmount);
  }

  function setPausedState(bool state) external onlyOwner {
    _paused = state;
    emit PausedStateSet(state);
  }


  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }

  function migrateAccounts(address oldLeptonContract, uint256 count) external onlyOwner whenNotMigrated {
    uint256 oldSupply = IERC721Enumerable(oldLeptonContract).totalSupply();
    require(oldSupply == 0 || oldSupply > _migratedCount, "LPT:E-004");

    if (oldSupply > 0) {
      uint256 endTokenId = _migratedCount.add(count);
      if (endTokenId > oldSupply) {
        count = count.sub(endTokenId.sub(oldSupply));
      }

      for (uint256 i = 1; i <= count; i++) {
        uint256 tokenId = _migratedCount.add(i);
        address tokenOwner = IERC721(oldLeptonContract).ownerOf(tokenId);
        _mint(tokenOwner);
      }
      _migratedCount = _migratedCount.add(count);
    }

    if (oldSupply == _migratedCount) {
      _finalizeMigration();
    }
  }

  /***********************************|
  |         Private Functions         |
  |__________________________________*/

  function _getLepton(uint256 tokenId) internal view returns (Classification memory) {
    uint256 types = _leptonTypes.length;
    for (uint256 i = 0; i < types; i++) {
      Classification memory lepton = _leptonTypes[i];
      if (tokenId <= lepton._upperBounds) {
        return lepton;
      }
    }
  }

  function _mintLepton(address receiver) internal returns (uint256 newTokenId) {
    require(_typeIndex < _leptonTypes.length, "LPT:E-408");

    Classification memory lepton = _leptonTypes[_typeIndex];
    require(msg.value >= lepton.price, "LPT:E-414");

    newTokenId = _safeMint(receiver, "");

    // Determine Next Type
    if (newTokenId == lepton._upperBounds) {
      _typeIndex = _typeIndex.add(1);
    }

    _refundOverpayment(lepton.price);
  }

  function _batchMintLepton(address receiver, uint256 count) internal {
    require(_typeIndex < _leptonTypes.length, "LPT:E-408");
    require(_maxMintPerTx == 0 || count <= _maxMintPerTx, "LPT:E-429");

    Classification memory lepton = _leptonTypes[_typeIndex];

    uint256 endTokenId = _tokenCount.add(count);
    if (endTokenId > lepton._upperBounds) {
      count = count.sub(endTokenId.sub(lepton._upperBounds));
    }

    uint256 salePrice = lepton.price.mul(count);
    require(msg.value >= salePrice, "LPT:E-414");

    _safeMintBatch(receiver, count, "");

    // Determine Next Type
    if (endTokenId >= lepton._upperBounds) {
      _typeIndex = _typeIndex.add(1);
    }

    _refundOverpayment(salePrice);
  }

  function _refundOverpayment(uint256 threshold) internal {
    uint256 overage = msg.value.sub(threshold);
    if (overage > 0) {
      payable(_msgSender()).sendValue(overage);
    }
  }

  function _finalizeMigration() internal {
    // Determine Next Type
    _typeIndex = 0;
    for (uint256 i = 0; i < _leptonTypes.length; i++) {
      Classification memory lepton = _leptonTypes[i];
      if (_migratedCount >= lepton._upperBounds) {
        _typeIndex = i + 1;
      }
    }
    _migrationComplete = true;
  }


  /***********************************|
  |             Modifiers             |
  |__________________________________*/

  modifier whenNotMigrated() {
    require(!_migrationComplete, "LPT:E-004");
    _;
  }

  modifier whenNotPaused() {
    require(!_paused, "LPT:E-101");
    _;
  }
}