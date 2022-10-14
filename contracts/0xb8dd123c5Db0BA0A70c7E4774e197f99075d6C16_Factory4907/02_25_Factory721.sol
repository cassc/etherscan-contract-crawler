// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '../vaults/Vault721.sol';
import '../interfaces/IMarket.sol';
import '../libraries/Detector.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

contract Factory721 is Ownable {
  using Detector for address;

  address internal _market;

  event VaultDeployed(address indexed vault, address indexed collection);

  constructor(address market) {
    _market = market;
  }

  //@notice Create a vault by hitting this function from the frontend UI
  //@access Can be executed by anyone, but must be the owner of the original NFT collection
  function deployVault(
    string memory _name,
    string memory _symbol,
    address _collection,
    uint256 _minDuration, // default: 0, as non limited
    uint256 _maxDuration, // default: 1000 years, as non limited
    uint256 _collectionOwnerFeeRatio, //default: 0, (1000 = 1%)
    uint256[] memory _minPrices, // default: 0, as a non limited
    address[] memory _paymentTokens, // default: 0x00
    uint256[] calldata _allowedTokenIds // default: [], it will be allow all tokens
  ) external virtual {
    require(_collection.is721(), 'OnlyERC721');

    address _vault = address(
      new Vault721(
        _name,
        _symbol,
        _collection,
        msg.sender,
        _market,
        _minDuration * 1 days, // day -> sec
        _maxDuration * 1 days, // day -> sec
        _collectionOwnerFeeRatio, // bps: 1000 => 1%
        _minPrices, // wei
        _paymentTokens,
        _allowedTokenIds
      )
    );

    emit VaultDeployed(_vault, _collection);
  }
}