// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import './Vault721.sol';
import '../ERC4907/IERC4907.sol';

contract Vault4907 is Vault721 {
  constructor(
    string memory _name,
    string memory _symbol,
    address _collection,
    address _collectionOwner,
    address _marketContract,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _collectionOwnerFeeRatio,
    uint256[] memory _minPrices,
    address[] memory _paymentTokens, // 'Stack too deep' error because of too many args!
    uint256[] memory _allowedTokenIds
  )
    Vault721(
      _name,
      _symbol,
      _collection,
      _collectionOwner,
      _marketContract,
      _minDuration,
      _maxDuration,
      _collectionOwnerFeeRatio,
      _minPrices,
      _paymentTokens,
      _allowedTokenIds
    )
  {}

  function _deployWrap() internal pure override {
    return;
  }

  function _mintWNft(
    address _renter,
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount
  ) internal override {
    _amount;
    IMarket.LendRent memory _lendRent = IMarket(marketContract).getLendRent(_lockId);
    uint256 _rentalExpireTime = _lendRent.rent[0].rentalExpireTime;
    IERC4907(originalCollection).setUser(_tokenId, _renter, uint64(_rentalExpireTime));
  }
}