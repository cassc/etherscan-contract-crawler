// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IDelegationContainer.sol";
import "./IEPSDelegateRegister.sol";

/**
 *
 * @dev The delegation container contract. This contract holds details of the EPS
 * delegation and custodies the asset. It is owned by the asset owner.
 *
 */
contract DelegationContainer is IDelegationContainer, IERC721Receiver, Context {
  using Address for address;

  // ============================
  // Constants
  // ============================

  // Default for any percentages, which must be held as a prortion of 100,000, i.e. a
  // percentage of 5% is held as 5,000.
  uint256 constant PERCENTAGE_DENOMINATOR = 100000;

  uint256 constant AIR_DROP_RIGHTS = 1; // Defined as the FREE claim of new assets

  uint256 constant RIGHTS_SLICE_LENGTH = 5;

  uint256 constant OWNER_TOKEN_ID = 0;

  uint256 constant DELEGATE_TOKEN_ID = 1;

  address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  IEPSDelegateRegister immutable epsRegister;

  // ============================
  // Storage
  // ============================

  // Slot 1: 160 + 24 + 32 + 8 + 32 = 256
  address payable public assetOwner; //160
  uint24 public durationInDays; // 24 || 184
  uint32 public startTime; // 32 || 216
  bool public terminated; // 8 || 224
  uint32 public tokenIdShort; // 32 || 256

  // Slot 2: 160 + 96 = 256
  address payable public delegate; // 160
  uint96 containerSalePrice; // 96 || 256

  // Slot 3: 160 + 96 = 256
  address public tokenContract; // 160
  uint96 public delegationFee; // 96 || 25

  // Slot 4: 256
  uint256 public delegateRightsInteger; // 256

  // Slot 5: 256
  uint256 public tokenIdLong; // 256

  // Slot 6: 96 = 96
  uint96 delegationSalePrice; // 96 || 96

  // Slot 7: variable, minimum 256
  string public containerURI;

  /**
   *
   * @dev Constructor: immutable register address accepted and loaded into bytecode
   *
   */
  constructor(address epsRegisterAddress_) {
    epsRegister = IEPSDelegateRegister(epsRegisterAddress_);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Throws if called by any account other than the delegate.
   */
  modifier onlyDelegate() {
    require(delegate == _msgSender(), "Ownable: caller is not the delegate");
    _;
  }

  /**
   * @dev Throws if the delegation can't be ended.
   */
  modifier whenCanBeEnded() {
    // Can only be called when this delegation has expired:
    require(
      block.timestamp > startTime + (durationInDays * 1 days),
      "Delegation not yet expired"
    );

    require(startTime != 0, "Cannot end if never started - owner can cancel");

    require(!terminated, "Delegation already terminated");
    _;
  }

  /**
   * @dev Throws if the delegation can't be cancelled (which can only happen prior to it starting) (two l's oh yeah!).
   */
  modifier whenCanBeCancelled() {
    require(startTime == 0, "Cannot cancel during delegation term");

    require(!terminated, "Delegation already terminated");
    _;
  }

  // ============================
  // Getters
  // ============================

  /**
   * @dev getDelegationContainerDetails: Get details of this container
   */
  function getDelegationContainerDetails(uint64 passedDelegationId_)
    external
    view
    returns (
      uint64 delegationId_,
      address assetOwner_,
      address delegate_,
      address tokenContract_,
      uint256 tokenId_,
      bool terminated_,
      uint32 startTime_,
      uint24 durationInDays_,
      uint96 delegationFee_,
      uint256 delegateRightsInteger_,
      uint96 containerSalePrice_,
      uint96 delegationSalePrice_
    )
  {
    return (
      passedDelegationId_,
      assetOwner,
      delegate,
      tokenContract,
      _tokenId(),
      terminated,
      startTime,
      durationInDays,
      delegationFee,
      delegateRightsInteger,
      containerSalePrice,
      delegationSalePrice
    );
  }

  /**
   * @dev tokenId: Return the tokenId (short or long)
   */
  function tokenId() external view returns (uint256) {
    return (_tokenId());
  }

  // ============================
  // Implementation
  // ============================

  /**
   *
   * @dev initialiseDelegationContainer: function to call to set storage correctly on a new delegation container.
   *
   */
  function initialiseDelegationContainer(
    address payable owner_,
    address payable delegate_,
    uint96 delegationFee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 delegateRightsInteger_,
    string memory containerURI_,
    uint64 offerId_
  ) external {
    require(owner_ != address(0), "Initialise: Owner cannot be 0 address");

    require(assetOwner == address(0), "Initialise: Can only initialise once");

    assetOwner = owner_;

    delegate = delegate_;

    delegationFee = delegationFee_;

    durationInDays = durationInDays_;

    tokenContract = tokenContract_;

    if (tokenId_ < 4294967295) {
      tokenIdShort = uint32(tokenId_);
    } else {
      tokenIdLong = tokenId_;
    }

    delegateRightsInteger = delegateRightsInteger_;

    if (bytes(containerURI_).length > 0) {
      containerURI = containerURI_;
    }

    if (offerId_ != 0) {
      // If this is accepting an offer start the delegation
      startTime = uint32(block.timestamp);

      // Make the delegation delegate token (id 1) visible:
      emit Transfer(address(0), address(delegate), DELEGATE_TOKEN_ID);
    }
  }

  /**
   *
   * @dev acceptDelegation: Delegate accepts delegation.
   *
   */
  function acceptDelegation(uint64 provider_) external payable {
    // Can't accept this twice:
    require(startTime == 0, "EPS Delegation: Delegation not available");

    // Asset owner cannot also be delegate:
    require(
      assetOwner != msg.sender,
      "EPS Delegation: Owner cannot be delegate"
    );

    (
      uint256 delegationRegisterFee,
      uint256 delegationFeePercentage
    ) = epsRegister.getFeeDetails();

    // If there is a delegation fee due it must have been paid:
    require(
      msg.value == (delegationFee + delegationRegisterFee),
      "EPS Delegation: Incorrect delegation fee"
    );

    if (delegate == address(0)) {
      delegate = payable(msg.sender);
    } else {
      // If this delegation is address specific it can only be accepted from that address:
      require(delegate == msg.sender, "EPS: Incorrect delegate address");
    }

    // We have a valid delegation, finalise the arrangement:
    startTime = uint32(block.timestamp);

    uint256 epsFee;

    // The fee taken by the protocol is a percentage of the delegation fee + the register fee. This ensures
    // that even for free delegations the platform takes a small fee to remain sustainable.
    if (msg.value == delegationRegisterFee) {
      epsFee = delegationRegisterFee;
    } else {
      epsFee = _calculateEPSFee(
        msg.value,
        delegationRegisterFee,
        delegationFeePercentage
      );
    }

    // Load to epsRegister:
    epsRegister.saveDelegationRecord{value: epsFee}(
      provider_,
      tokenContract,
      _tokenId(),
      assetOwner,
      delegate,
      uint32(block.timestamp) + (durationInDays * 1 days),
      delegateRightsInteger
    );

    // Handle delegationFee remittance
    if (msg.value - epsFee > 0) {
      _processPayment(assetOwner, (msg.value - epsFee));
    }

    // Make the delegate token (token id 1) visible:
    emit Transfer(address(0), address(delegate), DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev cancelDelegation: The owner can call this to cancel a delegation that has not yet begun.
   *
   */
  function cancelDelegation(uint64 provider_)
    external
    onlyOwner
    whenCanBeCancelled
  {
    _performFinalisation(provider_);
  }

  /**
   *
   * @dev endDelegationAndRetrieveAsset: When this delegation has expired it can be ended, with the original
   * asset returned to the assetOwner and the register details removed. Note that any NEW assets
   * on this contract are handled according to the rights delegated (i.e. whether they go to the owner
   * or the delegate).
   *
   */
  function endDelegationAndRetrieveAsset(uint64 provider_)
    external
    onlyOwner
    whenCanBeEnded
  {
    _performFinalisation(provider_);

    // Also "burn" the delegate token:
    emit Transfer(delegate, address(0), DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev endDelegationAndRelist: When this delegation has expired it can be ended, with a new delegation
   * specified in its place.
   *
   * This function can be called by the asset owner only
   *
   */
  function endDelegationAndRelist(
    uint64 provider_,
    address newDelegate_,
    uint96 fee_,
    uint24 durationInDays_,
    uint256 delegateRightsInteger_
  ) external onlyOwner whenCanBeEnded {
    address oldDelegate = delegate;

    // Reset the container entries:
    durationInDays = durationInDays_;
    startTime = 0;
    delegate = payable(newDelegate_);
    delegationFee = fee_;
    delegateRightsInteger = delegateRightsInteger_;

    // Reset the register entries:
    epsRegister.relistEntry(
      provider_,
      assetOwner,
      oldDelegate,
      newDelegate_,
      fee_,
      durationInDays_,
      tokenContract,
      _tokenId(),
      delegateRightsInteger_
    );

    //  "burn" the previous delegate token:
    emit Transfer(oldDelegate, address(0), DELEGATE_TOKEN_ID);
    // New delegation is now ready to be accepted.
  }

  /**
   *
   * @dev endDelegationAndAcceptOffer: When this delegation has expired it can be ended, and a delegation
   * offer accepted (subject to all the normal checks when accepting an offer)
   *
   * This function can be called by the asset owner only
   *
   */
  function endDelegationAndAcceptOffer(
    uint64 provider_,
    address newDelegate_,
    uint96 fee_,
    uint24 durationInDays_,
    uint256 delegateRightsInteger_,
    uint64 offerId_
  ) external onlyOwner whenCanBeEnded {
    address oldDelegate = delegate;
    // TODO - need to emit a transfer event from the old delegate to the new delegate, also in other places
    // that this happens.

    epsRegister.acceptOfferToExistingContainer(
      provider_,
      assetOwner,
      oldDelegate,
      newDelegate_,
      durationInDays_,
      fee_,
      delegateRightsInteger_,
      offerId_,
      tokenContract,
      _tokenId()
    );

    // Set the container entries to those retrieved from the offer:
    durationInDays = durationInDays_;
    startTime = uint32(block.timestamp + (durationInDays * 1 days));
    delegate = payable(newDelegate_);
    delegationFee = fee_;
    delegateRightsInteger = delegateRightsInteger_;

    // Note we could transfer the delegate token directly from the old delegate to the new delegate
    // in the same event. However, this is not what's happening, rather the delegation associated with
    // the old delegate is ending, and that with the new delegate is beginning. We therefore 'burn'
    // the old delegates token and 'mint' a new one for the new delegate.
    emit Transfer(oldDelegate, address(0), DELEGATE_TOKEN_ID);
    emit Transfer(address(0), newDelegate_, DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev _tokenId: return either tokenIdShort or Long
   *
   */
  function _tokenId() internal view returns (uint256) {
    // This saves storage on practically every container, as tokenId is very rarely
    // more than 4,294,967,295, but we store a whole uint256 for it every time, therefore
    // requiring a whole slot. Note that this method works for tokenId 0 as well, as that
    // will enter here, fail the tokenIdShort check (as it has been set to 0) and return
    // the value from tokenIdLong (which, correctly, is 0)
    if (tokenIdShort != 0) return (tokenIdShort);
    else return (tokenIdLong);
  }

  /**
   *
   * @dev _performFinalisation: unified processing for actions at the end of a delegation
   *
   */
  function _performFinalisation(uint64 provider_) internal {
    // A key principle of an EPS container is that the asset owner continues to have full rights
    // to the asset, subject to those delegated as part of the EPS delegation. The asset owner
    // has full ownership of the container. There is no other priviledged access, save the
    // delegate's right to transfer or list the delegation, and call functions if they are the
    // 'senior' rights owner of the airdrop right.
    //
    // It is therefore essential that nothing interupt the asset owner retrieving the ERC721 once
    // a delegation period has completed. Below we update the register to show that this delegation
    // has ceased and then return the asset to the owner. We do not anticipate a call to the register
    // ever failing, but it *is* an external call (i.e. to another contract). If for whatever reason it
    // fails the owner MUST still receive their ERC721. EPS would need to investigate the error and
    // determine if any corrective action is needed, but job one of the protocol is to see assets
    // under the full control of the rightful owner. For this reason we handle the external call in
    // a try / except clause. If this fails we still return the asset to the owner, in addition to
    // logging the error in an event for further analysis.

    // Remove the register entries:
    try
      epsRegister.deleteEntry(
        provider_,
        tokenContract,
        _tokenId(),
        assetOwner,
        delegate
      )
    {
      //
    } catch (bytes memory reason) {
      emit EPSRegisterCallError(reason);
    }

    terminated = true;

    // Return the original asset to the owner:
    IERC721(tokenContract).transferFrom(address(this), assetOwner, _tokenId());

    // "Burn" the owner token denoting this delegation:
    emit Transfer(owner(), address(0), OWNER_TOKEN_ID);
  }

  /**
   * @dev listContainerForSale: Allows the asset owner to list the delegation container for sale. This allows the
   * owner of an asset with an active delegation to sell the entire container contract, therefore
   * transferring the right to retrieve the ERC721 at the end of the delegation period. This also
   * allows the new owner to acknowledge that existing rights have been delegated, and that these
   * are grandfathered to the delegate despite the change of the owner of the container (and underlying asset).
   */
  function listContainerForSale(uint64 provider_, uint96 salePrice_)
    external
    onlyOwner
  {
    require(salePrice_ != 0, "Sale price cannot be 0");
    containerSalePrice = salePrice_;
    epsRegister.containerListedForSale(provider_, salePrice_);
  }

  /**
   * @dev buyContainerForSale: allows someone to purchase the container if they have paid the right amount
   * of eth.
   */
  function buyContainerForSale(uint64 provider_) external payable {
    // Sale price of 0 is not for sale
    require(containerSalePrice != 0, "Container not for sale");

    // Prevent someone from buying an expired delegation or one for an empty container!
    require(
      IERC721(tokenContract).ownerOf(_tokenId()) == address(this),
      "Asset no longer in container"
    );

    require(block.timestamp > startTime + durationInDays, "Delegation expired");

    // Handle remittance:
    (
      uint256 delegationRegisterFee,
      uint256 delegationFeePercentage
    ) = epsRegister.getFeeDetails();

    // Check the fee:
    require(
      msg.value == (containerSalePrice + delegationRegisterFee),
      "Incorrect sale price"
    );

    address oldOwner = assetOwner;

    _transferOwnership(provider_, msg.sender);

    // Clear sale data
    containerSalePrice = 0;

    // Platform fee is a percentage of the sale price + the base platform fee.

    uint256 epsFee = _calculateEPSFee(
      msg.value,
      delegationRegisterFee,
      delegationFeePercentage
    );

    _processPayment(address(epsRegister), epsFee);

    // Handle delegationFee remittance
    if (msg.value - epsFee > 0) {
      _processPayment(oldOwner, (msg.value - epsFee));
    }
  }

  /**
   * @dev listDelegationForSale: Allows the delegate to list the delegation for sale.
   */
  function listDelegationForSale(uint64 provider_, uint96 salePrice_)
    external
    onlyDelegate
  {
    require(salePrice_ != 0, "EPS: Sale price cannot be 0");
    delegationSalePrice = salePrice_;
    epsRegister.delegationListedForSale(provider_, salePrice_);
  }

  /**
   * @dev buyDelegationForSale: allows someone to purchase the delegation if they have paid the right amount
   * of eth.
   */
  function buyDelegationForSale(uint64 provider_) external payable {
    // Sale price of 0 is not for sale
    require(delegationSalePrice != 0, "EPS: Delegation not for sale");

    // Prevent someone from buying an expired delegation or one for an empty container!
    require(
      IERC721(tokenContract).ownerOf(_tokenId()) == address(this),
      "EPS: Asset no longer in container"
    );

    require(
      block.timestamp > startTime + durationInDays,
      "EPS: Delegation expired"
    );

    // Handle remittance:
    (
      uint256 delegationRegisterFee,
      uint256 delegationFeePercentage
    ) = epsRegister.getFeeDetails();

    // Check the fee:
    require(
      msg.value == (delegationSalePrice + delegationRegisterFee),
      "EPS: Incorrect sale price"
    );

    address oldDelegate = delegate;

    _transferDelegate(provider_, msg.sender);

    // Clear sale data
    delegationSalePrice = 0;

    // EPS fee is a percentage of the sale price + the base platform fee.

    uint256 epsFee = _calculateEPSFee(
      msg.value,
      delegationRegisterFee,
      delegationFeePercentage
    );

    _processPayment(address(epsRegister), epsFee);

    // Handle delegationFee remittance
    if (msg.value - epsFee > 0) {
      _processPayment(oldDelegate, (msg.value - epsFee));
    }

    // "Transfer" the delegate NFT:
    emit Transfer(oldDelegate, msg.sender, DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev _calculateEPSFee: calculate the EPS fee for the provider parameters
   *
   */
  function _calculateEPSFee(
    uint256 payment_,
    uint256 delegationRegisterFee_,
    uint256 delegationFeePercentage_
  ) internal pure returns (uint256 epsFee) {
    return
      (((payment_ - delegationRegisterFee_) * delegationFeePercentage_) /
        PERCENTAGE_DENOMINATOR) + delegationRegisterFee_;
  }

  /**
   *
   * @dev _processPayment: unified processing for transfer of ETH
   *
   */
  function _processPayment(address payee_, uint256 payment_) internal {
    if (payment_ > 0) {
      (bool success, ) = payee_.call{value: payment_}("");
      require(success, "EPS: Transfer failed");
    }
  }

  /**
   * @dev getBeneficiaryByRight: Get balance modifier by rights
   */
  function getBeneficiaryByRight(uint256 rightsIndex_)
    external
    view
    returns (address)
  {
    // Check the delegateRightsInteger to see whether the owner or the
    // delegate has rights at this index (note that the rights integers always sum
    // so we can check either to get the same result)

    if (_sliceRightsInteger(rightsIndex_, delegateRightsInteger) == 0) {
      // Owner has the rights
      return (assetOwner);
    } else {
      // Delegate has the rights
      return (delegate);
    }
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
   * @dev onERC721Received: Recieve an ERC721
   *
   */
  function onERC721Received(
    address,
    address,
    uint256 tokenId_,
    bytes memory
  ) external override returns (bytes4) {
    // If this is the arrival of the original asset 'mint' the owner token:
    if (msg.sender == tokenContract && tokenId_ == _tokenId()) {
      emit Transfer(address(0), address(assetOwner), OWNER_TOKEN_ID);
    }
    return this.onERC721Received.selector;
  }

  /**
   * @dev Ownable methods: owner() is the assetOwner.
   */

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return assetOwner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(uint64 provider_, address newOwner)
    public
    onlyOwner
  {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(provider_, newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(uint64 provider_, address newOwner) internal {
    address oldOwner = assetOwner;
    assetOwner = payable(newOwner);
    // Update the delegation register:
    epsRegister.changeAssetOwner(
      provider_,
      newOwner,
      tokenContract,
      _tokenId()
    );
    emit OwnershipTransferred(provider_, oldOwner, newOwner);

    // "Transfer" the ownership NFT
    emit Transfer(oldOwner, newOwner, OWNER_TOKEN_ID);
  }

  /**
   * @dev Transfers delegate to a new account (`newDelegate`).
   * Can only be called by the current delegate.
   */
  function transferDelegate(uint64 provider_, address newDelegate_)
    public
    onlyDelegate
  {
    require(
      newDelegate_ != address(0),
      "Ownable: new owner is the zero address"
    );

    address oldDelegate = delegate;

    _transferDelegate(provider_, newDelegate_);

    // "Transfer" the delegate NFT:
    emit Transfer(oldDelegate, newDelegate_, DELEGATE_TOKEN_ID);
  }

  /**
   * @dev Transfers delegate to the dead address.
   * Can only be called by the current delegate.
   */
  function burnDelegate(uint64 provider_) public onlyDelegate {
    address oldDelegate = delegate;

    _transferDelegate(provider_, BURN_ADDRESS);

    // We set the delegate to the 0xdead address as we need this address
    // to be non-0 to show that there IS a delegation here, even though
    // the delegate has burned their rights for the duration of the delegation.
    // But we 'burn' the delegate token to the 0 address so that all delegation
    // indication tokens arrive from and depart to the 0 address.
    emit Transfer(oldDelegate, address(0), DELEGATE_TOKEN_ID);
  }

  /**
   * @dev Transfers delegate on the contract to a new account (`newDelegate`).
   * Internal function without access restriction.
   */
  function _transferDelegate(uint64 provider_, address newDelegate_) internal {
    delegate = payable(newDelegate_);

    // Update the delegation register:
    epsRegister.changeDelegate(provider_, delegate, tokenContract, _tokenId());
  }

  /**
   *
   * @dev airdropAddress: return the address that has new asset (i.e. airdrop) rights on this delegation.
   *
   */
  function _airdropAddress() internal view returns (address payable) {
    // Check the delegateRightsInteger to see whether the owner or the
    // delegate has rights at this index (note that the rights integers always sum
    // so we can check either to get the same result)

    if (_sliceRightsInteger(1, delegateRightsInteger) == 0) {
      // Owner has the rights
      return (assetOwner);
    } else {
      // Delegate has the rights
      return (delegate);
    }
  }

  /**
   *
   * @dev withdrawETH: A withdraw function to allow ETH to be withdrawn to the address with airdrop rights
   *
   */
  function withdrawETH(uint256 amount_) external {
    (bool success, ) = _airdropAddress().call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev withdrawERC20: A withdraw function to allow ERC20s to be withdrawn to the address with airdrop rights
   *
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external {
    token_.transfer(_airdropAddress(), amount_);
  }

  /**
   *
   * @dev withdrawERC721: A withdraw function to allow ERC721s to be withdrawn to the address with airdrop rights
   * Note - this excludes the delegated asset!
   *
   */
  function withdrawERC721(IERC721 token_, uint256 tokenId_) external {
    require(
      !(address(token_) == tokenContract && tokenId_ == _tokenId()),
      "Cannot transfer delegated asset"
    );

    token_.transferFrom(address(this), _airdropAddress(), tokenId_);
  }

  /**
   *
   * @dev withdrawERC1155: A withdraw function to allow ERC1155s to be withdrawn to the address with airdrop rights
   * Note - this excludes the delegated asset!
   *
   */
  function withdrawERC1155(
    IERC1155 token_,
    uint256 tokenId_,
    uint256 amount_
  ) external {
    token_.safeTransferFrom(
      address(this),
      _airdropAddress(),
      tokenId_,
      amount_,
      ""
    );
  }

  /**
   *
   * @dev callExternal: It remains possible that to claim some benefit the beneficial owner of the asset needs to
   * make a call to another contract. For example, there could be an airdrop that must be claimed, and the project
   * performing the airdrop hasn't consulted the delegation register. Hopefully this doesn't happen, but if it does,
   * provide this method of calling any contract with any parameters.
   *
   * Note that we are making a distinction ahead of time that this function can only be used by the owner with air-drop
   * rights. It is conceivable that this function could be used in a mint scenario, but it is impossible to know ahead of time
   * what uses this may be put to by future projects. Airdrop rights in this sense are the 'senior' new asset right.
   *
   */
  function callExternal(
    address to_,
    uint256 value_,
    bytes memory data_,
    uint256 txGas_
  ) external returns (bool success) {
    // This cannot be used on a call to the tokenContract of the delegated asset, itself, or the EPS register
    require(
      to_ != tokenContract &&
        to_ != address(this) &&
        to_ != address(epsRegister),
      "Invalid call"
    );

    // Only the airdrop address
    require(
      msg.sender == _airdropAddress(),
      "Only address with airdrop rights"
    );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := call(txGas_, to_, value_, add(data_, 0x20), mload(data_), 0, 0)
    }

    require(success, "External call failed");
  }

  /**
   * @dev Receive ETH
   */
  receive() external payable {}

  /**
   * ================================
   * IERC721 interface
   * ================================
   */

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId;
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner_) public view returns (uint256) {
    if (terminated) {
      return (0);
    }

    if (owner_ == owner()) {
      return (1);
    }

    if (owner_ == delegate && startTime != 0) {
      return (1);
    }

    return (0);
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId_) public view returns (address ownerOf_) {
    if (terminated || tokenId_ > 1) {
      revert("ERC721: invalid token ID");
    }

    if (tokenId_ == 0) {
      return (owner());
    }

    if (tokenId_ == 1) {
      if (startTime == 0) {
        // Can't have an owner of a delegate token before this has started:
        revert("ERC721: invalid token ID");
      }
      if (delegate == BURN_ADDRESS) {
        // Unusual situation of a delegate having burned their delegation rights:
        revert("ERC721: invalid token ID");
      }
      return (delegate);
    }
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view returns (string memory) {
    uint64 delegationId = epsRegister.getDelegationIdForContainer(
      address(this)
    );

    return
      string.concat(
        "EPS Delegation ",
        Strings.toString(delegationId),
        ",  Token 0 is owner, Token 1 is delegate"
      );
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view returns (string memory) {
    uint64 delegationId = epsRegister.getDelegationIdForContainer(
      address(this)
    );

    return string.concat("EPS", Strings.toString(delegationId));
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId_) public view returns (string memory) {
    require(tokenId_ < 2, "ERC721: invalid token ID");

    return IERC721Metadata(tokenContract).tokenURI(_tokenId());
  }
}