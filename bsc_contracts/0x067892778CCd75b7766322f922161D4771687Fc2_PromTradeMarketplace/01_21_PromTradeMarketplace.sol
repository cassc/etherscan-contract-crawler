// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7;

import "./TradeMarketplaceCore.sol";

contract PromTradeMarketplace is TradeMarketplaceCore {
  constructor(
    address _addressRegistry,
    address _promToken,
    address _pauser,
    address _oracle,
    uint16 _promFeeDiscount
  ) {
    _setupRole(ADMIN_SETTER, msg.sender);
    _setupRole(PAUSER, _pauser);
    addressRegistry = IPromAddressRegistry(_addressRegistry);
    promToken = _promToken;
    oracle = IPromOracle(_oracle);
    promFeeDiscount = _promFeeDiscount;
  }

  function multicallList(
    address[] memory _nftAddresses,
    uint256[] memory _tokenIds,
    uint256[] memory _quantities,
    address[] memory _payTokens,
    uint256[] memory _pricePerItems,
    uint256[] memory _startingTimes,
    uint256[] memory _endTimes
  ) public {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      listItem(
        _nftAddresses[i],
        _tokenIds[i],
        _quantities[i],
        _payTokens[i],
        _pricePerItems[i],
        _startingTimes[i],
        _endTimes[i]
      );
    }
  }

  function multicallBuy(
    address[] calldata _nftAddresses,
    uint256[] calldata _tokenIds,
    address[] calldata _owners,
    uint256[] calldata _nonces
  ) public payable {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      buyItem(_nftAddresses[i], _tokenIds[i], _owners[i], _nonces[i]);
    }
  }

  function multicallBuyWithFeeInProm(
    address[] calldata _nftAddresses,
    uint256[] calldata _tokenIds,
    address[] calldata _owners,
    uint256[] calldata _nonces
  ) public payable {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      buyItemWithFeeInProm(
        _nftAddresses[i],
        _tokenIds[i],
        _owners[i],
        _nonces[i]
      );
    }
  }

  function multicallCancel(
    address[] calldata _nftAddresses,
    uint256[] calldata _tokenIds
  ) public {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      cancelListing(_nftAddresses[i], _tokenIds[i]);
    }
  }
}