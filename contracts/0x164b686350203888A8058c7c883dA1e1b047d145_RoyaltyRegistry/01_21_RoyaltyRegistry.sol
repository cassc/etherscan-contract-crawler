// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@sbinft/contracts/upgradeable/access/AdminUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "contracts/sbinft/market/v1/interface/IRoyaltyRegistry.sol";

/**
 * @title [Upgradeable] Stores royalty information, it supports
 * - tokenId wise (of a collection)
 * - default royalty for a collection
 *
 * It implements IRoyaltyRegistry (which extends IERC2981Upgradeable)
 */
contract RoyaltyRegistry is
  Initializable,
  IRoyaltyRegistry,
  ERC2771ContextUpgradeable,
  ERC165Upgradeable,
  AdminUpgradeable,
  EIP712Upgradeable,
  UUPSUpgradeable
{
  using ECDSAUpgradeable for bytes32;
  using AddressUpgradeable for address;

  // Struct for storing RoyaltyInfo
  struct Royalty {
    address receiver;
    uint16 primaryPercentage;
    uint16 secondaryPercentage;
  }
  struct RoyaltyInfo {
    Royalty[] royaltyList;
    uint8 primaryCount;
    uint8 secondaryCount;
    uint16 secondaryOnwardsRoyaltyPercentage;
  }

  // Fired when maxRoyaltyReceiversCount is changed
  event MaxRoyaltyReceiversCountUpdated(uint8 maxRoyaltyReceiversCount);
  // Number of royalty receivers per token, can be changed later
  uint8 public maxRoyaltyReceiversCount;

  event CollectionDefaultRoyaltyInfoSet(address indexed token);
  event CollectionDefaultRoyaltyInfoDeleted(address indexed token);
  // Manages Collection's DefaultRoyaltyInfo
  mapping(address => RoyaltyInfo) private _collectionDefaultRoyaltyInfo;

  event TokenRoyaltyInfoSet(address indexed token, uint256 indexed tokenId);
  event TokenRoyaltyInfoReset(address indexed token, uint256 indexed tokenId);
  // Manages RoyaltyInfo for each token of a Collection
  mapping(address => mapping(uint256 => RoyaltyInfo)) private _tokenRoyaltyInfo;

  bytes32 constant ROYALTY_TYPEHASH =
    keccak256(
      "Royalty(address receiver,uint16 primaryPercentage,uint16 secondaryPercentage)"
    );
  bytes32 constant ROYALTY_INFO_TYPEHASH =
    keccak256(
      "RoyaltyInfo(Royalty[] royaltyList,uint8 primaryCount,uint8 secondaryCount,uint16 secondaryOnwardsRoyaltyPercentage)Royalty(address receiver,uint16 primaryPercentage,uint16 secondaryPercentage)"
    );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(
    address trustedForwarder
  ) ERC2771ContextUpgradeable(trustedForwarder) {
    _disableInitializers();
  }

  /**
   * @dev Used instead of constructor(must be called once)
   */
  function __RoyaltyRegistry_init() external initializer {
    __ERC165_init();
    AdminUpgradeable.__Admin_init();
    __EIP712_init("SBINFT RoyaltyRegistry", "1.0");
    __UUPSUpgradeable_init();

    maxRoyaltyReceiversCount = 7;
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
      _interfaceId == type(IRoyaltyRegistry).interfaceId ||
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
   * @dev Prepares keccak256 hash for Royalty Info
   *
   * @param royaltyInfo_ RoyaltyInfo calldata
   */
  function _hashRoyaltyInfo(
    RoyaltyInfo calldata royaltyInfo_
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          ROYALTY_INFO_TYPEHASH,
          _hashRoyalty(royaltyInfo_.royaltyList),
          royaltyInfo_.primaryCount,
          royaltyInfo_.secondaryCount,
          royaltyInfo_.secondaryOnwardsRoyaltyPercentage
        )
      );
  }

  /**
   * @dev Prepares keccak256 hash for Royalty List
   *
   * @param royaltyList Royalty[] calldata
   */
  function _hashRoyalty(
    Royalty[] calldata royaltyList
  ) internal pure returns (bytes32) {
    bytes32[] memory keccakData = new bytes32[](royaltyList.length);

    for (uint256 idx = 0; idx < royaltyList.length; idx++) {
      keccakData[idx] = _hashRoyalty(royaltyList[idx]);
    }

    return keccak256(abi.encodePacked(keccakData));
  }

  /**
   * @dev Prepares keccak256 hash for Royalty
   *
   * @param royalty Royalty calldata
   */
  function _hashRoyalty(
    Royalty calldata royalty
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          ROYALTY_TYPEHASH,
          royalty.receiver,
          royalty.primaryPercentage,
          royalty.secondaryPercentage
        )
      );
  }

  /**
   * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
   * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
   * override.
   * 10000 = 100%
   */
  function feeDenominator() public pure virtual override returns (uint16) {
    return 10000;
  }

  /**
   * @dev Updates max royalty receivers count
   *
   * @param _newMaxRoyaltyReceiversCount uint8
   */
  function updateMaxRoyaltyReceiversCount(
    uint8 _newMaxRoyaltyReceiversCount
  ) external onlyAdmin {
    // EM: RoyaltyRegistry:updateMaxRoyaltyReceiversCount _newMaxRoyaltyReceiversCount must be greater than zero
    require(_newMaxRoyaltyReceiversCount > 0, "RR:UMRRC:GTZ");

    maxRoyaltyReceiversCount = _newMaxRoyaltyReceiversCount;

    emit MaxRoyaltyReceiversCountUpdated(_newMaxRoyaltyReceiversCount);
  }

  /**
   * @dev Extended IERC2981
   * with Primary,Secondary judgement
   *
   * @param _token address of collection
   * @param _tokenId uint256 tokenId
   * @param _salePrice uint256 sale price of token
   * @param _isSecondarySale uint8 SecondarySale identifier
   *
   * @return
   * - receivers   : Address of receivers
   * - royaltyFees : Royalty value to be paid
   * - royaltyType : 0 = Non CollectionDefaultRoyalty nor TokenRoyalty
   *                 1 = CollectionDefaultRoyalty
   *                 2 = TokenRoyalty
   */
  function royaltyInfo(
    address _token,
    uint256 _tokenId,
    uint256 _salePrice,
    uint8 _isSecondarySale
  )
    public
    view
    virtual
    override
    returns (address[] memory, uint256[] memory, uint8)
  {
    // EM: RoyaltyRegistry:royaltyInfo _token can't be a zero address
    require(_token != address(0), "RR:RI:TZA");

    // EM: RoyaltyRegistry:royaltyInfo _tokenId can't be zero
    require(_tokenId != 0, "RR:RI:TIDZA");

    // EM: RoyaltyRegistry:royaltyInfo _salePrice can't be zero
    require(_salePrice != 0, "RR:RI:SPZ");

    uint8 royaltyType = 2; // TokenRoyalty

    RoyaltyInfo memory targetRoyaltyInfo = _tokenRoyaltyInfo[_token][_tokenId];
    if (targetRoyaltyInfo.royaltyList.length == 0) {
      // We haven't found RoyaltyInfo for respective _token and _tokenId, let's see if DefaultRoyaltyInfo exists
      targetRoyaltyInfo = _collectionDefaultRoyaltyInfo[_token];

      if (targetRoyaltyInfo.royaltyList.length == 0) {
        // no CollectionRoyaltyInfo nor DefaultRoyaltyInfo was found, so return
        royaltyType = 0; // Non CollectionDefaultRoyalty nor TokenRoyalty
        return (new address[](0), new uint256[](0), royaltyType);
      }

      royaltyType = 1; // CollectionDefaultRoyalty
    }

    // Find the amount that needs to be split for royalty
    uint256 splitTotalPrice = _salePrice;
    if (_isSecondarySale == 1) {
      // Secondary Sale onwards royalty is distributed based on royaltyPercentage
      splitTotalPrice =
        (_salePrice * targetRoyaltyInfo.secondaryOnwardsRoyaltyPercentage) /
        feeDenominator();
    }

    // Create array for return
    uint8 count = (_isSecondarySale == 1)
      ? targetRoyaltyInfo.secondaryCount
      : targetRoyaltyInfo.primaryCount;
    address[] memory receivers = new address[](count);
    uint256[] memory royaltyFees = new uint256[](count);

    // Reuse
    count = 0;

    // Find/Calculate (receivers, royaltyFees)
    for (uint256 idx = 0; idx < targetRoyaltyInfo.royaltyList.length; idx++) {
      Royalty memory royalty = targetRoyaltyInfo.royaltyList[idx];
      if (_isSecondarySale == 1) {
        // This is the case of Secondary Sale
        uint16 secondaryPercentage = royalty.secondaryPercentage;
        if (secondaryPercentage != 0) {
          receivers[count] = royalty.receiver;
          royaltyFees[count] =
            (splitTotalPrice * secondaryPercentage) /
            feeDenominator();
          count++;
        }
      } else {
        // This is the case of Primary Sale
        uint16 primaryPercentage = royalty.primaryPercentage;
        if (primaryPercentage != 0) {
          receivers[count] = royalty.receiver;
          royaltyFees[count] =
            (splitTotalPrice * primaryPercentage) /
            feeDenominator();
          count++;
        }
      }
    }

    return (receivers, royaltyFees, royaltyType);
  }

  /**
   * @dev
   * @inheritdoc IERC2981
   *
   */
  function royaltyInfo(
    uint256 /*_tokenId*/,
    uint256 /*_salePrice*/
  ) public view virtual override returns (address, uint256) {
    // EM: RoyaltyRegistry:royaltyInfo not supported yet
    revert("RR:RI:NI");
  }

  /**
   * @dev Validates royalty parameters
   *
   * @param _token address
   * @param _royaltyInfo RoyaltyInfo
   */
  function _validateRoyaltyInfo(
    address _token,
    RoyaltyInfo calldata _royaltyInfo
  ) private view {
    // EM: RoyaltyRegistry:_validateRoyalty _token must be a contract address
    require(_token.isContract(), "RR:VRI:TNC");

    uint8 primaryCount = 0;
    uint8 secondaryCount = 0;
    uint16 primaryTotal = 0;
    uint16 secondaryTotal = 0;
    for (uint256 idx = 0; idx < _royaltyInfo.royaltyList.length; idx++) {
      Royalty memory royalty = _royaltyInfo.royaltyList[idx];
      uint16 primaryPercentage = royalty.primaryPercentage;
      uint16 secondaryPercentage = royalty.secondaryPercentage;

      if (primaryPercentage != 0) {
        primaryCount++;
      }
      if (secondaryPercentage != 0) {
        secondaryCount++;
      }

      primaryTotal += primaryPercentage;
      secondaryTotal += secondaryPercentage;

      // EM: RoyaltyRegistry:_validateRoyalty zero address must not be included in receivers
      require(royalty.receiver != address(0), "RR:VRI:IA");
    }

    // EM: RoyaltyRegistry:_validateRoyaltyInfo overfrow max receivers count
    require(
      primaryCount <= maxRoyaltyReceiversCount &&
        secondaryCount <= maxRoyaltyReceiversCount,
      "RR:VRI:OMRC"
    );

    // EM: RoyaltyRegistry:_validateRoyalty count does not match
    require(
      (primaryCount == _royaltyInfo.primaryCount) &&
        (secondaryCount == _royaltyInfo.secondaryCount),
      "RR:VRI:CNM"
    );

    // EM: RoyaltyRegistry:_validateRoyalty receiversPercentage not 100
    require(
      primaryTotal == feeDenominator() && secondaryTotal == feeDenominator(),
      "RR:VRI:RPN100"
    );

    // EM: RoyaltyRegistry:_validateRoyalty secondaryOnwardsRoyaltyPercentage greater than 100%
    require(
      _royaltyInfo.secondaryOnwardsRoyaltyPercentage <= feeDenominator(),
      "RR:VRI:SOPG100"
    );
  }

  /**
   * @dev Sets the royalty information that all ids in this contract will default to.
   *
   * @param token address
   * @param royaltyInfo_ RoyaltyInfo
   * @param sign bytes calldata
   *
   * Requirements:
   * - caller is an Admin or its called with Admin signature
   */
  function setCollectionDefaultRoyalty(
    address token,
    RoyaltyInfo calldata royaltyInfo_,
    bytes calldata sign
  ) external virtual {
    _validateRoyaltyInfo(token, royaltyInfo_);

    // caller is an Admin or its called with Admin signature
    if (isAdmin(_msgSender()) == false) {
      // Signature validation
      address recoverdAddress = _domainSeparatorV4()
        .toTypedDataHash(_hashRoyaltyInfo(royaltyInfo_))
        .recover(sign);
      require(
        isAdmin(recoverdAddress),
        "RoyaltyRegistry:setCollectionDefaultRoyalty invalid signature"
      );
    }

    _collectionDefaultRoyaltyInfo[token] = royaltyInfo_;

    emit CollectionDefaultRoyaltyInfoSet(token);
  }

  /**
   * @dev Sets the royalty information for a specific token id, overriding the global default.
   *
   * @param token address
   * @param tokenId uint256
   * @param royaltyInfo_ RoyaltyInfo
   *
   * Requirements:
   * - caller is an Admin or its called with Admin signature
   */
  function setTokenRoyalty(
    address token,
    uint256 tokenId,
    RoyaltyInfo calldata royaltyInfo_,
    bytes calldata sign
  ) external virtual {
    _validateRoyaltyInfo(token, royaltyInfo_);
    // EM: RoyaltyRegistry:_setCollectionRoyalty _tokenId can't be zero
    require(tokenId != 0, "RR:SCR:TIDNZ");

    // caller is an Admin or its called with Admin signature
    if (isAdmin(_msgSender()) == false) {
      // Signature validation
      address recoverdAddress = _domainSeparatorV4()
        .toTypedDataHash(_hashRoyaltyInfo(royaltyInfo_))
        .recover(sign);
      require(
        isAdmin(recoverdAddress),
        "RoyaltyRegistry:setTokenRoyalty invalid signature"
      );
    }

    _tokenRoyaltyInfo[token][tokenId] = royaltyInfo_;

    emit TokenRoyaltyInfoSet(token, tokenId);
  }

  /**
   * @dev Removes default royalty information for a collection
   *
   * @param _token address
   */
  function deleteCollectionDefaultRoyalty(
    address _token
  ) external virtual onlyAdmin {
    delete _collectionDefaultRoyaltyInfo[_token];

    emit CollectionDefaultRoyaltyInfoDeleted(_token);
  }

  /**
   * @dev Resets royalty information for the token id back to the global default.
   *
   * @param _token address
   * @param _tokenId uint256
   */
  function resetTokenRoyalty(
    address _token,
    uint256 _tokenId
  ) external virtual onlyAdmin {
    delete _tokenRoyaltyInfo[_token][_tokenId];

    emit TokenRoyaltyInfoReset(_token, _tokenId);
  }
}