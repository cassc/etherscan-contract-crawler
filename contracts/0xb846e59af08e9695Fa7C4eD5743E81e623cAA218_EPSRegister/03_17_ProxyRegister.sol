// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEPSProxyRegister.sol";

/**
 *
 * @dev The EPS Proxy Register contract. This contract implements a trustless proof of proxy between
 * two addresses, allowing the hot address to operate with the same rights as a cold address, and
 * for new assets to be delivered to a configurable delivery address.
 *
 */
contract ProxyRegister is IEPSProxyRegister, Ownable {
  // ======================================================
  // CONSTANTS
  // ======================================================

  // Constants denoting the API access types:
  uint256 constant HOT_NOMINATE_COLD = 1;
  uint256 constant COLD_ACCEPT_HOT = 2;
  uint256 constant CHANGE_DELIVERY = 3;
  uint256 constant DELETE_RECORD = 4;

  // ======================================================
  // VARIABLES
  // ======================================================

  // Fee to add a live proxy record to the register. This must be sent by the cold or hot wallet
  // address to the contract AFTER the hot wallet has nominated the cold wallet and the cold
  // wallet has accepted. If a fee is payable the record will remain in paymentPending status
  // until it is paid. If no fee is being charged the record is live after the cold wallet has
  // accepted the nomination.
  uint256 public proxyRegisterFee;

  // Cold wallet addresses need never call methods on EPS. All functionality is provided through
  // an ERC20 interface API, as well as traditional contract methods. To allow a cold wallet to delete
  // a proxy record without even using the ERC20 API, for example when the owner has lost access to
  // the hot wallet, we provide a nominal ETH payment, that if received from a cold wallet on a live
  // proxy will delete that proxy record.
  uint256 public deletionNominalEth;

  // ======================================================
  // MAPPINGS
  // ======================================================

  // Mapping between the hot wallet and the proxy record, the proxy record holding all the details of
  // the proxy relationship
  mapping(address => Record) hotToRecord;

  // Mapping from a cold address to a the associated hot address
  mapping(address => address) coldToHot;

  /**
   * @dev Constructor initialises the register fee and nominal ETH to which can be sent to
   * the contract to end an existing proxy.
   */
  constructor(uint256 registerFee_, uint256 deletionNominalEth_) {
    proxyRegisterFee = registerFee_;
    deletionNominalEth = deletionNominalEth_;
  }

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev isValidAddresses: Check the validity of sent addresses
   */
  function isValidAddresses(
    address hot_,
    address cold_,
    address delivery_
  ) public pure {
    require(cold_ != address(0), "Cold = 0");
    require(cold_ != hot_, "Hot = cold");
    require(delivery_ != address(0), "Delivery = 0");
  }

  /**
   * @dev addressIsAvailable: Return if an address isn't, as either hot or cold:
   * 1) live
   * 2) pending acceptance (unless we are checking as a cold address, which can be at pendingAcceptance infinite times)
   * 3) pending payment
   */
  function addressIsAvailable(address queryAddress_, bool checkingHot_)
    public
    view
    returns (bool)
  {
    // Check as cold:
    ProxyStatus currentStatus = hotToRecord[coldToHot[queryAddress_]].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      // Cold addresses CAN be pending acceptance as many times as they like,
      // in fact it is vital that they can be, so we only check this for the hot
      // address:
      (checkingHot_ && currentStatus == ProxyStatus.pendingAcceptance)
    ) {
      return false;
    }

    // Check as hot:
    currentStatus = hotToRecord[queryAddress_].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      // Neither cold or hot can be a hot address, at any status
      currentStatus == ProxyStatus.pendingAcceptance
    ) {
      return false;
    }

    return true;
  }

  /**
   * @dev coldIsLive: Return if a cold wallet is live
   */
  function coldIsLive(address cold_) public view returns (bool) {
    return (hotToRecord[coldToHot[cold_]].status == ProxyStatus.live);
  }

  /**
   * @dev hotIsLive: Return if a hot wallet is live
   */
  function hotIsLive(address hot_) public view returns (bool) {
    return (hotToRecord[hot_].status == ProxyStatus.live);
  }

  /**
   * @dev coldIsActiveOnRegister: Return if a cold wallet is active
   */
  function coldIsActiveOnRegister(address cold_) public view returns (bool) {
    ProxyStatus currentStatus = hotToRecord[coldToHot[cold_]].status;
    return (currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment);
  }

  /**
   * @dev hotIsActiveOnRegister: Return if a hot wallet is active
   */
  function hotIsActiveOnRegister(address hot_) public view returns (bool) {
    ProxyStatus currentStatus = hotToRecord[hot_].status;
    return (currentStatus != ProxyStatus.none);
  }

  /**
   * @dev getProxyRecordForHot: Get proxy details for a hot address
   */
  function getProxyRecordForHot(address hot_)
    public
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    )
  {
    Record memory currentItem = hotToRecord[hot_];
    return (
      currentItem.status,
      hot_,
      currentItem.cold,
      currentItem.delivery,
      currentItem.provider,
      currentItem.feePaid
    );
  }

  /**
   * @dev getProxyRecordForCold: Get proxy details for a cold address
   */
  function getProxyRecordForCold(address cold_)
    public
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    )
  {
    address currentHot = coldToHot[cold_];
    Record memory currentItem = hotToRecord[currentHot];
    return (
      currentItem.status,
      currentHot,
      currentItem.cold,
      currentItem.delivery,
      currentItem.provider,
      currentItem.feePaid
    );
  }

  /**
   * @dev Get proxy details for an address, checking cold and hot
   */
  function getProxyRecordForAddress(address queryAddress_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    )
  {
    // Check as cold:
    ProxyStatus currentStatus = hotToRecord[coldToHot[queryAddress_]].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      (currentStatus == ProxyStatus.pendingAcceptance)
    ) {
      return getProxyRecordForCold(queryAddress_);
    }

    // Check as hot:
    currentStatus = hotToRecord[queryAddress_].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      (currentStatus == ProxyStatus.pendingAcceptance)
    ) {
      return (getProxyRecordForHot(queryAddress_));
    }

    // Address not found
    return (ProxyStatus.none, address(0), address(0), address(0), 0, false);
  }

  // ======================================================
  // LIFECYCLE - NOMINATION
  // ======================================================

  /**
   * @dev nominate: Hot Nominates cold, direct contract call
   */
  function nominate(
    address cold_,
    address delivery_,
    uint64 provider_
  ) external payable {
    require(msg.value == proxyRegisterFee, "Incorrect fee");
    _processNomination(msg.sender, cold_, delivery_, msg.value, provider_);
  }

  /**
   * @dev _processNomination: Process the nomination
   */
  // The hot wallet cannot be on any record, live or pending, as either a hot or cold wallet.
  // The cold wallet cannot be currently live or pending payment, but can be 'pending' on multiple records. It can
  // only accept one of those pending records (at at time - others can be accepted if it cancels the existing proxy)
  function _processNomination(
    address hot_,
    address cold_,
    address delivery_,
    uint256 feePaid_,
    uint64 provider_
  ) internal {
    isValidAddresses(hot_, cold_, delivery_);

    require(
      addressIsAvailable(hot_, true) && addressIsAvailable(cold_, false),
      "Already proxied"
    );

    // Record the mapping from the hot address to the record. This is pending until accepted by the cold address.
    hotToRecord[hot_] = Record(
      provider_,
      ProxyStatus.pendingAcceptance,
      feePaid_ == proxyRegisterFee,
      cold_,
      delivery_
    );

    emit NominationMade(hot_, cold_, delivery_, provider_);
  }

  /**
   * @dev acceptNomination: Cold accepts nomination, direct contract call
   * (though it is anticipated that most will use an ERC20 transfer)
   */
  function acceptNomination(address hot_, uint64 provider_) external payable {
    _acceptNominationValidation(hot_, msg.sender);

    require(
      hotToRecord[hot_].feePaid || msg.value == proxyRegisterFee,
      "Fee required"
    );
    _acceptNomination(hot_, msg.sender, msg.value, provider_);
  }

  /**
   * @dev _acceptNominationValidation: validate passed parameters
   */
  function _acceptNominationValidation(address hot_, address cold_)
    internal
    view
  {
    // Check that the address passed in matches a pending record for the hot address:
    require(
      hotToRecord[hot_].cold == cold_ &&
        hotToRecord[hot_].status == ProxyStatus.pendingAcceptance,
      "Address mismatch"
    );

    // Check that the cold address isn't live or pending payment anywhere on the register:
    require(addressIsAvailable(cold_, false), "Already proxied");
  }

  /**
   * @dev _acceptNomination: Cold wallet accepts nomination
   */
  function _acceptNomination(
    address hot_,
    address cold_,
    uint256 feePaid_,
    uint64 providerCode_
  ) internal {
    // Record the mapping from the cold to the hot address:
    coldToHot[cold_] = hot_;

    emit NominationAccepted(
      hot_,
      cold_,
      hotToRecord[hot_].delivery,
      providerCode_
    );

    if (hotToRecord[hot_].feePaid || feePaid_ == proxyRegisterFee) {
      _recordLive(
        hot_,
        cold_,
        hotToRecord[hot_].delivery,
        hotToRecord[hot_].provider
      );
    } else {
      hotToRecord[hot_].status = ProxyStatus.pendingPayment;
    }
  }

  /**
   * @dev _recordLive: put a proxy record live
   */
  function _recordLive(
    address hot_,
    address cold_,
    address delivery_,
    uint64 provider_
  ) internal {
    hotToRecord[hot_].feePaid = true;
    hotToRecord[hot_].status = ProxyStatus.live;

    emit ProxyRecordLive(hot_, cold_, delivery_, provider_);
  }

  // ======================================================
  // LIFECYCLE - CHANGING DELIVERY ADDRESS
  // ======================================================

  /**
   * @dev updateDeliveryAddress: Change delivery address on an existing proxy record.
   */
  function updateDeliveryAddress(address delivery_, uint256 provider_)
    external
  {
    _updateDeliveryAddress(msg.sender, delivery_, provider_);
  }

  /**
   * @dev _updateDeliveryAddress: unified delivery address update processing
   */
  function _updateDeliveryAddress(
    address caller_,
    address delivery_,
    uint256 provider_
  ) internal {
    require(delivery_ != address(0), "Delivery = 0");
    // Only hot can change delivery address:
    if (hotIsActiveOnRegister(caller_)) {
      // Hot is requesting the change of address.
      // Get the associated hot address and process the address change
      _processUpdateDeliveryAddress(caller_, delivery_, provider_);
      //
    } else if (coldIsActiveOnRegister(caller_)) {
      // Cold is requesting the change of address. Cold cannot perform this operation:
      revert OnlyHotAddressCanChangeAddress();
      //
    } else {
      // Address not found, revert
      revert NoRecordFoundForAddress();
    }
  }

  /**
   * @dev _processUpdateDeliveryAddress: Process the update of the delivery address
   */
  function _processUpdateDeliveryAddress(
    address hot_,
    address delivery_,
    uint256 provider_
  ) internal {
    Record memory priorItem = hotToRecord[hot_];

    hotToRecord[hot_].delivery = delivery_;
    emit DeliveryUpdated(
      hot_,
      priorItem.cold,
      delivery_,
      priorItem.delivery,
      provider_
    );
  }

  // ======================================================
  // LIFECYCLE - DELETING A RECORD
  // ======================================================

  /**
   * @dev deleteRecord: Delete a proxy record, if found
   */
  function deleteRecord(uint256 provider_) external {
    _deleteRecord(msg.sender, provider_);
  }

  /**
   * @dev _deleteRecord: unified delete record processing
   */
  function _deleteRecord(address caller_, uint256 provider_) internal {
    // Hot can delete any entry that exists for it:
    if (hotIsActiveOnRegister(caller_)) {
      // Hot is requesting the deletion.
      // Get the associated cold address and process the deletion.
      _processDeleteRecord(
        caller_,
        hotToRecord[caller_].cold,
        Participant.hot,
        provider_
      );
      // Cold can only delete a record that it has accepted. This means a record
      // at either pendingPayment or live
    } else if (coldIsActiveOnRegister(caller_)) {
      // Cold is requesting the deletion.
      // Get the associated hot address and process the deletion
      _processDeleteRecord(
        coldToHot[caller_],
        caller_,
        Participant.cold,
        provider_
      );
    } else {
      // Address not found, revert
      revert NoRecordFoundForAddress();
    }
  }

  /**
   * @dev _processDeleteRecord: process record deletion
   */
  function _processDeleteRecord(
    address hot_,
    address cold_,
    Participant initiator_,
    uint256 provider_
  ) internal {
    // Delete the register entry
    delete hotToRecord[hot_];

    // Delete the cold to hot mapping:
    delete coldToHot[cold_];

    emit RecordDeleted(initiator_, cold_, hot_, provider_);
  }

  // ======================================================
  // ERC20 CALL ENTRY POINT
  // ======================================================

  /**
   * @dev tokenAPICall: receive a token API call
   */
  function _tokenAPICall(
    address from_,
    address to_,
    uint256 amount_
  ) internal {
    // The final digit of the amount are the action code, the
    // rest of the amount is the provider code

    uint256 actionCode = amount_ % 10;

    require(actionCode > 0 && actionCode < 5, "Unknown EPSAPI amount");

    uint64 providerCode = uint64(amount_ / 10);

    if (actionCode == HOT_NOMINATE_COLD)
      _processNomination(from_, to_, from_, 0, providerCode);
    else if (actionCode == COLD_ACCEPT_HOT) {
      _acceptNominationValidation(to_, from_);
      _acceptNomination(to_, from_, 0, providerCode);
    } else if (actionCode == CHANGE_DELIVERY)
      _updateDeliveryAddress(from_, to_, providerCode);
    else if (actionCode == DELETE_RECORD) _deleteRecord(from_, providerCode);
  }

  // ======================================================
  // CONFIGURATION
  // ======================================================

  /**
   * @dev setRegisterFee: set the fee for accepting a registration:
   */
  function setRegisterFee(uint256 registerFee_) external onlyOwner {
    proxyRegisterFee = registerFee_;
  }

  /**
   * @dev setDeletionNominalEth: set the nominal ETH transfer that represents an address ending a proxy
   */
  function setDeletionNominalEth(uint256 deleteNominalEth_) external onlyOwner {
    deletionNominalEth = deleteNominalEth_;
  }
}