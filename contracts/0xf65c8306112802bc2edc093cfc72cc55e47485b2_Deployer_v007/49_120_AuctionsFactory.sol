// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import '../../../interfaces/IJBDirectory.sol';
import '../../../interfaces/IJBPaymentTerminal.sol';

import '../../Auctions/DutchAuction.sol';
import '../../Auctions/EnglishAuction.sol';
import '../../Auctions/FixedPriceSale.sol';

library AuctionsFactory {
  error INVALID_SOURCE_CONTRACT();

  function createDutchAuction(
    address _source,
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    uint256 _periodDuration,
    address _owner,
    IJBDirectory _directory
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IDutchAuctionHouse).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    DutchAuctionHouse(auctionClone).initialize(
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _periodDuration,
      _owner,
      _directory
    );
  }

  function createEnglishAuction(
    address _source,
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    address _owner,
    IJBDirectory _directory
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IEnglishAuctionHouse).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    EnglishAuctionHouse(auctionClone).initialize(
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _owner,
      _directory
    );
  }

  function createFixedPriceSale(
    address _source,
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicSales,
    address _owner,
    IJBDirectory _directory
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IFixedPriceSale).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    FixedPriceSale(auctionClone).initialize(
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicSales,
      _owner,
      _directory
    );
  }
}