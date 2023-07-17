// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import '../../../interfaces/IJBDirectory.sol';

import '../../NFT/DutchAuctionMachine.sol';
import '../../NFT/EnglishAuctionMachine.sol';

library AuctionMachineFactory {
  error INVALID_SOURCE_CONTRACT();

  function createDutchAuctionMachine(
    address _source,
    uint256 _maxAuctions,
    uint256 _auctionDuration,
    uint256 _periodDuration,
    uint256 _maxPriceMultiplier,
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    address _token,
    address _owner
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IDutchAuctionMachine).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    DutchAuctionMachine(auctionClone).initialize(
      _maxAuctions,
      _auctionDuration,
      _periodDuration,
      _maxPriceMultiplier,
      _projectId,
      _jbxDirectory,
      _token,
      _owner
    );
  }

  function createEnglishAuctionMachine(
    address _source,
    uint256 _maxAuctions,
    uint256 _auctionDuration,
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    address _token,
    address _owner
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IEnglishAuctionMachine).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    EnglishAuctionMachine(auctionClone).initialize(
      _maxAuctions,
      _auctionDuration,
      _projectId,
      _jbxDirectory,
      _token,
      _owner
    );
  }
}