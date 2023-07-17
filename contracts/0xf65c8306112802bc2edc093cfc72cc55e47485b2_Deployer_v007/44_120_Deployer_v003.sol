// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Auctions/DutchAuction.sol';
import '../Auctions/EnglishAuction.sol';
import '../Auctions/FixedPriceSale.sol';
import './Deployer_v002.sol';
import './Factories/AuctionsFactory.sol';

/**
 * @notice This version of the deployer adds the ability to create DutchAuctionHouse, EnglishAuctionHouse and FixedPriceSale contracts.
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v003 is Deployer_v002 {
  DutchAuctionHouse internal dutchAuctionSource;
  EnglishAuctionHouse internal englishAuctionSource;
  FixedPriceSale internal fixedPriceSaleSource;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _dutchAuctionSource,
    address _englishAuctionSource,
    address _fixedPriceSaleSource
  ) public virtual override reinitializer(3) {
    // NOTE: clashes with Deployer_001
    __Ownable_init();
    __UUPSUpgradeable_init();

    dutchAuctionSource = DutchAuctionHouse(_dutchAuctionSource);
    englishAuctionSource = EnglishAuctionHouse(_englishAuctionSource);
    fixedPriceSaleSource = FixedPriceSale(_fixedPriceSaleSource);
  }

  function deployDutchAuction(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    uint256 _periodDuration,
    address _owner,
    IJBDirectory _directory
  ) external returns (address auction) {
    auction = AuctionsFactory.createDutchAuction(
      address(dutchAuctionSource),
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _periodDuration,
      _owner,
      _directory
    );

    emit Deployment('DutchAuctionHouse', auction);
  }

  function deployEnglishAuction(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    address _owner,
    IJBDirectory _directory
  ) external returns (address auction) {
    auction = AuctionsFactory.createEnglishAuction(
      address(englishAuctionSource),
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _owner,
      _directory
    );

    emit Deployment('EnglishAuctionHouse', auction);
  }

  function deployFixedPriceSale(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicSales,
    address _owner,
    IJBDirectory _directory
  ) external returns (address sale) {
    sale = AuctionsFactory.createFixedPriceSale(
      address(fixedPriceSaleSource),
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicSales,
      _owner,
      _directory
    );

    emit Deployment('FixedPriceSale', sale);
  }
}