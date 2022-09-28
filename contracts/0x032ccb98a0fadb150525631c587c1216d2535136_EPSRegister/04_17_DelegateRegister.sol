// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IDelegationContainer.sol";
import "./IEPSDelegateRegister.sol";

/**
 *
 * @dev The EPS Delegation Register contract. This contract is part of the EPSRegister, and allows the owner
 * of an ERC721 to delegate rights to another address (the delegate address). The owner decides what rights
 * they wish to delegate, how long for, and if they require payment for the delegation. For example, a holder
 * might decide that they wish to delegate physical event rights to another for three months. They want 0.5 ETH
 * for this privelidge. They load the delegation here, with the asset being custodied in a delegation container
 * that the original asset owner owns. Other addresses can accept that delegation proposal by paying the ETH
 * due. This loads the delegation details to the register, and means that query functions like beneficiaryOf and
 * beneficiaryBalanceOf return data that reflect this delegation.
 *
 */

contract DelegateRegister is IEPSDelegateRegister, Ownable, IERC721Receiver {
  using Clones for address payable;

  // =======================================
  // CONSTANTS
  // =======================================

  // Total rights, positions 13, 14 and 15 reserved for project specific rights.
  uint256 constant TOTAL_RIGHTS =
    10000100001000010000100001000010000100001000010000100001000010000100001;
  //15   14   13   12   11   10   9    8    7    6    5    4    3    2    1

  // Rights slice length - this is used in run time to slice up rights integers into their component parts.
  uint256 constant RIGHTS_SLICE_LENGTH = 5;

  // Default for any percentages, which must be held as a prortion of 100,000, i.e. a
  // percentage of 5% is held as 5,000.
  uint256 constant PERCENTAGE_DENOMINATOR = 100000;

  address immutable weth;

  // =======================================
  // STORAGE
  // =======================================

  // Unique ID for every proposed delegation.
  uint64 public delegationId;

  // Unique ID for every collection offer.
  uint64 public offerId;

  // Basic fee charged by the protocol for operations that require payment, namely the acceptance of a delegation
  // or the secondary sale of rights.
  uint96 public delegationRegisterFee;

  // Percentage fee applied to proceeds derived from protocol actions. For example, if this is set to 0.5% (500) and
  // an asset owner has charged 1 ETH for a delegation this will be a charge of 0.005 ETH. Note that this is charged in
  // addition to the base fee. This is important, as the base fee is all the protocol will take for fee free transactions,
  // and some revenue is required to maintain the service.
  uint32 public delegationFeePercentage;

  // The string descriptions associated with the default rights codes. Only position 1 to 12 will be used, but full length
  // provided here for future flexiblity
  string[16] public defaultRightsCodes;

  // Lock for delegation container address
  bool public delegationContainerTemplateLocked;

  // Provide ability to pause new sales (in-ife functionality including asset reclaim cannot be paused)
  bool public marketplacePaused;

  struct DelegationRecord {
    // The unique identifier for every delegation. Note that this is stamped on each delegation container. This doesn't mean
    // that every delegation Id will make it to the register, as this might be a proposed delegation that is not taken
    // up by anyone.
    uint64 delegationId; // 64
    // The owner of the asset that is being containerised for delegation.
    address owner; // 160
    // The end time for this delegation. After the end time the owner can remove the asset.
    uint64 endTime; // 64
    // The address of the delegate for this delegation
    address delegate; // 160
    // Delegate rights integer:
    uint256 delegateRightsInteger;
  }

  struct DelegationParameters {
    // The provider who has originated this delegation.
    uint64 provider; // 64
    // The address proposed as deletage. The owner of an asset can specify a particular address OR they can leave
    // this as address 0 if they will accept any delegate, subject to payment of the fee (if any)
    address delegate; // 160
    // The duration of the delegation.
    uint24 duration; // 24
    // The fee that the delegate must pay for this delegation to go live.
    uint96 fee; // 96
    // Owner rights integer:
    uint256 ownerRightsInteger;
    // Delegate rights integer:
    uint256 delegateRightsInteger;
    // URI
    string URI;
    // Offer ID, passed if this is accepting an offer, otherwise will be 0:
    uint64 offerId;
  }

  struct Offer {
    // Slot 1 160 + 24 + 32 + 8 = 224
    // The address that is making the offer
    address offerMaker; // 160
    // The delegation duration time in days for this offer.
    uint24 delegationDuration; //24
    // When this offer expires
    uint32 expiry; // 32
    // Boolean to note a collection offer
    bool collectionOffer; // 8
    // Slot 2 160 + 96 = 256
    // The collection the offer is for
    address collection;
    // Offer amount (in provided ERC)
    uint96 offerAmount;
    // Slot 3 = 256
    // TokenId, (is ignored for collection offers)
    uint256 tokenId;
    // Slot 4 = 256
    // Delegate rights integer that they are requesting:
    uint256 delegateRightsInteger;
    // ERC20 that they are paying in:
    address paymentERC20;
  }

  // Configurable payment options for offers:
  struct ERC20PaymentOptions {
    bool isValid;
    uint96 registerFee;
  }

  // The address of the delegation container template.
  address payable public delegationContainer;

  // Map a tokenContract and Id to a delegation record.
  // bytes32 mapping for this is tokenContract and tokenId
  mapping(bytes32 => DelegationRecord) public tokenToDelegationRecord;

  // Map a token contract and query address to a balance struct:
  // bytes32 mapping for this is tokenContract and address being queried
  mapping(bytes32 => uint256) public contractToBalanceByRights;

  // Map a deployed container contract to a delegation record.
  mapping(address => uint64) public containerToDelegationId;

  // Map a token contract to a listing of contract specific rights codes:
  mapping(address => string[16]) public tokenContractToRightsCodes;

  // Map collection offer ID to offer:
  mapping(uint64 => Offer) public offerIdToOfferDetails;

  // Store offer ERC20 payment options, the returned value if the base fee for that ERC20
  mapping(address => ERC20PaymentOptions) public validERC20PaymentOption;

  /**
   *
   * @dev Constructor
   *
   */
  constructor(
    uint96 delegationRegisterFee_,
    uint32 delegationFeePercentage_,
    address weth_
  ) {
    delegationRegisterFee = delegationRegisterFee_;
    delegationFeePercentage = delegationFeePercentage_;
    weth = weth_;
  }

  // =======================================
  // GETTERS
  // =======================================

  /**
   *
   * @dev getFeeDetails: Get fee details (register fee and fee percentage).
   *
   */
  function getFeeDetails()
    external
    view
    returns (uint96 delegationRegisterFee_, uint32 delegationFeePercentage_)
  {
    return (delegationRegisterFee, delegationFeePercentage);
  }

  /**
   *
   * @dev getDelegationIdForContainer: Get delegation ID for a given container.
   *
   */
  function getDelegationIdForContainer(address container_)
    external
    view
    returns (uint64 delegationId_)
  {
    return (containerToDelegationId[container_]);
  }

  /**
   *
   * @dev getBalanceByRight: Get balance by rights
   *
   */
  function getBalanceByRight(
    address tokenContract_,
    address queryAddress_,
    uint256 rightsIndex_
  ) public view returns (uint256) {
    // Create the hash for this contract and address combination:

    bytes32 queryHash = _getParticipantHash(tokenContract_, queryAddress_);

    return (
      _sliceRightsInteger(rightsIndex_, contractToBalanceByRights[queryHash])
    );
  }

  /**
   *
   * @dev getBeneficiaryByRight: Get beneficiary by rights
   *
   */
  function getBeneficiaryByRight(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) public view returns (address) {
    bytes32 keyHash = _getKeyHash(tokenContract_, tokenId_);

    DelegationRecord memory currentRecord = tokenToDelegationRecord[keyHash];

    // Check for delegation

    if (currentRecord.delegationId != 0) {
      if (
        _sliceRightsInteger(
          rightsIndex_,
          currentRecord.delegateRightsInteger
        ) == 0
      ) {
        // Owner has the rights
        return (currentRecord.owner);
      } else {
        // Delegate has the rights
        return (currentRecord.delegate);
      }
    }

    // Return 0 if there is nothing stored here.
    return (address(0));
  }

  // =======================================
  // SETTERS
  // =======================================

  /**
   * @dev addOfferPaymentERC20: add an offer ERC20 payment option
   */
  function addOfferPaymentERC20(address contractForERC20_, uint96 baseFee_)
    public
    onlyOwner
  {
    validERC20PaymentOption[contractForERC20_].isValid = true;
    validERC20PaymentOption[contractForERC20_].registerFee = baseFee_;
  }

  /**
   * @dev removeOfferPaymentERC20: remove an offer ERC20 payment option
   */
  function removeOfferPaymentERC20(address contractForERC20_) public onlyOwner {
    delete validERC20PaymentOption[contractForERC20_];
  }

  /**
   * @dev setDefaultRightsCodes: set the string description for the 12 defauls rights codes. Note this is for information only - these strings are
   * not used in the contract for any purpose.
   */
  function setDefaultRightsCodes(
    uint256 rightsIndex_,
    string memory rightsDescription_
  ) public onlyOwner {
    defaultRightsCodes[rightsIndex_] = rightsDescription_;
  }

  /**
   * @dev setProjectSpecificRightsCodes: set the string description for the 3 configurable rights codes that can be set per token contract. These
   * occupy positions 13, 14 and 15 on the rights index. These may be seldom used, but the idea is to give projects three positions in the rights
   * integer where they can determine their own authorities.
   */
  function setProjectSpecificRightsCodes(
    address tokenContract_,
    uint256 rightsIndex_,
    string memory rightsDescription_
  ) public onlyOwner {
    tokenContractToRightsCodes[tokenContract_][
      rightsIndex_
    ] = rightsDescription_;
  }

  /**
   * @dev setDelegationRegisterFee: set the base fee for transactions.
   */
  function setDelegationRegisterFee(uint96 delegationRegisterFee_)
    public
    onlyOwner
  {
    delegationRegisterFee = delegationRegisterFee_;
  }

  /**
   * @dev setDelegationFeePercentage: set the percentage fee taken from transactions that involve payment.
   */
  function setDelegationFeePercentage(uint32 delegationFeePercentage_)
    public
    onlyOwner
  {
    delegationFeePercentage = delegationFeePercentage_;
  }

  /**
   * @dev lockDelegationContainerTemplate: allow the delegation container template to be locked at a given address.
   */
  function lockDelegationContainerTemplate() public onlyOwner {
    delegationContainerTemplateLocked = true;
  }

  /**
   *
   * @dev setDelegationContainer: set the container address. Can only be called once. Not set in the constructor
   * as the container needs to know the address of the register (which IS set in the constructor)
   * so we have a chicken and egg situation to resolve. Only allow to be set ONCE.
   *
   */
  function setDelegationContainer(address payable delegationContainer_)
    public
    onlyOwner
  {
    if (delegationContainerTemplateLocked) revert TemplateContainerLocked();
    delegationContainer = delegationContainer_;
  }

  /**
   * @dev toggleMarketplace: allow the marketplace to be paused / unpaused
   */
  function pauseMarketplace(bool marketPlacePaused) public onlyOwner {
    marketplacePaused = marketPlacePaused;
  }

  // =======================================
  // VALIDATION
  // =======================================

  /**
   * @dev Throws if this is not a valid container, returnds delegation Id if it's valid.
   */
  function isValidContainer(address container_)
    public
    view
    returns (uint64 recordId_)
  {
    recordId_ = containerToDelegationId[container_];

    if (recordId_ == 0) revert InvalidContainer();

    return (recordId_);
  }

  /**
   * @dev Throws if marketplace is not open
   */
  function _isMarketOpen() internal view {
    if (marketplacePaused) revert MarketPlacePaused();
  }

  // =======================================
  // RIGHTS 'BOOKKEEPING'
  // =======================================

  /**
   *
   * @dev _increaseRightsInteger: increase the passed rights integer with the passed integer
   *
   */
  function _increaseRightsInteger(
    address containerAddress_,
    address participantAddress_,
    address tokenContract_,
    uint256 tokenId_,
    bytes32 participantHash_,
    uint256 rightsInteger_
  ) internal {
    contractToBalanceByRights[participantHash_] += rightsInteger_;

    // An increase of rights is implicitly a transfer from the container that holds the asset:
    emit TransferRights(
      containerAddress_,
      participantAddress_,
      tokenContract_,
      tokenId_,
      rightsInteger_
    );
  }

  /**
   *
   * @dev _decreaseRightsInteger: decrease the passed rights integer with the passed integer
   *
   */
  function _decreaseRightsInteger(
    address containerAddress_,
    address participantAddress_,
    address tokenContract_,
    uint256 tokenId_,
    bytes32 participantHash_,
    uint256 rightsInteger_
  ) internal {
    contractToBalanceByRights[participantHash_] -= rightsInteger_;

    // An decrease of rights is implicitly a transfer to the container that holds the asset:
    emit TransferRights(
      participantAddress_,
      containerAddress_,
      tokenContract_,
      tokenId_,
      rightsInteger_
    );
  }

  /**
   *
   * @dev _adjustBalancesAtEndOfDelegation: reduce balances when a delegation has ended
   *
   */
  function _adjustBalancesAtEndOfDelegation(
    address tokenContract_,
    address container_,
    address owner_,
    address delegate_,
    uint256 tokenId_,
    uint64 delegationId_
  ) internal returns (bytes32 keyHash_, bytes32 ownerHash_) {
    (bytes32 keyHash, bytes32 ownerHash, bytes32 delegateHash) = _getAllHashes(
      tokenContract_,
      tokenId_,
      owner_,
      delegate_
    );

    _decreaseRightsInteger(
      container_,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      (TOTAL_RIGHTS - tokenToDelegationRecord[keyHash].delegateRightsInteger)
    );

    _decreaseRightsInteger(
      container_,
      delegate_,
      tokenContract_,
      tokenId_,
      delegateHash,
      tokenToDelegationRecord[keyHash].delegateRightsInteger
    );

    // Emit event to show that this delegation is now
    _emitComplete(delegationId_);

    return (keyHash, ownerHash);
  }

  // =======================================
  // DELEGATION RECORDS MANAGEMENT
  // =======================================

  /**
   *
   * @dev _assignDelegationId: Create new delegation Id and assign it.
   *
   */
  function _assignDelegationId(address container_) internal {
    delegationId += 1;

    containerToDelegationId[container_] = delegationId;
  }

  /**
   *
   * @dev _resetDelegationRecordDetails: reset to default on relist
   *
   */
  function _resetDelegationRecordDetails(bytes32 keyHash_) internal {
    _updateDelegationRecordDetails(keyHash_, 0, address(0), 0);
  }

  /**
   *
   * @dev _updateDelegationRecordDetails: common processing for delegation record updates
   *
   */
  function _updateDelegationRecordDetails(
    bytes32 keyHash_,
    uint64 endTime_,
    address delegate_,
    uint256 delegateRightsInteger_
  ) internal {
    tokenToDelegationRecord[keyHash_].endTime = endTime_;
    tokenToDelegationRecord[keyHash_].delegate = delegate_;
    tokenToDelegationRecord[keyHash_]
      .delegateRightsInteger = delegateRightsInteger_;
  }

  /**
   *
   * @dev _getAllHashes: get the hashes for tracking owner and delegate
   *
   */
  function _getAllHashes(
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_
  )
    internal
    pure
    returns (
      bytes32 keyHash_,
      bytes32 ownerHash_,
      bytes32 delegateHash_
    )
  {
    (keyHash_, ownerHash_) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      owner_
    );

    delegateHash_ = keccak256(abi.encodePacked(tokenContract_, delegate_));

    return (keyHash_, ownerHash_, delegateHash_);
  }

  /**
   *
   * @dev _getKeyAndParticipantHashes: get key and one participant hashes
   *
   */
  function _getKeyAndParticipantHashes(
    address tokenContract_,
    uint256 tokenId_,
    address participant_
  ) internal pure returns (bytes32 keyHash_, bytes32 participantHash_) {
    keyHash_ = _getKeyHash(tokenContract_, tokenId_);

    participantHash_ = _getParticipantHash(tokenContract_, participant_);

    return (keyHash_, participantHash_);
  }

  /**
   *
   * @dev _getParticipantHash: get one participant hash
   *
   */
  function _getParticipantHash(address tokenContract_, address participant_)
    internal
    pure
    returns (bytes32 participantHash_)
  {
    participantHash_ = keccak256(
      abi.encodePacked(tokenContract_, participant_)
    );

    return (participantHash_);
  }

  /**
   *
   * @dev _getKeyHash: get key hash
   *
   */
  function _getKeyHash(address tokenContract_, uint256 tokenId_)
    internal
    pure
    returns (bytes32 keyHash_)
  {
    keyHash_ = keccak256(abi.encodePacked(tokenContract_, tokenId_));

    return (keyHash_);
  }

  /**
   *
   * @dev _sliceRightsInteger: extract a position from the rights integer
   *
   */
  function _sliceRightsInteger(uint256 position_, uint256 rightsInteger_)
    internal
    pure
    returns (uint256 value)
  {
    uint256 exponent = (10**(position_ * RIGHTS_SLICE_LENGTH));
    uint256 divisor;
    if (position_ == 1) {
      divisor = 1;
    } else {
      divisor = (10**((position_ - 1) * RIGHTS_SLICE_LENGTH));
    }

    return ((rightsInteger_ % exponent) / divisor);
  }

  /**
   *
   * @dev sundryEvent: generic function for delegation register emits
   *
   */
  function sundryEvent(
    uint64 provider_,
    address address1_,
    address address2_,
    uint256 int1_,
    uint256 int2_,
    uint256 int3_,
    uint256 int4_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit a sundry event so we know about it:
    emit SundryEvent(
      provider_,
      recordId,
      address1_,
      address2_,
      int1_,
      int2_,
      int3_,
      int4_
    );
  }

  // =======================================
  // DELEGATION CREATION
  // =======================================

  /**
   *
   * @dev _createDelegationFromOffer: call when an offer is being accepted
   *_createDelegation
   */
  function _createDelegationFromOffer(
    DelegationParameters memory delegationData_,
    uint256 tokenId_,
    address owner_,
    bytes32 keyHash_,
    bytes32 ownerHash_,
    address tokenContract_,
    address container_
  ) internal {
    _offerAccepted(delegationData_, tokenId_, owner_, tokenContract_);

    _createDelegation(
      owner_,
      uint64(block.timestamp) + (uint64(delegationData_.duration) * 1 days),
      delegationData_.delegate,
      delegationData_.delegateRightsInteger,
      keyHash_
    );

    _increaseRightsInteger(
      container_,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash_,
      (TOTAL_RIGHTS - delegationData_.delegateRightsInteger)
    );

    _increaseRightsInteger(
      container_,
      delegationData_.delegate,
      tokenContract_,
      tokenId_,
      _getParticipantHash(tokenContract_, delegationData_.delegate),
      delegationData_.delegateRightsInteger
    );

    _emitDelegationAccepted(
      delegationData_,
      container_,
      tokenContract_,
      tokenId_,
      owner_
    );
  }

  /**
   *
   * @dev _emitDelegationAccepted
   *
   */
  function _emitDelegationAccepted(
    DelegationParameters memory delegationData_,
    address container_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_
  ) internal {
    emit DelegationAccepted(
      delegationData_.provider,
      delegationId,
      container_,
      tokenContract_,
      tokenId_,
      owner_,
      delegationData_.delegate,
      uint64(block.timestamp) + (uint64(delegationData_.duration) * 1 days),
      delegationData_.delegateRightsInteger,
      0,
      delegationData_.URI
    );
  }

  /**
   *
   * @dev _createDelegation: create the delegation record
   *
   */
  function _createDelegation(
    address owner_,
    uint64 endTime_,
    address delegate_,
    uint256 delegateRightsInteger_,
    bytes32 keyHash_
  ) internal {
    tokenToDelegationRecord[keyHash_] = DelegationRecord(
      delegationId,
      owner_,
      endTime_,
      delegate_,
      delegateRightsInteger_
    );
  }

  /**
   *
   * @dev _offerAccepted: call when an offer is being accepted
   *
   */
  function _offerAccepted(
    DelegationParameters memory delegationData_,
    uint256 tokenId_,
    address owner_,
    address collection_
  ) internal {
    // 1) Check this is a valid match.
    Offer memory offerData = offerIdToOfferDetails[delegationData_.offerId];

    if (
      (offerData.collection != collection_) ||
      (!offerData.collectionOffer && offerData.tokenId != tokenId_) ||
      (delegationData_.delegate != offerData.offerMaker) ||
      (delegationData_.duration != offerData.delegationDuration) ||
      (delegationData_.fee != offerData.offerAmount) ||
      (delegationData_.delegateRightsInteger !=
        offerData.delegateRightsInteger) ||
      (block.timestamp > offerData.expiry)
    ) {
      revert InvalidOffer();
    }

    // 2) Perform payment processing:

    // If the payment ERC20 is address(0) this means the default, which is weth
    // (doing this saves a slot on the offer struct)
    address paymentERC20Address;
    uint256 registerFee;
    if (offerData.paymentERC20 == address(0)) {
      paymentERC20Address = weth;
      registerFee = delegationRegisterFee;
    } else {
      paymentERC20Address = offerData.paymentERC20;

      if (!validERC20PaymentOption[paymentERC20Address].isValid)
        revert InvalidERC20();

      registerFee = validERC20PaymentOption[paymentERC20Address].registerFee;
    }

    // Cancel the offer as it is being actioned
    delete offerIdToOfferDetails[delegationData_.offerId];

    uint256 claimAmount = (delegationData_.fee + registerFee);

    // Claim payment from the offerer:
    if (claimAmount > 0) {
      IERC20(paymentERC20Address).transferFrom(
        delegationData_.delegate,
        address(this),
        claimAmount
      );
    }

    uint256 epsFee;

    // The fee taken by the protocol is a percentage of the delegation fee + the register fee. This ensures
    // that even for free delegations the platform takes a small fee to remain sustainable.

    if (delegationData_.fee == 0) {
      epsFee = registerFee;
    } else {
      epsFee =
        ((delegationData_.fee * delegationFeePercentage) /
          PERCENTAGE_DENOMINATOR) +
        registerFee;
    }

    // Handle delegation Fee remittance
    if (delegationData_.fee != 0) {
      IERC20(paymentERC20Address).transfer(owner_, (claimAmount - epsFee));
    }

    emit OfferAccepted(
      delegationData_.provider,
      delegationData_.offerId,
      epsFee,
      paymentERC20Address
    );
  }

  /**
   *
   * @dev _decodeParameters
   *
   */
  function _decodeParameters(bytes memory data_)
    internal
    pure
    returns (DelegationParameters memory)
  {
    // Decode the delegation parameters from the data_ passed in:
    (
      uint64 paramProvider,
      address paramDelegate,
      uint24 paramDuration,
      uint96 paramFee,
      uint256 paramOwnerRights,
      uint256 paramDelegateRights,
      string memory paramURI,
      uint64 paramPfferId
    ) = abi.decode(
        data_,
        (uint64, address, uint24, uint96, uint256, uint256, string, uint64)
      );

    return (
      DelegationParameters(
        paramProvider,
        paramDelegate,
        paramDuration,
        paramFee,
        paramOwnerRights,
        paramDelegateRights,
        paramURI,
        paramPfferId
      )
    );
  }

  /**
   *
   * @dev onERC721Received - tokens are containerised for delegation by being sent to this
   * contract with the correct bytes data. NOTE - DO NOT JUST SEND ERC721s TO THIS
   * CONTRACT. This MUST be called from an interface that correctly encodes the
   * bytes parameter data for decode.
   *
   */

  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory data_
  ) external override returns (bytes4) {
    if (from_ == address(0)) revert DoNoMintToThisAddress();

    address tokenContract = msg.sender;

    // Decode the delegation parameters from the data_ passed in:
    DelegationParameters memory delegationData = _decodeParameters(data_);

    // Check that we have been passed valid rights details for the owner and the beneficiary.
    if (
      delegationData.ownerRightsInteger +
        delegationData.delegateRightsInteger !=
      TOTAL_RIGHTS
    ) revert InvalidRights();

    // Cannot assign the current owner as the delegate:
    if (delegationData.delegate == from_) revert OwnerCannotBeDelegate();

    // Create the container contract:
    address newDelegationContainer = delegationContainer.clone();

    // Assign the container a delegation Id
    _assignDelegationId(newDelegationContainer);

    if (delegationData.offerId == 0) {
      emit DelegationCreated(
        delegationData.provider,
        delegationId,
        newDelegationContainer,
        from_,
        delegationData.delegate,
        delegationData.fee,
        delegationData.duration,
        tokenContract,
        tokenId_,
        delegationData.delegateRightsInteger,
        delegationData.URI
      );
    }

    (bytes32 keyHash, bytes32 ownerHash) = _getKeyAndParticipantHashes(
      tokenContract,
      tokenId_,
      from_
    );

    // If this was accepting an offer we save a full delegation record now:
    if (delegationData.offerId != 0) {
      _isMarketOpen();

      _createDelegationFromOffer(
        delegationData,
        tokenId_,
        from_,
        keyHash,
        ownerHash,
        tokenContract,
        newDelegationContainer
      );
    } else {
      _createDelegation(from_, 0, address(0), 0, keyHash);

      _increaseRightsInteger(
        newDelegationContainer,
        from_,
        tokenContract,
        tokenId_,
        ownerHash,
        TOTAL_RIGHTS
      );
    }

    // Initialise storage data:
    IDelegationContainer(newDelegationContainer).initialiseDelegationContainer(
      payable(from_),
      payable(delegationData.delegate),
      delegationData.fee,
      delegationData.duration,
      msg.sender,
      tokenId_,
      delegationData.delegateRightsInteger,
      delegationData.URI,
      delegationData.offerId
    );

    // Deliver the ERC721 to the container:
    IERC721(msg.sender).safeTransferFrom(
      address(this),
      newDelegationContainer,
      tokenId_
    );

    return this.onERC721Received.selector;
  }

  /**
   *
   * @dev saveDelegationRecord: Save the complete delegation to the register.
   *
   */
  function saveDelegationRecord(
    uint64 provider_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_,
    uint64 endTime_,
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external payable {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash, bytes32 delegateHash) = _getAllHashes(
      tokenContract_,
      tokenId_,
      owner_,
      delegate_
    );

    _updateDelegationRecordDetails(
      keyHash,
      endTime_,
      delegate_,
      delegateRightsInteger_
    );

    // We can just subtract the delegate rights integer as we added in a
    // TOTAL_RIGHTS for the owner while the delegation was pending:
    _decreaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      delegateRightsInteger_
    );

    _increaseRightsInteger(
      msg.sender,
      delegate_,
      tokenContract_,
      tokenId_,
      delegateHash,
      delegateRightsInteger_
    );

    emit DelegationAccepted(
      provider_,
      recordId,
      msg.sender,
      tokenContract_,
      tokenId_,
      owner_,
      delegate_,
      endTime_,
      delegateRightsInteger_,
      msg.value,
      containerURI_
    );
  }

  /**
   *
   * @dev acceptOfferPriorToCommencement: Accept an offer from a container that is pre-commencement
   *
   */
  function acceptOfferPriorToCommencement(
    uint64 provider_,
    address owner_,
    address delegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      owner_
    );

    // Remove the temporary full rights for the owner:
    _decreaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      TOTAL_RIGHTS
    );

    // Emit event to show that the previous listing is removed:
    _emitComplete(recordId);

    // Move the container to a new delegation Id:
    _assignDelegationId(msg.sender);

    _createDelegationFromOffer(
      DelegationParameters(
        provider_,
        delegate_,
        duration_,
        fee_,
        TOTAL_RIGHTS - delegateRightsInteger_,
        delegateRightsInteger_,
        "",
        offerId_
      ),
      tokenId_,
      owner_,
      keyHash,
      ownerHash,
      tokenContract_,
      msg.sender
    );
  }

  // =======================================
  // SECONDARY MARKET / TRANSFERS
  // =======================================

  /**
   *
   * @dev containerListedForSale: record that a delegation container has been listed for sale.
   *
   */
  function containerListedForSale(uint64 provider_, uint96 salePrice_)
    external
  {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit an event so we know about it:
    emit ContainerListedForSale(provider_, recordId, msg.sender, salePrice_);
  }

  /**
   *
   * @dev containerDetailsUpdated: record that an asset owner has updated container details.
   *
   */
  function containerDetailsUpdated(
    uint64 provider_,
    address delegate_,
    uint256 fee_,
    uint256 duration_,
    uint256 delegateRightsInteger_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit an event so we know about it:
    emit ContainerDetailsUpdated(
      provider_,
      recordId,
      msg.sender,
      delegate_,
      fee_,
      duration_,
      delegateRightsInteger_
    );
  }

  /**
   *
   * @dev changeAssetOwner: Change the owner of the container on sale.
   *
   */
  function changeAssetOwner(
    uint64 provider_,
    address newOwner_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee_
  ) external {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 newOwnerHash) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      newOwner_
    );

    // Save the old owner:
    address oldOwner = tokenToDelegationRecord[keyHash].owner;

    // Get hash for old owner:
    bytes32 oldOwnerHash = _getParticipantHash(tokenContract_, oldOwner);

    // This has been called from a container, and that method is assetOwner only. Procced to
    // update the register accordingly.

    // Update owner:
    tokenToDelegationRecord[keyHash].owner = newOwner_;

    // Reduce the contract to balance rights of the old owner by the owner rights integer
    // for this delegation record, and likewise increase it for the new owner:

    uint256 rightsInteger = TOTAL_RIGHTS -
      tokenToDelegationRecord[keyHash].delegateRightsInteger;

    _decreaseRightsInteger(
      msg.sender,
      oldOwner,
      tokenContract_,
      tokenId_,
      oldOwnerHash,
      rightsInteger
    );

    _increaseRightsInteger(
      msg.sender,
      newOwner_,
      tokenContract_,
      tokenId_,
      newOwnerHash,
      rightsInteger
    );

    emit DelegationOwnerChanged(provider_, recordId, newOwner_, epsFee_);
  }

  /**
   *
   * @dev List the delegation for sale.
   *
   */
  function delegationListedForSale(uint64 provider_, uint96 salePrice_)
    external
  {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit an event so we know about it:
    emit DelegationListedForSale(provider_, recordId, salePrice_);
  }

  /**
   *
   * @dev changeDelegate: Change the delegate on a delegation.
   *
   */
  function changeDelegate(
    uint64 provider_,
    address newDelegate_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee_
  ) external {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 newDelegateHash) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      newDelegate_
    );

    // Save the old delegate:
    address oldDelegate = tokenToDelegationRecord[keyHash].delegate;

    // Get hashes for new and old delegate:
    bytes32 oldDelegateHash = _getParticipantHash(tokenContract_, oldDelegate);

    // This has been called from a container, and that method is delegate only. Procced to
    // update the register accordingly:

    // Update delegate:
    tokenToDelegationRecord[keyHash].delegate = newDelegate_;

    // Reduce the contract to balance rights of the old delegate by the delegate rights integer
    // for this delegation record, and likewise increase it for the new delegate:

    uint256 rightsInteger = tokenToDelegationRecord[keyHash]
      .delegateRightsInteger;

    _decreaseRightsInteger(
      msg.sender,
      oldDelegate,
      tokenContract_,
      tokenId_,
      oldDelegateHash,
      rightsInteger
    );

    _increaseRightsInteger(
      msg.sender,
      newDelegate_,
      tokenContract_,
      tokenId_,
      newDelegateHash,
      rightsInteger
    );

    emit DelegationDelegateChanged(provider_, recordId, newDelegate_, epsFee_);
  }

  // =======================================
  // END OF DELEGATION
  // =======================================

  /**
   *
   * @dev acceptOfferAfterDelegationCompleted: Perform acceptance processing where the user is
   * ending a delegation and accepting an offer.
   *
   */
  function acceptOfferAfterDelegationCompleted(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address newDelegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external payable {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      oldDelegate_,
      tokenId_,
      recordId
    );

    // Move the container to a new delegation Id:
    _assignDelegationId(msg.sender);

    _createDelegationFromOffer(
      DelegationParameters(
        provider_,
        newDelegate_,
        duration_,
        fee_,
        TOTAL_RIGHTS - delegateRightsInteger_,
        delegateRightsInteger_,
        "",
        offerId_
      ),
      tokenId_,
      owner_,
      keyHash,
      ownerHash,
      tokenContract_,
      msg.sender
    );
  }

  /**
   *
   * @dev deleteEntry: remove a completed entry from the register.
   *
   */
  function deleteEntry(
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, ) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      delegate_,
      tokenId_,
      recordId
    );

    // Delete the register entry and owner and delegate data:
    delete tokenToDelegationRecord[keyHash];
    delete containerToDelegationId[msg.sender];
  }

  /**
   *
   * @dev relistEntry: relist an entry for a new delegation
   *
   */
  function relistEntry(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address newDelegate_,
    uint96 fee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      oldDelegate_,
      tokenId_,
      recordId
    );

    // Move the container to a new delegation Id:
    _assignDelegationId(msg.sender);

    _resetDelegationRecordDetails(keyHash);

    _increaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      TOTAL_RIGHTS
    );

    emit DelegationCreated(
      provider_,
      delegationId,
      msg.sender,
      owner_,
      newDelegate_,
      fee_,
      durationInDays_,
      tokenContract_,
      tokenId_,
      delegateRightsInteger_,
      containerURI_
    );
  }

  /**
   *
   * @dev _emitComplete: signal that this delegation is complete
   *
   */
  function _emitComplete(uint64 delegationId_) internal {
    emit DelegationComplete(delegationId_);
  }

  // =======================================
  // OFFERS
  // =======================================

  /**
   *
   * @dev makeOffer: make an offer.
   *
   */
  function makeOffer(
    uint64 provider_,
    uint24 duration_,
    uint32 expiry_,
    bool collectionOffer_,
    address collection_,
    uint96 offerAmount_,
    address offerERC20_,
    uint256 tokenId_,
    uint256 delegateRightsRequested_
  ) external {
    // Check that the payment ERC20 is valid

    if (
      offerERC20_ != address(0) && !validERC20PaymentOption[offerERC20_].isValid
    ) revert InvalidERC20();

    // Increment offer id
    offerId += 1;

    offerIdToOfferDetails[offerId] = Offer(
      msg.sender,
      duration_,
      expiry_,
      collectionOffer_,
      collection_,
      offerAmount_,
      tokenId_,
      delegateRightsRequested_,
      offerERC20_
    );

    emit OfferMade(
      provider_,
      offerId,
      collection_,
      collectionOffer_,
      tokenId_,
      duration_,
      expiry_,
      offerAmount_,
      delegateRightsRequested_,
      msg.sender
    );
  }

  /**
   *
   * @dev cancelOffer: cancel an offer.
   *
   */
  function cancelOffer(uint64 provider_, uint64 offerId_) external {
    if (msg.sender != offerIdToOfferDetails[offerId_].offerMaker)
      revert CallerIsNotOfferMaker();
    delete offerIdToOfferDetails[offerId_];
    emit OfferDeleted(provider_, offerId_);
  }

  /**
   *
   * @dev changeOffer: change an offer.
   *
   */
  function changeOffer(
    uint64 provider_,
    uint64 offerId_,
    uint24 newDuration_,
    uint32 newExpiry_,
    uint96 newAmount_,
    uint256 newRightsInteger_
  ) external {
    if (msg.sender != offerIdToOfferDetails[offerId_].offerMaker)
      revert CallerIsNotOfferMaker();

    if (newDuration_ != 0)
      offerIdToOfferDetails[offerId_].delegationDuration = newDuration_;
    if (newExpiry_ != 0) offerIdToOfferDetails[offerId_].expiry = newExpiry_;
    if (newAmount_ != 0)
      offerIdToOfferDetails[offerId_].offerAmount = newAmount_;
    if (newRightsInteger_ != 0)
      offerIdToOfferDetails[offerId_].delegateRightsInteger = newRightsInteger_;

    emit OfferChanged(
      provider_,
      offerId_,
      newDuration_,
      newExpiry_,
      newAmount_,
      newRightsInteger_
    );
  }
}