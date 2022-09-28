// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./FeesDistributor.sol";

contract Gateway is Ownable, ReentrancyGuard {
  using SafeERC20 for ERC20Permit;


  // ==== Structs ==== //

  /**
   * @notice
   * This struct is used to represent a transaction
   */
  struct Transaction {
    string id;
    string merchantId;
    uint256 date;
    uint256 amount;
    uint256 fees;
    address payer;
  }

  /**
   * @notice
   * This struct is used to represent a merchant
   */
  struct Merchant {
    string id;
    bool enabled;
    address beneficiary;
    uint16 feesPercentage;
    mapping(string => Transaction) transactions;
  }


  // ==== State ==== //

  ERC20Permit public token;
  FeesDistributor public feesDistributor;
  mapping(string => Merchant) merchants;


  // ==== Events ==== //

  event FeesDistributorChanged(address oldFeesDistributor, address newFeesDistributor);
  event MerchantAdded(string merchantId, address beneficiary, uint16 feesPercentage);
  event MerchantStatusChanged(string merchantId, bool enabled);
  event MerchantBeneficiaryChanged(string merchantId, address oldBeneficiary, address newBeneficiary);
  event MerchantFeesPercentageChanged(string merchantId, uint16 oldFeesPercentage, uint16 newFeesPercentage);
  event PaymentMade(string indexed merchantId, string transactionId, Transaction transaction);


  // ==== Modifiers ==== //

  /**
   * @dev Check if the caller is the merchant or the owner
   */
  modifier onlyMerchantOrOwner(string calldata merchantId) {
    require(
      merchants[merchantId].beneficiary == _msgSender() || owner() == _msgSender(),
      "Caller is not the merchant beneficiary, nor the owner"
    );
    _;
  }

  /**
   * @dev Check if the merchant exists
   */
  modifier merchantExists(string calldata merchantId) {
    require(
      merchants[merchantId].beneficiary != address(0),
      "Merchant does not exist"
    );
    _;
  }


  // ==== Constructor ==== //

  /**
   * @dev constructor
   * @param _token Address of the BEP20
   * @param _feesDistributor Address of the fees distributor
   */
  constructor(
    address _token,
    address _feesDistributor
  )
  {
    require(
      _token != address(0),
      "Token address is not valid"
    );
    token = ERC20Permit(_token);

    require(
      _feesDistributor != address(0),
      "FeesDistributor address is not valid"
    );
    feesDistributor = FeesDistributor(_feesDistributor);
  }


  // ==== Public methods ==== //

  /**
   * @notice Pay transaction
   * @param merchantId The id of the merchant
   * @param transactionId The id of the transaction
   * @param amount The amount of the transaction
   * @param owner The address of the payer (owner of the spent tokens)
   * @param deadline Permit deadline
   * @param v ECDSA v value
   * @param r ECDSA r value
   * @param s ECDSA s value
   */
  function pay(
    string calldata merchantId,
    string calldata transactionId,
    uint256 amount,
    address owner,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
    nonReentrant
    merchantExists(merchantId)
  {
    require(
      merchants[merchantId].transactions[transactionId].payer == address(0),
      "This transaction has already been paid"
    );

    require(
      merchants[merchantId].enabled == true,
      "Merchant is disabled"
    );

    // Calculate fees
    uint fees;
    if (merchants[merchantId].feesPercentage > 0) {
      fees = amount * merchants[merchantId].feesPercentage / 10000;
    }

    // Log the transaction
    Transaction memory transaction = Transaction(
      transactionId,
      merchantId,
      block.timestamp,
      amount,
      fees,
      owner
    );
    merchants[merchantId].transactions[transactionId] = transaction;

    // Use payer signature to approve this contract
    token.permit(
      owner,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );

    // Transfer funds to this contract
    token.safeTransferFrom(
      owner,
      address(this),
      amount
    );

    // Transfer funds to merchant beneficiary
    if ((amount - fees) > 0) {
      token.safeTransfer(
        merchants[merchantId].beneficiary,
        amount - fees
      );
    }

    // Distribute fees
    if (fees > 0) {
      token.safeIncreaseAllowance(address(feesDistributor), fees);
      feesDistributor.distribute("Gateway", fees);
    }

    // Emit event
    emit PaymentMade(merchantId, transactionId, transaction);
  }


  // ==== Views ==== //

  /**
   * @notice Get transaction
   * @param merchantId The id of the merchant
   * @param transactionId The id of the transaction
   */
  function getTransaction(
    string calldata merchantId,
    string calldata transactionId
  )
    external
    view
    merchantExists(merchantId)
    returns (Transaction memory transaction)
  {
    transaction = merchants[merchantId].transactions[transactionId];
  }


  // ==== Restricted methods ==== //

  /**
   * @notice Add a new merchant
   * @param _id The id of the merchant
   * @param _beneficiary The beneficiary of the merchant
   * @param _feesPercentage Fees applied to this merchant
   */
  function addMerchant(
    string calldata _id,
    address _beneficiary,
    uint16 _feesPercentage
  )
    external
    onlyOwner
  {
    require(
      bytes(_id).length > 0,
      "merchantId cannot be empty"
    );

    require(
      merchants[_id].beneficiary == address(0),
      "Merchant already exists"
    );

    require(
      _beneficiary != address(0),
      "Beneficiary address is not valid"
    );

    require(
      _feesPercentage <= 10000,
      "Fees percentage is not valid"
    );

    merchants[_id].id = _id;
    merchants[_id].enabled = true;
    merchants[_id].beneficiary = _beneficiary;
    merchants[_id].feesPercentage = _feesPercentage;

    emit MerchantAdded(_id, _beneficiary, _feesPercentage);
  }

  /**
   * @notice Enable/disabled a merchant
   * @param _id The id of the merchant
   * @param _enabled The new enabled status
   */
  function changeMerchantStatus(
    string calldata _id,
    bool _enabled
  )
    external
    onlyOwner
    merchantExists(_id)
  {
    require(
      merchants[_id].enabled != _enabled,
      "Merchant status is already set to this value"
    );

    merchants[_id].enabled = _enabled;
    emit MerchantStatusChanged(_id, _enabled);
  }

  /**
   * @notice Allows merchant to change its beneficiary address
   * @param _id The id of the merchant
   * @param _beneficiary The new beneficiary address
   */
  function changeMerchantBeneficiary(
    string calldata _id,
    address _beneficiary
  )
    external
    onlyMerchantOrOwner(_id)
    merchantExists(_id)
  {
    require(
      _beneficiary != address(0),
      "Beneficiary address is not valid"
    );

    require(
      merchants[_id].beneficiary != _beneficiary,
      "Merchant beneficiary is already set to this value"
    );

    address oldBeneficiary = merchants[_id].beneficiary;
    merchants[_id].beneficiary = _beneficiary;
    emit MerchantBeneficiaryChanged(_id, oldBeneficiary, _beneficiary);
  }

  /**
   * @notice Change fees percentage of a merchant
   * @param _id The id of the merchant
   * @param _feesPercentage The new fees percentage for the given merchant
   */
  function changeMerchantFeesPercentage(
    string calldata _id,
    uint16 _feesPercentage
  )
    external
    onlyOwner
    merchantExists(_id)
  {
    require(
      _feesPercentage <= 10000,
      "Fees percentage is not valid"
    );

    require(
      merchants[_id].feesPercentage != _feesPercentage,
      "Merchant fees percentage is already set to this value"
    );

    uint16 oldFeesPercentage = merchants[_id].feesPercentage;
    merchants[_id].feesPercentage = _feesPercentage;
    emit MerchantFeesPercentageChanged(_id, oldFeesPercentage, _feesPercentage);
  }

  /**
   * @notice Change the fees distributor address
   * @param _feesDistributor The new fees distributor address
   */
  function changeFeesDistributor(
    address _feesDistributor
  )
    external
    onlyOwner
  {
    require(
      _feesDistributor != address(0),
      "FeesDistributor address is not valid"
    );

    require(
      address(feesDistributor) != _feesDistributor,
      "Fees distributor cannot be the same as the old one"
    );

    address oldFeesDistributor = address(feesDistributor);
    feesDistributor = FeesDistributor(_feesDistributor);
    emit FeesDistributorChanged(oldFeesDistributor, _feesDistributor);
  }
}