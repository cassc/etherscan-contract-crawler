// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBConstants.sol';
import '../../libraries/JBTokens.sol';
import '../../structs/JBSplit.sol';

import '../Utils/JBSplitPayerUtil.sol';

interface IFixedPriceSale {
  event CreateFixedPriceSale(
    address seller,
    IERC721 collection,
    uint256 item,
    uint256 price,
    uint256 expiration,
    string memo
  );

  event ConcludeFixedPriceSale(
    address seller,
    address buyer,
    IERC721 collection,
    uint256 item,
    uint256 closePrice,
    string memo
  );

  error SALE_EXISTS();
  error INVALID_SALE();
  error SALE_ENDED();
  error SALE_IN_PROGRESS();
  error INVALID_PRICE();
  error INVALID_DURATION();
  error INVALID_FEERATE();
  error NOT_AUTHORIZED();

  function create(
    IERC721 _collection,
    uint256 _item,
    uint256 _price,
    uint256 _duration,
    JBSplit[] calldata _saleSplits,
    string calldata _memo
  ) external;

  function takeOffer(IERC721, uint256, string calldata) external payable;

  function distributeProceeds(IERC721, uint256) external;

  function currentPrice(IERC721, uint256) external view returns (uint256);

  function updateSaleSplits(IERC721, uint256, JBSplit[] calldata) external;

  function setFeeRate(uint256) external;

  function setAllowPublicSales(bool) external;

  function setFeeReceiver(IJBPaymentTerminal) external;

  function addAuthorizedSeller(address) external;

  function removeAuthorizedSeller(address) external;
}

struct SaleData {
  address seller;
  /** @notice Bit-packed price (96bits) and expiration seconds offset (64bits) */
  uint256 condition;
  /** @notice Sale price (96bits) */
  uint256 sale;
}

contract FixedPriceSale is
  AccessControl,
  JBSplitPayerUtil,
  ReentrancyGuard,
  IFixedPriceSale,
  Initializable
{
  bytes32 public constant AUTHORIZED_SELLER_ROLE = keccak256('AUTHORIZED_SELLER_ROLE');

  /**
   * @notice Fee rate cap set to 10%.
   */
  uint256 public constant FEE_RATE_CAP = 100000000;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
   * @notice Collection of active sales.
   */
  mapping(bytes32 => SaleData) public sales;

  /**
   * @notice Juicebox splits for active sales.
   */
  mapping(bytes32 => JBSplit[]) public saleSplits;

  /**
   * @notice Timestamp of contract deployment, used as sale expiration offset to reduce the number of bits needed to store sale expiration.
   */
  uint256 public deploymentOffset;

  uint256 public projectId;
  IJBPaymentTerminal public feeReceiver;
  IJBDirectory public directory;
  uint256 public settings; // allowPublicSales(bool), feeRate (32)

  /**
   * @notice Contract initializer to make deployment more flexible.
   *
   * @param _projectId Project that manages this sales contract.
   * @param _feeReceiver An instance of IJBPaymentTerminal which will get sale fees.
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1000000000).
   * @param _allowPublicSales A flag to allow anyone to create a sale on this contract rather than only accounts with the `AUTHORIZED_SELLER_ROLE` permission.
   * @param _owner Contract admin. Granted admin and seller roles.
   * @param _directory JBDirectory instance to enable JBX integration.
   *
   * @dev feeReceiver.addToBalanceOf will be called to send fees.
   */
  function initialize(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicSales,
    address _owner,
    IJBDirectory _directory
  ) public initializer {
    deploymentOffset = block.timestamp;

    projectId = _projectId;
    feeReceiver = _feeReceiver;
    settings = setBoolean(_feeRate, 32, _allowPublicSales);
    directory = _directory;

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(AUTHORIZED_SELLER_ROLE, _owner);
  }

  /**
   * @notice Creates a new sale listing for an item from an ERC721 collection.
   *
   * @dev _price must fit into uint96, expiration is 64 bit.
   *
   * @dev WARNING, if using a JBSplits collection, make sure each of the splits is properly configured. The default project and default receiver during split processing is set to 0 and will therefore result in loss of funds if the split doesn't provide sufficient instructions.
   *
   * @param _collection ERC721 contract.
   * @param _item Token id to list.
   * @param _price Sale price at which the sale can be completed.
   * @param _duration Seconds from block time at which the sale concludes.
   * @param _saleSplits Juicebox splits collection that will receive sale proceeds.
   * @param _memo Text to publish as part of the creation event.
   */
  function create(
    IERC721 _collection,
    uint256 _item,
    uint256 _price,
    uint256 _duration,
    JBSplit[] calldata _saleSplits,
    string calldata _memo
  ) external override nonReentrant {
    if (!getBoolean(settings, 32)) {
      if (!hasRole(AUTHORIZED_SELLER_ROLE, msg.sender)) {
        revert NOT_AUTHORIZED();
      }
    }

    bytes32 saleId = keccak256(abi.encodePacked(address(_collection), _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller != address(0)) {
      revert SALE_EXISTS();
    }

    if (_price > type(uint96).max) {
      revert INVALID_PRICE();
    }

    uint256 expiration = block.timestamp - deploymentOffset + _duration;

    if (expiration > type(uint64).max) {
      revert INVALID_DURATION();
    }

    {
      // scope to reduce stack depth
      uint256 saleCondition = uint256(uint96(_price));
      saleCondition |= uint256(uint64(expiration)) << 96;

      sales[saleId] = SaleData(msg.sender, saleCondition, 0);
    }

    uint256 length = _saleSplits.length;
    for (uint256 i; i != length; ) {
      saleSplits[saleId].push(_saleSplits[i]);
      unchecked {
        ++i;
      }
    }

    _collection.transferFrom(msg.sender, address(this), _item);

    emit CreateFixedPriceSale(msg.sender, _collection, _item, _price, expiration, _memo);
  }

  /**
   * @notice Completes the sale if during validity period by either sending the item to the buyer or sending it back to the seller in the event that the sale period ended.
   *
   * @param collection ERC721 contract.
   * @param item Token id to settle.
   */
  function takeOffer(
    IERC721 collection,
    uint256 item,
    string calldata _memo
  ) external payable override nonReentrant {
    bytes32 saleId = keccak256(abi.encodePacked(collection, item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = uint256(uint64(saleDetails.condition >> 96));
    if (block.timestamp > deploymentOffset + expiration) {
      revert SALE_ENDED();
    }

    uint256 expectedPrice = uint256(uint96(saleDetails.condition));
    if (msg.value >= expectedPrice) {
      sales[saleId].sale = msg.value;

      collection.transferFrom(address(this), msg.sender, item);

      emit ConcludeFixedPriceSale(
        saleDetails.seller,
        msg.sender,
        collection,
        item,
        msg.value,
        _memo
      );
    }
  }

  /**
   * @notice This trustless method removes the burden of distributing sale proceeds to the seller-configured splits from the buyer (or anyone else) calling settle(). The call will iterate saleSplits for a given sale or send the proceeds to the seller account.
   */
  function distributeProceeds(IERC721 _collection, uint256 _item) external override nonReentrant {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = uint256(uint64(saleDetails.condition >> 96));
    if (block.timestamp < deploymentOffset + expiration) {
      if (saleDetails.sale == 0) {
        revert SALE_IN_PROGRESS();
      }
    }

    if (saleDetails.sale == 0) {
      _collection.transferFrom(address(this), saleDetails.seller, _item);

      delete sales[saleId];
      delete saleSplits[saleId];

      emit ConcludeFixedPriceSale(saleDetails.seller, address(0), _collection, _item, 0, '');

      return;
    }

    uint256 saleAmount = uint256(uint96(saleDetails.sale));

    if (uint32(settings) != 0) {
      // feeRate > 0
      uint256 fee = PRBMath.mulDiv(saleAmount, uint32(settings), JBConstants.SPLITS_TOTAL_PERCENT);
      feeReceiver.addToBalanceOf{value: fee}(projectId, fee, JBTokens.ETH, '', '');

      unchecked {
        saleAmount -= fee;
      }
    }

    delete sales[saleId];

    if (saleSplits[saleId].length != 0) {
      saleAmount = payToSplits(
        saleSplits[saleId],
        saleAmount,
        JBTokens.ETH,
        18,
        directory,
        0,
        payable(address(0))
      );
      delete saleSplits[saleId];

      if (saleAmount > 0) {
        // in case splits don't cover 100%, transfer remainder to seller
        payable(saleDetails.seller).transfer(saleAmount);
      }
    } else {
      payable(saleDetails.seller).transfer(saleAmount);
    }
  }

  /**
   * @notice Returns the number of seconds to the end of the sale for a given item.
   */
  function timeLeft(IERC721 _collection, uint256 _item) public view returns (uint256) {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = deploymentOffset + uint256(uint64(saleDetails.condition >> 96));

    if (block.timestamp > expiration) {
      return 0;
    }

    return expiration - block.timestamp;
  }

  /**
   * @notice Returns current bid for a given item even if it is below the reserve.
   */
  function currentPrice(
    IERC721 _collection,
    uint256 _item
  ) public view override returns (uint256 price) {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = deploymentOffset + uint256(uint64(saleDetails.condition >> 96));
    if (block.timestamp > expiration) {
      price = 0;
    } else {
      price = uint256(uint96(saleDetails.condition));
    }
  }

  /**
   * @notice A way to update sale splits in case current configuration cannot be processed correctly. Can only be executed by the seller address. Setting an empty collection will send sale proceeds, less fee, to the seller account.
   */
  function updateSaleSplits(
    IERC721 _collection,
    uint256 _item,
    JBSplit[] calldata _saleSplits
  ) external override {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    if (saleDetails.seller != msg.sender) {
      revert NOT_AUTHORIZED();
    }

    delete saleSplits[saleId];

    uint256 length = _saleSplits.length;
    for (uint256 i; i != length; ) {
      saleSplits[saleId].push(_saleSplits[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Change fee rate, admin only.
   *
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1_000_000_000).
   */
  function setFeeRate(uint256 _feeRate) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_feeRate > FEE_RATE_CAP) {
      revert INVALID_FEERATE();
    }

    settings |= uint256(uint32(_feeRate));
  }

  /**
   * @notice Sets or clears the flag to enable users other than admin role to create sales.
   */
  function setAllowPublicSales(
    bool _allowPublicSales
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    settings = setBoolean(settings, 32, _allowPublicSales);
  }

  /**
   * @param _feeReceiver JBX terminal to send fees to.
   *
   * @dev addToBalanceOf on the feeReceiver will be called to send fees.
   */
  function setFeeReceiver(
    IJBPaymentTerminal _feeReceiver
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    feeReceiver = _feeReceiver;
  }

  function addAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function removeAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
    return
      _interfaceId == type(IFixedPriceSale).interfaceId || super.supportsInterface(_interfaceId);
  }

  // TODO: consider admin functions to recover eth & token balances

  //*********************************************************************//
  // ------------------------------ utils ------------------------------ //
  //*********************************************************************//

  function getBoolean(uint256 _source, uint256 _index) internal pure returns (bool) {
    uint256 flag = (_source >> _index) & uint256(1);
    return (flag == 1 ? true : false);
  }

  function setBoolean(
    uint256 _source,
    uint256 _index,
    bool _value
  ) internal pure returns (uint256 update) {
    if (_value) {
      update = _source | (uint256(1) << _index);
    } else {
      update = _source & ~(uint256(1) << _index);
    }
  }
}