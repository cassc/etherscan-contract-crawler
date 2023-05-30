// SPDX-License-Identifier: BUSL-1.1

/**
 *
 * @title ArrngController.sol. Core contract for arrng, the world's first
 * pirate themed multi-chain off-chain RNG generator with full
 * on-chain storage of data and signatures.
 *
 * No subscriptions, ERC20 tokens or funds held in escrow.
 *
 * No confusing parameters and hashes. Pay in native token for the
 * randomness you need.
 *
 * @author arrng https://arrng.xyz/
 *
 */

pragma solidity 0.8.19;

import {IArrngController} from "./IArrngController.sol";
import {IArrngConsumer} from "../consumer/IArrngConsumer.sol";
import {IENSReverseRegistrar} from "../ENS/IENSReverseRegistrar.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ArrngController is IArrngController, Ownable, IERC721Receiver {
  using Strings for uint256;

  // Native token required for gas cost to serve RNG:
  uint256 public minimumNativeToken;

  // Address of the oracle:
  address payable public firstMate;

  // Address of the treasury
  address payable public strongbox;

  // Request ID:
  uint256 public skirmishID;

  // Limit on number of returned numbers:
  uint256 public maximumNumberOfNumbers;

  // Address of the ENS reverse registrar to allow assignment of an ENS
  // name to this contract:
  IENSReverseRegistrar public ensLog;

  event ENSLogLoggedInTheCaptainsLogOfLogsMatey(address newENSReverseRegistrar);
  event ColoursNailedToTheMastMatey(string ensName, bytes32 ensNameHash);
  event SmallestTreasureChestSetMatey(uint256 minimumNativeToken);
  event MostNumbersYeCanGetSetMatey(uint256 newNumberLimited);
  event YarrrOfficerOnDeckMatey(address oracle);
  event XMarksTheSpot(address treasury);
  event ArrngRequest(
    address indexed caller,
    uint64 indexed requestId,
    uint32 method,
    uint64 numberOfNumbers,
    uint64 minValue,
    uint64 maxvalue,
    uint64 ethValue,
    address refundAddress
  );
  event ArrngResponse(bytes32 requestTxnHash);
  event ArrngServed(
    uint128 indexed requestId,
    uint128 feeCharged,
    uint256[] randomNumbers,
    string apiResponse,
    string apiSignature
  );
  event ArrngRefundInsufficientTokenForGas(
    address indexed caller,
    uint256 requestId
  );

  /**
   *
   * @dev constructor
   *
   * @param captain_: our master/mistress/other pronoun and commander
   *
   */
  constructor(address captain_) {
    _transferOwnership(captain_);
    maximumNumberOfNumbers = 100;
  }

  /**
   * @dev Walks the plank if called by any account other than the cap'n!
   */
  modifier garrCapnOnly() {
    _checkOwner();
    _;
  }

  /**
   * -------------------------------------------------------------
   * @dev CAPTAIN'S CABIN
   * -------------------------------------------------------------
   */

  /**
   *
   * @dev thisDoBeTheENSLog: set the ENS register address
   *
   * @param ensRegistrar_: ENS Reverse Registrar address
   *
   */
  function thisDoBeTheENSLog(address ensRegistrar_) external garrCapnOnly {
    ensLog = IENSReverseRegistrar(ensRegistrar_);
    emit ENSLogLoggedInTheCaptainsLogOfLogsMatey(ensRegistrar_);
  }

  /**
   *
   * @dev nailColoursToTheMast: used to set reverse record so interactions with this contract
   * are easy to identify
   *
   * @param ensName_: string ENS name
   *
   */
  function nailColoursToTheMast(string memory ensName_) external garrCapnOnly {
    bytes32 ensNameHash = ensLog.setName(ensName_);
    emit ColoursNailedToTheMastMatey(ensName_, ensNameHash);
    (ensName_);
  }

  /**
   *
   * @dev thisDoBeTheSmallestTreasureChest: set a new value of required native token for gas
   *
   * @param minGasFee_: the new minimum native token per call
   *
   */
  function thisDoBeTheSmallestTreasureChest(
    uint256 minGasFee_
  ) external garrCapnOnly {
    minimumNativeToken = minGasFee_;
    emit SmallestTreasureChestSetMatey(minGasFee_);
  }

  /**
   *
   * @dev thisDoBeTheMostNumbersYeCanGet: set a new max number of numbers
   *
   * @param maxNumbersPerTxn_: the new max requested numbers
   *
   */
  function thisDoBeTheMostNumbersYeCanGet(
    uint256 maxNumbersPerTxn_
  ) external garrCapnOnly {
    maximumNumberOfNumbers = maxNumbersPerTxn_;
    emit MostNumbersYeCanGetSetMatey(maxNumbersPerTxn_);
  }

  /**
   *
   * @dev thisDoBeTheFirstMate: set a new oracle address
   *
   * @param oracle_: the new oracle address
   *
   */
  function thisDoBeTheFirstMate(address payable oracle_) external garrCapnOnly {
    require(oracle_ != address(0), "Are ye mad me hearty?!");
    firstMate = oracle_;
    emit YarrrOfficerOnDeckMatey(oracle_);
  }

  /**
   *
   * @dev thisDoBeTheStrongbox: set a new treasury address
   *
   * @param treasury_: the new treasury address
   *
   */
  function thisDoBeTheStrongbox(
    address payable treasury_
  ) external garrCapnOnly {
    require(treasury_ != address(0), "Are ye mad me hearty?!");
    strongbox = treasury_;
    emit XMarksTheSpot(treasury_);
  }

  /**
   *
   * @dev getGold: cap'n can pull native token to the strongbox!
   *
   * @param amount_: amount to withdraw
   *
   */
  function getGold(uint256 amount_) external garrCapnOnly {
    require(strongbox != address(0), "Are ye mad me hearty?!");
    processPayment_(strongbox, amount_);
  }

  /**
   *
   * @dev getDubloons: cap'n can pull tokens to the strongbox!
   *
   * @param erc20Address_: the contract address for the token
   * @param amount_: amount to withdraw
   *
   */
  function getDubloons(
    address erc20Address_,
    uint256 amount_
  ) external garrCapnOnly {
    require(strongbox != address(0), "Are ye mad me hearty?!");
    IERC20(erc20Address_).transfer(strongbox, amount_);
  }

  /**
   *
   * @dev getGems: Pull ERC721s (likely only the ENS
   * associated with this contract) to the strongbox.
   *
   * @param erc721Address_: The token contract for the withdrawal
   * @param tokenIDs_: the list of tokenIDs for the withdrawal
   *
   */
  function getGems(
    address erc721Address_,
    uint256[] memory tokenIDs_
  ) external garrCapnOnly {
    require(strongbox != address(0), "Are ye mad me hearty?!");
    for (uint256 i = 0; i < tokenIDs_.length; ) {
      IERC721(erc721Address_).transferFrom(
        address(this),
        strongbox,
        tokenIDs_[i]
      );
      unchecked {
        ++i;
      }
    }
  }

  /**
   *
   * @dev onERC721Received: allow transfer from owner (for the ENS token).
   *
   * @param from_: used to check this is only from the contract owner
   *
   */
  function onERC721Received(
    address,
    address from_,
    uint256,
    bytes memory
  ) external view returns (bytes4) {
    if (from_ == owner()) {
      return this.onERC721Received.selector;
    } else {
      return ("");
    }
  }

  /**
   * -------------------------------------------------------------
   * @dev HOIST THE MAINSAIL!!
   * -------------------------------------------------------------
   */

  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_
  ) external payable returns (uint256 uniqueID_) {
    return requestRandomWords(numberOfNumbers_, tx.origin);
  }

  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_,
    address refundAddress_
  ) public payable returns (uint256 uniqueID_) {
    return requestWithMethod(numberOfNumbers_, 0, 0, refundAddress_, 0);
  }

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_
  ) public payable returns (uint256 uniqueID_) {
    return
      requestRandomNumbersInRange(
        numberOfNumbers_,
        minValue_,
        maxValue_,
        tx.origin
      );
  }

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_
  ) public payable returns (uint256 uniqueID_) {
    return
      requestWithMethod(
        numberOfNumbers_,
        minValue_,
        maxValue_,
        refundAddress_,
        1
      );
  }

  /**
   *
   * @dev requestWithMethod: public method to allow calls specifying the
   * arrng method, allowing functionality to be extensible without
   * requiring a new controller contract
   * requestWithMethod is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param method_: the arrng method to call
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestWithMethod(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    uint32 method_
  ) public payable returns (uint256 uniqueID_) {
    return
      requestWithMethod(
        numberOfNumbers_,
        minValue_,
        maxValue_,
        tx.origin,
        method_
      );
  }

  /**
   *
   * @dev requestWithMethod: public method to allow calls specifying the
   * arrng method, allowing functionality to be extensible without
   * requiring a new controller contract
   * requestWithMethod is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   * @param method_: the arrng method to call
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestWithMethod(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_,
    uint32 method_
  ) public payable returns (uint256 uniqueID_) {
    return
      ahoy_(
        msg.sender,
        msg.value,
        method_,
        numberOfNumbers_,
        minValue_,
        maxValue_,
        refundAddress_
      );
  }

  /**
   *
   * @dev ahoy_: request RNG
   *
   * @param caller_: the msg.sender that has made this call
   * @param payment_: the msg.value sent with the call
   * @param method_: the method for the oracle to execute
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of ununsed native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function ahoy_(
    address caller_,
    uint256 payment_,
    uint256 method_,
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_
  ) internal returns (uint256 uniqueID_) {
    skirmishID += 1;

    if (payment_ < minimumNativeToken) {
      string memory message = string.concat(
        "Insufficient native token for gas, minimum is ",
        minimumNativeToken.toString(),
        ". You may need more depending on the number of numbers requested and prevailing gas cost. All excess refunded, less txn fee."
      );
      require(payment_ >= minimumNativeToken, message);
    }

    require(numberOfNumbers_ > 0, "GarrrNotEnoughNumbers");

    require(numberOfNumbers_ <= maximumNumberOfNumbers, "GarrrTooManyNumbers");

    processPayment_(firstMate, payment_);

    emit ArrngRequest(
      caller_,
      uint64(skirmishID),
      uint32(method_),
      uint64(numberOfNumbers_),
      uint64(minValue_),
      uint64(maxValue_),
      uint64(payment_),
      refundAddress_
    );

    return (skirmishID);
  }

  /**
   *
   * @dev landHo: serve result of the call
   *
   * @param skirmishID_: unique request ID
   * @param ship_: the contract to call
   * @param requestTxnHash_: the txn hash of the original request
   * @param responseCode_: 0 is success, !0 = failure
   * @param barrelONum_: the array of random integers
   * @param refundAddress_: the address for refund of native token not used for gas
   * @param apiResponse_: the response from the off-chain rng provider
   * @param apiSignature_: signature for the rng response
   * @param feeCharged_: the fee for this rng
   *
   */
  function landHo(
    uint256 skirmishID_,
    address ship_,
    bytes32 requestTxnHash_,
    uint256 responseCode_,
    uint256[] calldata barrelONum_,
    address refundAddress_,
    string calldata apiResponse_,
    string calldata apiSignature_,
    uint256 feeCharged_
  ) external payable {
    require(msg.sender == firstMate, "BelayThatFirstMateOnly");
    emit ArrngResponse(requestTxnHash_);
    if (responseCode_ == 0) {
      arrngSuccess_(
        skirmishID_,
        ship_,
        barrelONum_,
        refundAddress_,
        apiResponse_,
        apiSignature_,
        msg.value,
        feeCharged_
      );
    } else {
      arrngFailure_(skirmishID_, ship_, refundAddress_, msg.value);
    }
  }

  /**
   *
   * @dev arrngSuccess_: process a successful response
   * arrng can be requested by a contract call or from an EOA. In the
   * case of a contract call we call the external method that the calling
   * contract must include to perform downstream processing using the rng. In
   * the case of an EOA call this is a user requesting signed, verifiable rng
   * that is stored on-chain (through emitted events), that they intend to use
   * manually. So in the case of the EOA call we emit the results and send them
   * the refund, i.e. no method call.
   *
   * @param skirmishID_: unique request ID
   * @param ship_: the contract to call
   * @param barrelONum_: the array of random integers
   * @param refundAddress_: the address for unused token refund
   * @param apiResponse_: the response from the off-chain rng provider
   * @param apiSignature_: signature for the rng response
   * @param amount_: the amount of unused native toke to refund
   * @param feeCharged_: the fee for this rng
   *
   */
  function arrngSuccess_(
    uint256 skirmishID_,
    address ship_,
    uint256[] calldata barrelONum_,
    address refundAddress_,
    string calldata apiResponse_,
    string calldata apiSignature_,
    uint256 amount_,
    uint256 feeCharged_
  ) internal {
    // Success
    emit ArrngServed(
      uint128(skirmishID_),
      uint128(feeCharged_),
      barrelONum_,
      apiResponse_,
      apiSignature_
    );
    if (ship_.code.length > 0) {
      // If the calling contract is the same as the refund address then return
      // ramdomness and the refund in a single function call:
      if (refundAddress_ == ship_) {
        IArrngConsumer(ship_).yarrrr{value: amount_}(skirmishID_, barrelONum_);
      } else {
        IArrngConsumer(ship_).yarrrr{value: 0}(skirmishID_, barrelONum_);
        processPayment_(refundAddress_, amount_);
      }
    } else {
      // Refund the EOA any native token not used for gas:
      processPayment_(refundAddress_, amount_);
    }
  }

  /**
   *
   * @dev arrngFailure_: process a failed response
   * Refund any native token not used for gas:
   *
   * @param skirmishID_: unique request ID
   * @param ship_: the contract to call
   * @param refundAddress_: the address for the refund
   * @param amount_: the amount for the refund
   *
   */
  function arrngFailure_(
    uint256 skirmishID_,
    address ship_,
    address refundAddress_,
    uint256 amount_
  ) internal {
    // Failure
    emit ArrngRefundInsufficientTokenForGas(ship_, skirmishID_);
    processPayment_(refundAddress_, amount_);
  }

  /**
   *
   * @dev processPayment_: central function for payment processing
   *
   * @param payeeAddress_: address to pay.
   * @param amount_: amount to pay.
   *
   */
  function processPayment_(address payeeAddress_, uint256 amount_) internal {
    (bool success, ) = payeeAddress_.call{value: amount_}("");
    require(success, "TheTransferWalkedThePlank!(failed)");
  }
}