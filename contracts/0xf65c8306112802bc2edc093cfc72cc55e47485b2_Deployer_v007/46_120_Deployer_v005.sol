// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Auctions/DutchAuction.sol';
import '../Auctions/EnglishAuction.sol';
import '../Auctions/FixedPriceSale.sol';
import '../NFT/NFUToken.sol';
import '../TokenLiquidator.sol';
import './Deployer_v004.sol';
import './Factories/PaymentProcessorFactory.sol';

/**
 * @notice This version of the deployer adds the ability to deploy PaymentProcessor instances to allow project to accept payments in various ERC20 tokens.
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v005 is Deployer_v004 {
  ITokenLiquidator internal tokenLiquidator;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    DutchAuctionHouse _dutchAuctionSource,
    EnglishAuctionHouse _englishAuctionSource,
    FixedPriceSale _fixedPriceSaleSource,
    NFUToken _nfuTokenSource,
    NFUMembership _nfuMembershipSource,
    ITokenLiquidator _tokenLiquidator
  ) public virtual reinitializer(5) {
    __Ownable_init();
    __UUPSUpgradeable_init();

    dutchAuctionSource = _dutchAuctionSource;
    englishAuctionSource = _englishAuctionSource;
    fixedPriceSaleSource = _fixedPriceSaleSource;
    nfuTokenSource = _nfuTokenSource;
    nfuMembershipSource = _nfuMembershipSource;
    tokenLiquidator = _tokenLiquidator;
  }

  function deployPaymentProcessor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) external returns (address processor) {
    processor = PaymentProcessorFactory.createPaymentProcessor(
      _jbxDirectory,
      _jbxOperatorStore,
      _jbxProjects,
      tokenLiquidator,
      _jbxProjectId,
      _ignoreFailures,
      _defaultLiquidation
    );

    emit Deployment('PaymentProcessor', processor);
  }
}