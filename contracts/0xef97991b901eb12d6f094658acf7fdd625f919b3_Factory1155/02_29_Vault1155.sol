// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import './Vault721.sol';
import {IWrap1155} from '../interfaces/IWrap.sol';
import '../wraps/Wrap1155.sol';

contract Vault1155 is Vault721 {
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

  function _deployWrap() internal override {
    wrapContract = address(
      new Wrap1155(
        string(abi.encodePacked('Wrapped ', originalName)),
        string(abi.encodePacked('W', originalSymbol)),
        marketContract
      )
    );
  }

  function _redeem(uint256 _lockId) internal override {
    IMarket.Lend memory _lend = IMarket(marketContract).getLendRent(_lockId).lend;
    // Send tokens back from Vault contract to the user's wallet
    IERC1155(originalCollection).safeTransferFrom(
      address(this),
      ownerOf(_lockId),
      _lend.tokenId,
      _lend.amount,
      ''
    );
    _burn(_lockId);
  }

  function _mintWNft(
    address _renter,
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount
  ) internal override {
    IWrap1155(wrapContract).emitTransfer(address(this), _renter, _tokenId, _amount, _lockId);
  }

  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    uint256 _value,
    bytes memory _data
  ) external pure returns (bytes4) {
    _operator;
    _from;
    _tokenId;
    _value;
    _data;
    return 0xf23a6e61;
  }

  // function onERC1155BatchReceived(
  //     address _operator,
  //     address _from,
  //     uint256[] memory _tokenIds,
  //     uint256[] memory _values,
  //     bytes memory _data
  // ) external pure returns (bytes4) {
  //     _operator;
  //     _from;
  //     _tokenIds;
  //     _values;
  //     _data;
  //     return 0xbc197c81;
  // }
}