// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@sbinft/contracts/upgradeable/access/AdminUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "contracts/sbinft/market/v1/interface/IPlatformRegistry.sol";

/**
 * @dev SBINFT Platform Registry
 */
contract PlatformRegistry is
  Initializable,
  IPlatformRegistry,
  EIP712Upgradeable,
  ERC2771ContextUpgradeable,
  AdminUpgradeable,
  ERC165Upgradeable,
  UUPSUpgradeable
{
  using AddressUpgradeable for address;
  using ECDSAUpgradeable for bytes32;

  // Fired when PlatformFeeReceiver is changed
  event PlatformFeeReceiverUpdated(address indexed _pfFeeReceiver);
  // Address of PlatformFeeReceiver
  address payable private _pfFeeReceiver;

  // Fired when PartnerFeeReceiverUpdated is changed
  event PartnerFeeReceiverUpdated(
    address indexed collection,
    address indexed partner
  );
  // Map of partner collection and its respective fee receivers
  mapping(address => address payable) private _partnerFeeReceiverInfo;

  event ERC20AddedToWhitelist(address addedToken);
  event ERC20RemovedFromWhitelist(address removedToken);
  // Map of ERC20 Token address => approve state
  mapping(address => bool) private _whitelistERC20;

  event PlatformSignerAdded(address addedAddress);
  event PlatformSignerRemoved(address removedAddress);
  // Map of Approved platform signer
  mapping(address => bool) private _platformSigner;

  // Fired when PartnerPfFeeReceiverUpdated is changed
  event PlatformFeeLowerRateUpdated(uint16 pfFeelowerlimit);
  // uint16 of pfFeeLowerLimit
  uint16 private _pfFeeLowerLimit;

  // Fired when ExternalPlatformFeeReceiverUpdated is changed
  event ExternalPlatformFeeReceiverUpdated(
    address indexed platformSigner,
    address indexed partnerPf
  );
  // Map of partner platformSigner and its respective fee receivers
  mapping(address => address payable) private _externalPfFeeReceiverInfo;

  bytes32 private constant UPDATE_PARTNER_FEE_RECEIVER_TYPEHASH =
    keccak256(
      "PartnerFeeReceiverInfo(address collection,address partnerFeeReceiver)"
    );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(
    address trustedForwarder
  ) ERC2771ContextUpgradeable(trustedForwarder) {
    _disableInitializers();
  }

  /**
   * @dev Used instead of constructor(must be called once)
   *
   * @param _pfFeeReceiver_ address of PlatformFeeReceiver
   * @param _platformSignerList address[] list of Platform Signer
   * @param _whitelistERC20List address[] list of whitlisted ERC20 token
   *
   * Emits a {PlatformFeeReceiverUpdated} event
   */
  function __PlatformRegistry_init(
    address payable _pfFeeReceiver_,
    address[] calldata _platformSignerList,
    address[] calldata _whitelistERC20List
  ) external initializer {
    __ERC165_init();
    AdminUpgradeable.__Admin_init();
    __EIP712_init("SBINFT Platform Registry", "1.0");
    __UUPSUpgradeable_init();

    updatePlatformFeeReceiver(_pfFeeReceiver_);

    addPlatformSigner(_platformSignerList);
    addToERC20Whitelist(_whitelistERC20List);
  }

  /**
   * @dev See {UUPSUpgradeable._authorizeUpgrade()}
   *
   * Requirements:
   * - onlyAdmin can call
   */
  function _authorizeUpgrade(
    address _newImplementation
  ) internal virtual override onlyAdmin {}

  /**
   * @dev See {IERC165Upgradeable-supportsInterface}.
   *
   * @param _interfaceId bytes4
   */
  function supportsInterface(
    bytes4 _interfaceId
  )
    public
    view
    virtual
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      _interfaceId == type(IPlatformRegistry).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /**
   * See {ERC2771ContextUpgradeable._msgSender()}
   */
  function _msgSender()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (address sender)
  {
    return ERC2771ContextUpgradeable._msgSender();
  }

  /**
   * See {ERC2771ContextUpgradeable._msgData()}
   */
  function _msgData()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (bytes calldata)
  {
    return ERC2771ContextUpgradeable._msgData();
  }

  /**
   * @dev Update to new PlatformFeeReceiver
   *
   * @param _newPlatformFeeReceiver new PlatformFeeReceiver
   *
   * Requirements:
   * - _newPlatformFeeReceiver must be a non zero address
   *
   * Emits a {PlatformFeeReceiverUpdated} event
   */
  function updatePlatformFeeReceiver(
    address payable _newPlatformFeeReceiver
  ) public virtual override onlyAdmin {
    // EM: new PlatformFeeReceiver can't be zero address
    require(_newPlatformFeeReceiver != address(0), "P:UPFR:PZA");

    _pfFeeReceiver = _newPlatformFeeReceiver;

    emit PlatformFeeReceiverUpdated(_newPlatformFeeReceiver);
  }

  /**
   * @dev Update to new PartnerFeeReceiver for partner's collection
   *
   * @param collection partner's collection
   * @param partnerFeeReceiver new partner's FeeReceiver
   * @param sign bytes calldata
   *
   * Requirements:
   * - collection must be a contract address
   * - partnerFeeReceiver must be a non zero address
   *
   * Emits a {PartnerFeeReceiverUpdated} event
   */
  function updatePartnerFeeReceiver(
    address collection,
    address payable partnerFeeReceiver,
    bytes calldata sign
  ) external virtual override {
    // EM: partner's collection must be a contract address
    require(collection.isContract(), "P:UPFR:PCCA");
    // EM: new PartnerFeeReceiver can't be zero address
    require(partnerFeeReceiver != address(0), "P:UPFR:NPZA");

    // caller is an Admin or its called with Platform signature
    if (isAdmin(_msgSender()) == false) {
      // Prepares ERC712 message hash of updatePartnerFeeReceiver signature
      bytes32 msgHash = keccak256(
        abi.encode(
          UPDATE_PARTNER_FEE_RECEIVER_TYPEHASH,
          collection,
          partnerFeeReceiver
        )
      );

      address recoverdAddress = _domainSeparatorV4()
        .toTypedDataHash(msgHash)
        .recover(sign);
      // EM: invalid platform signer
      require(isPlatformSigner(recoverdAddress), "P:UPFR:IPS");
    }

    _partnerFeeReceiverInfo[collection] = partnerFeeReceiver;

    emit PartnerFeeReceiverUpdated(collection, partnerFeeReceiver);
  }

  /**
   * @dev Checks if partner fee receiver
   *
   * @param _collection address of token
   * @param _partnerFeeReceiver address of partner FeeReceiver
   *
   * Requirements:
   * - _collection must be a non zero address
   * - _partnerFeeReceiver must be a non zero address
   */
  function isPartnerFeeReceiver(
    address _collection,
    address _partnerFeeReceiver
  ) public view virtual override returns (bool) {
    // EM: _collection must be a non zero address
    require(_collection != address(0), "P:IPFR:CNZA");
    // EM: _partnerFeeReceiver must be a non zero address
    require(_partnerFeeReceiver != address(0), "P:IPFR:PNZA");

    return _partnerFeeReceiverInfo[_collection] == _partnerFeeReceiver;
  }

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _token address of token
   */
  function isWhitelistedERC20(
    address _token
  ) public view virtual override returns (bool) {
    return _whitelistERC20[_token];
  }

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _addTokenList array of address of token to add
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {AddedToWhitelist} event
   */
  function addToERC20Whitelist(
    address[] calldata _addTokenList
  ) public virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _addTokenList.length; idx++) {
      address newToken = _addTokenList[idx];

      if (newToken != address(0) && newToken.isContract()) {
        _whitelistERC20[newToken] = true;
        emit ERC20AddedToWhitelist(newToken);
      }
    }
  }

  /**
   * @dev Removes list of token from Whitelisted
   *
   * @param _removeTokenList array of address of token to remove
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {RemovedFromWhitelist} event
   */
  function removeFromERC20Whitelist(
    address[] calldata _removeTokenList
  ) external virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _removeTokenList.length; idx++) {
      address tokenToRemove = _removeTokenList[idx];
      if (tokenToRemove != address(0)) {
        delete _whitelistERC20[tokenToRemove];
        emit ERC20RemovedFromWhitelist(tokenToRemove);
      }
    }
  }

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _signer address of token
   */
  function isPlatformSigner(
    address _signer
  ) public view virtual override returns (bool) {
    return _platformSigner[_signer];
  }

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _platformSignerList array of platfomr signer address  to add
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {PlatformSignerAdded} event
   */
  function addPlatformSigner(
    address[] calldata _platformSignerList
  ) public virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _platformSignerList.length; idx++) {
      address newSigner = _platformSignerList[idx];
      if (newSigner != address(0)) {
        _platformSigner[newSigner] = true;
        emit PlatformSignerAdded(newSigner);
      }
    }
  }

  /**
   * @dev Removes list of platform signers address
   *
   * @param _platformSignerList array of platfomr signer address to remove
   *
   * Requirements:
   * - onlyAdmin can call
   *
   * Emits a {PlatformSignerRemoved} event
   */
  function removePlatformSigner(
    address[] calldata _platformSignerList
  ) external virtual override onlyAdmin {
    for (uint256 idx = 0; idx < _platformSignerList.length; idx++) {
      address signerToRemove = _platformSignerList[idx];
      if (signerToRemove != address(0)) {
        delete _platformSigner[signerToRemove];
        emit PlatformSignerRemoved(signerToRemove);
      }
    }
  }

  /**
   * @dev Returns PartnerFeeReceiver
   *
   * @param _token address of partner token
   */
  function getPartnerFeeReceiver(
    address _token
  ) external virtual override returns (address payable) {
    return _partnerFeeReceiverInfo[_token];
  }

  /**
   * @dev Returns PlatformFeeReceiver
   *
   */
  function getPlatformFeeReceiver()
    external
    view
    virtual
    override
    returns (address payable)
  {
    return _pfFeeReceiver;
  }

  /**
   * @dev Returns PlatformFeeReceiver
   *
   */
  function getPlatformFeeRateLowerLimit()
    public
    virtual
    override
    returns (uint16)
  {
    return _pfFeeLowerLimit;
  }

  /**
   * @dev Update to new PlatformFeeLowerLimit
   *
   * Emits a {PlatformFeeLowerRateUpdated} event
   */
  function updatePlatformFeeLowerLimit(
    uint16 _platformFeeLowerLimit
  ) external virtual override onlyAdmin {
    _pfFeeLowerLimit = _platformFeeLowerLimit;
    emit PlatformFeeLowerRateUpdated(_pfFeeLowerLimit);
  }

  /**
   * @dev Update to new PartnerPfFeeReceiver for partner's platformSigner
   *
   * @param _externalPlatformToken address of external Platform Token
   * @param _partnerPfFeeReceiver address new partner's platformer FeeReceiver
   *
   * Requirements:
   * - _platformSigner must be a non zero address
   * - _partnerPfFeeReceiver must be a non zero address
   *
   * Emits a {ExternalPfFeeReceiverUpdated} event
   */
  function updateExternalPlatformFeeReceiver(
    address _externalPlatformToken,
    address payable _partnerPfFeeReceiver
  ) external virtual override onlyAdmin {
    // EM: new platfromSigner can't be zero address
    require(_externalPlatformToken != address(0), "A:UPFR:NPZA");
    // EM: new PartnerFeeReceiver can't be zero address
    require(_partnerPfFeeReceiver != address(0), "A:UPFR:NPZA");

    _externalPfFeeReceiverInfo[_externalPlatformToken] = _partnerPfFeeReceiver;

    emit ExternalPlatformFeeReceiverUpdated(
      _externalPlatformToken,
      _partnerPfFeeReceiver
    );

    /**
     * Test cases
     * 1. _platformSigner Zero address
     * 2. _partnerPfFeeReceiver Zero address
     * 3. Non Admin call
     * 4. Emits PartnerFeeReceiverUpdated event
     */
  }

  /**
   * @dev Returns ExternalPlatformFeeReceiver
   *
   * @param _token address of external platform token
   */
  function getExternalPlatformFeeReceiver(
    address _token
  ) external virtual override returns (address payable) {
    return _externalPfFeeReceiverInfo[_token];
  }

  /**
   * @dev Check validity of arguments when called CreateAuction
   *
   * @param _auction AuctionDomain.Auction auction info
   */
  function checkParametaForAuctionCreate(
    AuctionDomain.Auction calldata _auction
  ) external virtual override {
    //creator address check
    require(
      AuctionDomain._isValidPlatformKind(_auction.pfKind),
      "A:CPFAC:AIPK"
    );

    require(_auction.creatorAddress != address(0), "A:CPFAC:AICA");

    // EM: Auction asset invalid originKind
    require(
      AuctionDomain._isValidOriginKind(_auction.asset.originKind),
      "A:CPFAC:SAIO"
    );
    // EM: Auction asset invalid token
    require(_auction.asset.asset.isContract(), "A:CPFAC:SAIAA");
    // EM: Auction asset invalid tokenId
    require(_auction.asset.assetId != 0, "A:CPFAC:SAIAI");

    //EM: Auction auctionType invalid bidMode
    require(
      AuctionDomain._isValidBidMode(_auction.auctionType.bidMode),
      "A:CPFAC:BTIBM"
    );
    //EM: Auction auctionType invalid auctionKind
    require(
      AuctionDomain._isValidAuctionKind(_auction.auctionType.auctionKind),
      "A:CPFAC:BTIBEM"
    );
    //EM: Auction auctionType invalid Bid_Currency
    require(
      _auction.auctionType.paymentToken == address(0) ||
        _auction.auctionType.paymentToken.isContract(),
      "A:CPFAC:BTITA"
    );

    //EM: Auction startTime invalid
    require(_auction.startTime > block.timestamp, "A:CPFAC:STI");
    //EM: Auction startTime is bigger than endTime
    require(_auction.endTime > _auction.startTime, "A:CPFAC:ETIBTST");

    //EM: Auction pfFeeRate limit is lower than limit
    require(
      _auction.pfFeeRate >= getPlatformFeeRateLowerLimit(),
      "A:CPFAC:APFLTL"
    );

    //EM: Auction PFFeeRate limit is lower than pfFeelowerlimit
    require(
      _auction.externalPfFeeRate >= getPlatformFeeRateLowerLimit() ||
        _auction.externalPfFeeRate == 0,
      "A:CPFAC:AIPPFR"
    );

    //EM: Auction platformSigner not eqaul zero Address
    require(
      _auction.platformSigner != address(0) &&
        isPlatformSigner(_auction.platformSigner),
      "A:CPFAC:AIPS|PSNPA"
    );
  }
}