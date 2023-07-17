// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Auctions/DutchAuction.sol';
import '../Auctions/EnglishAuction.sol';
import '../Auctions/FixedPriceSale.sol';
import '../NFT/DutchAuctionMachine.sol';
import '../NFT/EnglishAuctionMachine.sol';
import '../NFT/NFUEdition.sol';
import '../NFT/NFUToken.sol';
import '../NFT/TraitToken.sol';
import '../TokenLiquidator.sol';
import '../ThinProjectPayer.sol';

import './Deployer_v006.sol';
import './Factories/AuctionMachineFactory.sol';
import './Factories/TraitTokenFactory.sol';
import './Factories/NFUEditionFactory.sol';
import './Factories/ThinProjectPayerFactory.sol';

/**
 * @notice This version of the deployer adds the ability to deploy Dutch and English perpetual auctions for a specific NFT.
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v007 is Deployer_v006 {
  DutchAuctionMachine internal dutchAuctionMachineSource;
  EnglishAuctionMachine internal englishAuctionMachineSource;
  TraitToken internal traitTokenSource;
  NFUEdition internal nfuEditionSource;
  ThinProjectPayer internal projectPayerSource;

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
    ITokenLiquidator _tokenLiquidator,
    DutchAuctionMachine _dutchAuctionMachineSource,
    EnglishAuctionMachine _englishAuctionMachineSource,
    TraitToken _traitTokenSource,
    NFUEdition _nfuEditionSource,
    ThinProjectPayer _projectPayerSource
  ) public virtual reinitializer(7) {
    __Ownable_init();
    __UUPSUpgradeable_init();

    dutchAuctionSource = _dutchAuctionSource;
    englishAuctionSource = _englishAuctionSource;
    fixedPriceSaleSource = _fixedPriceSaleSource;
    nfuTokenSource = _nfuTokenSource;
    nfuMembershipSource = _nfuMembershipSource;
    tokenLiquidator = _tokenLiquidator;
    dutchAuctionMachineSource = _dutchAuctionMachineSource;
    englishAuctionMachineSource = _englishAuctionMachineSource;
    traitTokenSource = _traitTokenSource;
    nfuEditionSource = _nfuEditionSource;
    projectPayerSource = _projectPayerSource;
  }

  /**
   * @param _maxAuctions Maximum number of auctions to perform automatically, 0 for no limit.
   * @param _auctionDuration Auction duration in seconds.
   * @param _periodDuration Price reduction period in seconds.
   * @param _maxPriceMultiplier Dutch auction opening price multiplier. NFT contract must expose price via `unitPrice()`.
   * @param _projectId Juicebox project id which should recieve auction proceeds.
   * @param _jbxDirectory Juicebox directory contract
   * @param _token ERC721 token the Auction machine will have minting privileges on.
   * @param _owner Auction machine admin.
   */
  function deployDutchAuctionMachine(
    uint256 _maxAuctions,
    uint256 _auctionDuration,
    uint256 _periodDuration,
    uint256 _maxPriceMultiplier,
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    address _token,
    address _owner
  ) external returns (address machine) {
    machine = AuctionMachineFactory.createDutchAuctionMachine(
      address(dutchAuctionMachineSource),
      _maxAuctions,
      _auctionDuration,
      _periodDuration,
      _maxPriceMultiplier,
      _projectId,
      _jbxDirectory,
      _token,
      _owner
    );

    emit Deployment('DutchAuctionMachine', machine);
  }

  /**
   * @param _maxAuctions Maximum number of auctions to perform automatically, 0 for no limit.
   * @param _auctionDuration Auction duration in seconds.
   * @param _projectId Juicebox project id, used to transfer auction proceeds.
   * @param _jbxDirectory Juicebox directory, used to transfer auction proceeds to the correct terminal.
   * @param _token Token contract to operate on.
   * @param _owner Auction machine admin.
   */
  function deployEnglishAuctionMachine(
    uint256 _maxAuctions,
    uint256 _auctionDuration,
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    address _token,
    address _owner
  ) external returns (address machine) {
    machine = AuctionMachineFactory.createEnglishAuctionMachine(
      address(englishAuctionMachineSource),
      _maxAuctions,
      _auctionDuration,
      _projectId,
      _jbxDirectory,
      _token,
      _owner
    );
    emit Deployment('EnglishAuctionMachine', machine);
  }

  function deployTraitToken(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance
  ) external returns (address token) {
    token = TraitTokenFactory.createTraitToken(
      address(traitTokenSource),
      _owner,
      _name,
      _symbol,
      _baseUri,
      _contractUri,
      _maxSupply,
      _unitPrice,
      _mintAllowance
    );

    emit Deployment('TraitToken', token);
  }

  function deployNFUEdition(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance
  ) external returns (address token) {
    token = NFUEditionFactory.createNFUEdition(
      address(nfuEditionSource),
      _owner,
      _name,
      _symbol,
      _baseUri,
      _contractUri,
      _maxSupply,
      _unitPrice,
      _mintAllowance
    );

    emit Deployment('NFUEdition', token);
  }

  /**
   * @notice Deploys a ThinProjectPayer by cloning a known instance.
   */
  function deployProjectPayer(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    uint256 _defaultProjectId,
    address payable _defaultBeneficiary,
    bool _defaultPreferClaimedTokens,
    bool _defaultPreferAddToBalance,
    string memory _defaultMemo,
    bytes memory _defaultMetadata
  ) external returns (address payer) {
    payer = ThinProjectPayerFactory.createProjectPayer(
      payable(projectPayerSource),
      _jbxDirectory,
      _jbxOperatorStore,
      _jbxProjects,
      _defaultProjectId,
      _defaultBeneficiary,
      _defaultPreferClaimedTokens,
      _defaultPreferAddToBalance,
      _defaultMemo,
      _defaultMetadata
    );

    emit Deployment('ThinProjectPayer', payer);
  }
}