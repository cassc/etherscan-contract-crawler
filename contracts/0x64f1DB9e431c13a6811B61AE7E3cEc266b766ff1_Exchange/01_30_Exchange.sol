// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@sbinft/contracts/upgradeable/access/AdminUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "contracts/sbinft/market/v1/interface/IPlatformRegistry.sol";
import "contracts/sbinft/market/v1/interface/ITransferProxy.sol";
import "contracts/sbinft/market/v1/interface/IRoyaltyRegistry.sol";
import "contracts/sbinft/market/v1/interface/IExchange.sol";

/**
 * @dev SBINFT Exchange 2.0
 */
contract Exchange is
  Initializable,
  IExchange,
  EIP712Upgradeable,
  ERC2771ContextUpgradeable,
  AdminUpgradeable,
  ERC165Upgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using ECDSAUpgradeable for bytes32;

  // Fired when PlatformRegistry is changed
  event PlatformRegistryUpdated(IPlatformRegistry indexed platformRegistry);
  // PlatformRegistry holds platform related info
  IPlatformRegistry public platformRegistry;

  // Fired when TransferProxy is changed
  event TransferProxyUpdated(ITransferProxy indexed transferProxy);
  // Holds access rights for on-chain asset transfer.
  // Must be pre approved for the respective asset
  ITransferProxy public transferProxy;

  // Fired when RoyaltyRegistry is changed
  event RoyaltyRegistryUpdated(IRoyaltyRegistry indexed royaltyRegistry);
  // RoyaltyRegistry holds Royalty info
  IRoyaltyRegistry public royaltyRegistry;

  // Map of SaleOrderHash => soldCount
  // Instead of soldCount being uint256 it can be bool but using uint256 inorder to support ERC1155 later
  mapping(bytes32 => uint256) private _saleProgress;

  // Tip related
  struct ERC20Tip {
    address tipper;
    uint256 amount;
  }
  mapping(address => ERC20Tip[]) private _erc20TipDeposite;

  // Just a temp variable to be used as local function variable
  // as mapping declaration is not supported inside function
  mapping(address => uint256) private _tempPayoutAmount;
  address[] private _tempPayoutAddress;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(
    address trustedForwarder
  ) ERC2771ContextUpgradeable(trustedForwarder) {
    _disableInitializers();
  }

  /**
   * @dev Used instead of constructor(must be called once)
   *
   * @param _platformRegistry address of PlatformRegistry
   * @param _royaltyManager address of RoyaltyRegistry
   * @param _transferProxy address of TransferProxy
   *
   * Emits a {PlatformRegistryUpdated} event
   * Emits a {RoyaltyManagerUpdated} event
   * Emits a {TransferProxyUpdated} event
   */
  function __Exchange_init(
    IPlatformRegistry _platformRegistry,
    IRoyaltyRegistry _royaltyManager,
    ITransferProxy _transferProxy
  ) external initializer {
    __ERC165_init();
    AdminUpgradeable.__Admin_init();
    __EIP712_init("SBINFT Exchange", "1.0");
    __Pausable_init();
    __ReentrancyGuard_init();
    __UUPSUpgradeable_init();

    updatePlatformRegistry(_platformRegistry);
    updateRoyaltyRegistry(_royaltyManager);
    updateTransferProxy(_transferProxy);
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
      _interfaceId == type(IExchange).interfaceId ||
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
   * @dev See {PausableUpgradeable._pause()}
   *
   * Requirements:
   * - onlyAdmin can call
   */
  function pause() external onlyAdmin {
    PausableUpgradeable._pause();

    /**
     * Test cases
     * 1. Non Admin call
     */
  }

  /**
   * @dev See {PausableUpgradeable._unpause()}
   *
   * Requirements:
   * - onlyAdmin can call
   */
  function unpause() external onlyAdmin {
    PausableUpgradeable._unpause();

    /**
     * Test cases
     * 1. Non Admin call
     */
  }

  /**
   * @dev Update to new PlatformRegistry
   *
   * @param _newPlatformRegistry new PlatformRegistry
   *
   * Requirements:
   * - _newPlatformRegistry must be a contract and must support IPlatformRegistry
   *
   * Emits a {PlatformRegistryUpdated} event
   */
  function updatePlatformRegistry(
    IPlatformRegistry _newPlatformRegistry
  ) public onlyAdmin {
    // EM: IPlatformRegistry interface not supported
    require(
      IPlatformRegistry(_newPlatformRegistry).supportsInterface(
        type(IPlatformRegistry).interfaceId
      ),
      "E:UPR:INS"
    );

    platformRegistry = _newPlatformRegistry;

    emit PlatformRegistryUpdated(_newPlatformRegistry);
  }

  /**
   * @dev Update to new TransferProxy
   *
   * @param _newTransferProxy new TransferProxy
   *
   * Requirements:
   * - _newTransferProxy must be a contract and must support ITransferProxy
   *
   * Emits a {TransferProxyUpdated} event
   */
  function updateTransferProxy(
    ITransferProxy _newTransferProxy
  ) public onlyAdmin {
    // EM: ITransferProxy interface not supported
    require(
      ITransferProxy(_newTransferProxy).supportsInterface(
        type(ITransferProxy).interfaceId
      ),
      "E:UTP:INS"
    );

    transferProxy = _newTransferProxy;

    emit TransferProxyUpdated(_newTransferProxy);
  }

  /**
   * @dev Update to new RoyaltyRegistry
   *
   * @param _newRoyaltyRegistry new RoyaltyRegistry
   *
   * Requirements:
   * - _newRoyaltyRegistry must be a contract and must support IRoyaltyRegistry
   *
   * Emits a {RoyaltyManagerUpdated} event
   */
  function updateRoyaltyRegistry(
    IRoyaltyRegistry _newRoyaltyRegistry
  ) public onlyAdmin {
    // EM: IRoyaltyRegistry interface not supported
    require(
      IRoyaltyRegistry(_newRoyaltyRegistry).supportsInterface(
        type(IRoyaltyRegistry).interfaceId
      ),
      "E:URR:INS"
    );

    royaltyRegistry = _newRoyaltyRegistry;

    emit RoyaltyRegistryUpdated(_newRoyaltyRegistry);
  }

  /**
   * @dev Checks if order is sold or not
   *
   * @param _saleOrder OrderDomain.SaleOrder order info
   * @return bool true if sold
   */
  function _isSold(
    OrderDomain.SaleOrder calldata _saleOrder
  ) private view returns (bool) {
    return _saleProgress[OrderDomain._hashSaleOrder(_saleOrder)] == 1;
  }

  /**
   * @dev Updates order state as sold
   *
   * @param _saleOrder OrderDomain.SaleOrder order info
   */
  function _setSold(OrderDomain.SaleOrder calldata _saleOrder) private {
    _saleProgress[OrderDomain._hashSaleOrder(_saleOrder)] = 1;
  }

  /**
   * @dev Check validity of arguments when called exchange
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _buyOrder OrderDomain.BuyOrder
   */
  function _checkParameterForExchange(
    OrderDomain.SaleOrder calldata _saleOrder,
    OrderDomain.BuyOrder calldata _buyOrder
  ) private {
    // Make sure asset is not already sold out
    // EM: not enough asset remaining for sale
    require(_isSold(_saleOrder) == false, "E:CPFE:SOLD");

    // Make sure order is not expired
    // EM: Expired Order
    require(_buyOrder.validUntil >= block.timestamp, "E:CPFE:EO");

    // Platform fee rate should be greater than 1%
    // EM: SaleOrder invalid pfSaleFeeRate
    require(
      _saleOrder.pfSaleFeeRate >= (royaltyRegistry.feeDenominator() / 100),
      "E:CPFE:SIPF"
    );

    if (
      _buyOrder.paymentDetails.paymentMode == OrderDomain.ERC20_PAYMENT_MODE
    ) {
      // Whitelist check
      // EM: BuyOrder paymentToken not whitelisted
      require(
        platformRegistry.isWhitelistedERC20(
          _buyOrder.paymentDetails.paymentToken
        ),
        "E:CPFE:BPTNW"
      );
    }

    // OrderDomain.SaleOrder
    // EM: SaleOrder invalid assetList
    require(_saleOrder.assetList.length > 0, "E:CPFE:SIAL");
    // OrderDomain.Asset
    uint256 idx = 0;
    for (idx = 0; idx < _saleOrder.assetList.length; idx++) {
      // EM: SaleOrder asset invalid originKind
      require(
        OrderDomain._isValidOriginKind(_saleOrder.assetList[idx].originKind),
        "E:CPFE:SAIO"
      );
      // EM: SaleOrder asset invalid token
      require(_saleOrder.assetList[idx].token != address(0), "E:CPFE:SAIT");
      // EM: SaleOrder asset invalid tokenId
      require(_saleOrder.assetList[idx].tokenId != 0, "E:CPFE:SAITI");
    }
    // EM: SaleOrder invalid currentOwner
    require(_saleOrder.currentOwner != address(0), "E:CPFE:SICO");
    // EM: SaleOrder invalid paymentReceiver
    require(_saleOrder.paymentReceiver != address(0), "E:CPFE:SIPR");

    // EM: SaleOrder invalid start
    require(
      _saleOrder.start > 0 && _saleOrder.start <= block.timestamp,
      "E:CPFE:SIS"
    );
    // EM: SaleOrder invalid end
    require(
      _saleOrder.end == 0 || _saleOrder.end > block.timestamp,
      "E:CPFE:SIE"
    );
    // EM: SaleOrder invalid nonce
    require(_saleOrder.nonce != 0, "E:CPFE:SIN");

    // OrderDomain.BuyOrder
    // EM: BuyOrder invalid saleNonce
    require(_buyOrder.saleNonce != 0, "E:CPFE:BIS");
    // EM: SaleOrder and BuyOrder nonce does't match
    require(_saleOrder.nonce == _buyOrder.saleNonce, "E:CPFE:SBN");
    // EM: BuyOrder invalid buyer
    require(_buyOrder.buyer != address(0), "E:CPFE:BIB");
    // EM: BuyOrder invalid payer
    require(_buyOrder.payer != address(0), "E:CPFE:BIP");
    // EM: BuyOrder invalid paymentMode
    require(
      OrderDomain._isValidPaymentMode(_buyOrder.paymentDetails.paymentMode),
      "E:CPFE:BIPM"
    );
    // EM: BuyOrder invalid price
    require(_buyOrder.paymentDetails.price != 0, "E:CPFE:BOIP");

    // Mixed cases
    // EM: currentOwner and buyer can't be same
    require(_saleOrder.currentOwner != _buyOrder.buyer, "E:CPFE:CAABS");

    // Check for matching payment mode for Sale and Buy
    bool matchFound = false;
    for (idx = 0; idx < _saleOrder.acceptedPaymentMode.length; idx++) {
      // EM: SaleOrder acceptedPaymentMode invalid paymentMode
      require(
        OrderDomain._isValidPaymentMode(
          _saleOrder.acceptedPaymentMode[idx].paymentMode
        ),
        "E:CPFE:SAPMPM"
      );
      // EM: SaleOrder acceptedPaymentMode invalid price
      require(_saleOrder.acceptedPaymentMode[idx].price != 0, "E:CPFE:SAPMIP");

      if (
        _saleOrder.acceptedPaymentMode[idx].paymentMode ==
        _buyOrder.paymentDetails.paymentMode
      ) {
        matchFound = true;
        break;
      }
    }
    // EM: payment mode did't match
    require(matchFound, "E:CPFE:PMNM");
  }

  /**
   * @dev Verify signatures for calling exchange
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _salerSign saler signature
   * @param _buyOrder OrderDomain.BuyOrder
   * @param _buyerSign buyer signature
   * @param _platformSign platform signature
   */
  function _verifySignaturesForExchange(
    OrderDomain.SaleOrder calldata _saleOrder,
    bytes calldata _salerSign,
    OrderDomain.BuyOrder calldata _buyOrder,
    bytes calldata _buyerSign,
    bytes calldata _platformSign
  ) private view {
    // Prepares ERC712 message hash of Saler signature
    address recoverdAddress = _domainSeparatorV4()
      .toTypedDataHash(OrderDomain._hashSaleOrder(_saleOrder))
      .recover(_salerSign);
    // EM: invalid saler signer
    require(recoverdAddress == _saleOrder.currentOwner, "E:VSE:ISS");

    // Prepares ERC712 message hash of Buyer signature
    bytes32 hashMsgBuyOrder = OrderDomain._hashBuyOrder(_buyOrder);
    recoverdAddress = _domainSeparatorV4()
      .toTypedDataHash(hashMsgBuyOrder)
      .recover(_buyerSign);
    // EM: invalid buyer signer
    require(recoverdAddress == _buyOrder.buyer, "E:VSE:IBS");

    // Prepares ERC712 message hash of platform signature
    recoverdAddress = _domainSeparatorV4()
      .toTypedDataHash(hashMsgBuyOrder)
      .recover(_platformSign);
    // EM: invalid platform signer
    require(platformRegistry.isPlatformSigner(recoverdAddress), "E:VSE:IPS");
  }

  /**
   * @dev Clears previous payout data
   * It is used for collective payment to pay one address only once
   */
  function _resetPayoutTemp() private {
    for (uint256 idx = 0; idx < _tempPayoutAddress.length; idx++) {
      delete _tempPayoutAmount[_tempPayoutAddress[idx]];
    }
    delete _tempPayoutAddress;
  }

  /**
   * @dev Simulate the PartnerFeeTransfer(Not actual transfer)
   *
   * @param _asset OrderDomain.Asset
   * @param _pricePerAsset uint256 price of the asset
   */
  function _simulatePartnerFeeTransfer(
    OrderDomain.Asset memory _asset,
    uint256 _pricePerAsset
  ) private returns (uint256) {
    uint256 partnerFee = 0;

    if (
      OrderDomain._isPartnerOrigin(_asset.originKind) &&
      _asset.partnerFeeRate > 0
    ) {
      address payable partnerFeeReceiver = platformRegistry
        .getPartnerFeeReceiver(_asset.token);
      // Make sure partner fee recever is set
      // EM: partner fee recever is not set
      require(partnerFeeReceiver != address(0), "E:SPFT:PFRNS");

      partnerFee =
        (_pricePerAsset * _asset.partnerFeeRate) /
        royaltyRegistry.feeDenominator();
      _registerPayout(partnerFeeReceiver, partnerFee);
    }

    return partnerFee;
  }

  /**
   * @dev Simulate the PartnerFeeTransfer(Not actual transfer)
   *
   * @param _asset OrderDomain.Asset
   * @param _pricePerAsset uint256 price of the asset
   */
  function _simulateRoyaltyTransfer(
    OrderDomain.Asset memory _asset,
    uint256 _pricePerAsset
  ) private returns (uint256) {
    uint256 totalRoyaltyToSend = 0;

    address[] memory royaltyReceivers;
    uint256[] memory royaltyReceiversCut;
    uint8 royaltyType;
    (royaltyReceivers, royaltyReceiversCut, royaltyType) = royaltyRegistry
      .royaltyInfo(
        _asset.token,
        _asset.tokenId,
        _pricePerAsset,
        _asset.isSecondarySale
      );

    for (uint256 idx = 0; idx < royaltyReceivers.length; idx++) {
      uint256 royaltyReceiverCut = royaltyReceiversCut[idx];

      _registerPayout(royaltyReceivers[idx], royaltyReceiverCut);

      totalRoyaltyToSend += royaltyReceiverCut;
    }

    return totalRoyaltyToSend;
  }

  /**
   * @dev Transfer NFT
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _buyOrder OrderDomain.BuyOrder
   */
  function _transferNFT(
    OrderDomain.SaleOrder calldata _saleOrder,
    OrderDomain.BuyOrder calldata _buyOrder
  ) private {
    for (uint256 idx = 0; idx < _saleOrder.assetList.length; idx++) {
      OrderDomain.Asset memory asset = _saleOrder.assetList[idx];
      transferProxy.erc721safeTransferFrom(
        IERC721(asset.token),
        _saleOrder.currentOwner,
        _buyOrder.buyer,
        asset.tokenId
      );
    }
  }

  /**
   * @dev Payout to all receivers using _tempPayoutAddress and _tempPayoutAmount
   * when execting exchange
   *
   * @param _buyOrder OrderDomain.BuyOrder
   */
  function _payout(OrderDomain.BuyOrder calldata _buyOrder) private {
    bytes4 paymentMode = _buyOrder.paymentDetails.paymentMode;

    for (uint256 idx = 0; idx < _tempPayoutAddress.length; idx++) {
      address payable reciever = payable(_tempPayoutAddress[idx]);
      uint256 amount = _tempPayoutAmount[reciever];

      if (paymentMode == OrderDomain.NATIVE_PAYMENT_MODE) {
        // Sending ETH
        reciever.transfer(amount);
      } else if (paymentMode == OrderDomain.ERC20_PAYMENT_MODE) {
        // Sending ERC20
        transferProxy.erc20safeTransferFrom(
          IERC20(_buyOrder.paymentDetails.paymentToken),
          _buyOrder.payer,
          reciever,
          amount
        );
      }
    }
  }

  /**
   * @dev Register payment locally, to be used in _payout
   *
   * @param _reciever address
   * @param _amount uint256
   */
  function _registerPayout(address _reciever, uint256 _amount) private {
    if (_amount > 0) {
      if (_tempPayoutAmount[_reciever] == 0) {
        _tempPayoutAddress.push(_reciever);
      }
      _tempPayoutAmount[_reciever] += _amount;
    }
  }

  /**
   * @dev See {IExchange.exchange()}
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _salerSign saler signature
   * @param _buyOrder OrderDomain.BuyOrder
   * @param _buyerSign buyer signature
   * @param _platformSign platform signature
   *
   * Requirements:
   * - whenNotPaused
   * - nonReentrant
   *
   * Emits a {Sale} event
   */
  function exchange(
    OrderDomain.SaleOrder calldata _saleOrder,
    bytes calldata _salerSign,
    OrderDomain.BuyOrder calldata _buyOrder,
    bytes calldata _buyerSign,
    bytes calldata _platformSign
  ) external payable virtual override whenNotPaused nonReentrant {
    // Step1 : Parameters and signatures checks
    // Check parameters
    _checkParameterForExchange(_saleOrder, _buyOrder);
    // Verify signatures
    _verifySignaturesForExchange(
      _saleOrder,
      _salerSign,
      _buyOrder,
      _buyerSign,
      _platformSign
    );

    // Step2 : Payout (if OnchainPaymentMode) : Platform Fee + Partner Fee(If partner) + Royalty + Saler(Secondary onwards)
    bytes4 paymentMode = _buyOrder.paymentDetails.paymentMode;
    // OnchainPaymentMode == NATIVE_PAYMENT_MODE || ERC20_PAYMENT_MODE
    if (OrderDomain._isOnchainPaymentMode(paymentMode)) {
      // Payout map is used for collective payment by sending only once for an address
      // So reset it before using it
      _resetPayoutTemp();

      // Sale Price = Platform Fee + Partner Fee(If partner) + Royalty + Saler(Secondary onwards)
      // Find the total sale price by matching payment mode of SaleOrder and BuyOrder
      uint256 totalSalePrice = OrderDomain._findTotalSalePrice(
        _saleOrder,
        _buyOrder
      );

      // Make sure Native Token/ERC20 recieved is enough for sale
      // NOTE: if got more Native Token/ERC20 then needed, it will be stored in this contract(considered as TIP)
      if (paymentMode == OrderDomain.NATIVE_PAYMENT_MODE) {
        // Native Token case
        // EM: not enough Native Token received for sale
        require(msg.value >= totalSalePrice, "E:E:NENT");
        // NOTE: TIP will be added to the balance of this contract
      } else if (paymentMode == OrderDomain.ERC20_PAYMENT_MODE) {
        // ERC20 case
        // NOTE: Make sure appropriate amount of ERC20 is approved to TransferProxy
        address paymentToken = _buyOrder.paymentDetails.paymentToken;
        // EM: not enough ERC20 approved for sale
        uint256 allowanceCount = IERC20(paymentToken).allowance(
          _buyOrder.payer,
          address(transferProxy)
        );
        require(allowanceCount >= totalSalePrice, "E:E:NEERC20");

        // Register TIP
        uint256 tip = allowanceCount - totalSalePrice;
        if (tip > 0) {
          ERC20Tip memory erc20Tip = ERC20Tip(_buyOrder.payer, tip);
          _erc20TipDeposite[paymentToken].push(erc20Tip);
        }
      }

      // Simulate sending platform fee
      uint256 pfFee = (totalSalePrice * _saleOrder.pfSaleFeeRate) /
        royaltyRegistry.feeDenominator();
      _registerPayout(platformRegistry.getPlatformFeeReceiver(), pfFee);

      OrderDomain.Asset[] memory assetList = _saleOrder.assetList;
      // In case of bundle, price of each asset is considerd same.
      // For example: if a bundle has 5 assets and price of buldle is 100 then price of each asset will be 20 (100 / 5)
      uint256 pricePerAsset = totalSalePrice / assetList.length;
      uint256 pfFeePerAsset = pfFee / assetList.length;
      address paymentReceiver = _saleOrder.paymentReceiver;

      for (uint256 idx = 0; idx < assetList.length; idx++) {
        OrderDomain.Asset memory asset = assetList[idx];
        // Simulate sending partner fee
        uint256 partnerFeePerAsset = _simulatePartnerFeeTransfer(
          asset,
          pricePerAsset
        );

        uint256 royaltySplitPricePerAsset = 0;
        if (OrderDomain._isSecondarySale(asset.isSecondarySale)) {
          // Secondary onwards sale case
          royaltySplitPricePerAsset = pricePerAsset;
        } else {
          // Primary sale case
          royaltySplitPricePerAsset =
            pricePerAsset -
            pfFeePerAsset -
            partnerFeePerAsset;
        }
        // Simulate sending royalty cut
        uint256 royaltyFeePerAsset = _simulateRoyaltyTransfer(
          asset,
          royaltySplitPricePerAsset
        );

        // Simulate sending Saler(Secondary onwards) cut
        if (OrderDomain._isSecondarySale(asset.isSecondarySale)) {
          uint256 toSalerPerAsset = pricePerAsset -
            pfFeePerAsset -
            partnerFeePerAsset -
            royaltyFeePerAsset;
          _registerPayout(paymentReceiver, toSalerPerAsset);
        }
      }

      // Payout
      _payout(_buyOrder);
      _resetPayoutTemp();
    }

    // Step3 : Transfer NFT
    _transferNFT(_saleOrder, _buyOrder);

    // Step4 : Mark order as sold
    _setSold(_saleOrder);

    // Step5 : Emit event for sale
    // TODO: If needed add more data in the event
    emit Sale(_buyOrder.saleNonce);
  }

  /**
   * @dev Verify signatures for calling cancel
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _salerSign saler signature
   * @param _platformSign platform signature
   */
  function _verifySignaturesForCancel(
    OrderDomain.SaleOrder calldata _saleOrder,
    bytes calldata _salerSign,
    bytes calldata _platformSign
  ) private view {
    // Prepares ERC712 message hash of Saler signature
    bytes32 hashMsgSaleOrder = OrderDomain._hashSaleOrder(_saleOrder);
    address recoverdAddress = _domainSeparatorV4()
      .toTypedDataHash(hashMsgSaleOrder)
      .recover(_salerSign);
    // EM: invalid saler signer
    require(recoverdAddress == _saleOrder.currentOwner, "E:VSC:ISS");

    // Prepares ERC712 message hash of platform signature
    recoverdAddress = _domainSeparatorV4()
      .toTypedDataHash(hashMsgSaleOrder)
      .recover(_platformSign);
    // EM: invalid platform signer
    require(platformRegistry.isPlatformSigner(recoverdAddress), "E:VSC:IPS");
  }

  /**
   * @dev Cancel a sale order
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _salerSign saler signature
   * @param _platformSign platform signature
   *
   * Emits a {OrderCancelled} event
   */
  function cancel(
    OrderDomain.SaleOrder calldata _saleOrder,
    bytes calldata _salerSign,
    bytes calldata _platformSign
  ) external virtual override nonReentrant whenNotPaused {
    _verifySignaturesForCancel(_saleOrder, _salerSign, _platformSign);

    // Mark order as sold
    _setSold(_saleOrder);

    // Emit event for OrderCancelled
    // TODO: If needed add more data in the event
    emit OrderCancelled(_saleOrder.nonce);
  }

  /**
   * @dev Withdraw Tip
   *
   * @param _receiver address payable
   * @param _erc20Token address. When Native, address is zero.
   */
  function withdrawTip(
    address payable _receiver,
    address _erc20Token
  ) public onlyAdmin {
    // EM: Invalid withdraw address
    require(_receiver != address(0), "E:WT:IRA");

    if (_erc20Token == address(0)) {
      // Native tip withdraw
      _receiver.transfer(address(this).balance);
    } else {
      // ERC20 tip withdrawal
      ERC20Tip[] storage erc20TipList = _erc20TipDeposite[_erc20Token];

      for (uint256 idx = 0; idx < erc20TipList.length; idx++) {
        ERC20Tip storage erc20Tip = erc20TipList[idx];
        // Sending ERC20
        transferProxy.erc20safeTransferFrom(
          IERC20(_erc20Token),
          erc20Tip.tipper,
          _receiver,
          erc20Tip.amount
        );
      }

      // Clear tip info after transfer
      delete _erc20TipDeposite[_erc20Token];
    }
  }

  // fallback() external payable {}
}