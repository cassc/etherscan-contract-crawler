// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/Constants.sol";
import "./libraries/Ticket.sol";
import "./interfaces/logiumBinaryBet/ILogiumBinaryBetCore.sol";
import "./interfaces/ILogiumCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Logium master contract
/// @notice Contract managing core Logium logic incl. collateral, tickets, opening bets, and system parameters
/// @dev For interaction with this contract please refer to the interface. It's split into easily understood parts.
contract LogiumCore is Ownable, ILogiumCore, Multicall, EIP712 {
  using SafeCast for uint256;
  using SafeCast for int256;
  using Ticket for Ticket.Payload;
  using ECDSA for bytes32;

  /// User structure for storing issuer related state.
  /// Properties:
  /// - freeUSDCCollateral - free collateral (USDC token amount)
  /// - invalidation - value for ticket invalidation
  /// - exists - used to make sure storage slots are not cleared on collateral withdrawal
  /// @dev All properties size was adjusted to fit into one slot
  /// @dev We make a silent assumption that there will never be more than 2^128 USDC (incl. decimals) in circulation.
  struct User {
    uint128 freeUSDCCollateral;
    uint64 invalidation;
    bool exists;
  }

  mapping(address => User) public override users;

  mapping(ILogiumBinaryBetCore => bytes32)
    private fullTypeHashForBetImplementation;

  bytes32 internal constant WITHDRAW_AUTHORIZATION_TYPE =
    keccak256("WithdrawAuthorization(address to,uint256 expiry)");
  bytes32 internal constant INVALIDATION_MESSAGE_TYPE =
    keccak256("InvalidationMessage(uint64 newInvalidation)");

  // solhint-disable-next-line no-empty-blocks
  constructor() EIP712("Logium Exchange", "1") {}

  function allowBetImplementation(ILogiumBinaryBetCore newBetImplementation)
    external
    override
    onlyOwner
  {
    require(
      fullTypeHashForBetImplementation[newBetImplementation] == 0x0,
      "Can't allow allowed"
    );
    bytes memory detailsType = newBetImplementation.DETAILS_TYPE();
    fullTypeHashForBetImplementation[newBetImplementation] = Ticket
      .fullTypeHash(detailsType);
    emit AllowedBetImplementation(newBetImplementation);
  }

  function disallowBetImplementation(
    ILogiumBinaryBetCore blockedBetImplementation
  ) external override onlyOwner {
    require(
      fullTypeHashForBetImplementation[blockedBetImplementation] != 0x0,
      "Can't disallow disallowed"
    );
    fullTypeHashForBetImplementation[blockedBetImplementation] = 0x0;
    emit DisallowedBetImplementation(blockedBetImplementation);
  }

  function isAllowedBetImplementation(ILogiumBinaryBetCore betImplementation)
    external
    view
    override
    returns (bool)
  {
    return fullTypeHashForBetImplementation[betImplementation] != 0x0;
  }

  function withdraw(uint128 amount) external override {
    _withdrawFromTo(msg.sender, msg.sender, amount);
  }

  function withdrawAll() external override returns (uint256) {
    return _withdrawAllFromTo(msg.sender, msg.sender);
  }

  function withdrawFrom(
    uint128 amount,
    WithdrawAuthorization calldata authorization,
    bytes calldata signature
  ) external override returns (address) {
    address from = validateAuthorization(authorization, signature);
    _withdrawFromTo(from, msg.sender, amount);
    return from;
  }

  function withdrawAllFrom(
    WithdrawAuthorization calldata authorization,
    bytes calldata signature
  ) external override returns (address, uint256) {
    address from = validateAuthorization(authorization, signature);
    return (from, _withdrawAllFromTo(from, msg.sender));
  }

  function validateAuthorization(
    WithdrawAuthorization calldata authorization,
    bytes calldata signature
  ) internal view returns (address) {
    require(authorization.to == msg.sender, "Invalid 'to' in authorization");
    require(authorization.expiry > block.timestamp, "Expired authorization");
    address from = _hashTypedDataV4(
      keccak256(
        abi.encode(
          WITHDRAW_AUTHORIZATION_TYPE,
          authorization.to,
          authorization.expiry
        )
      )
    ).recover(signature);
    return from;
  }

  function _withdrawFromTo(
    address from,
    address to,
    uint128 amount
  ) internal {
    User storage user = users[from];

    require(amount > 0, "Can't withdraw zero");
    require(amount <= user.freeUSDCCollateral, "Not enough freeCollateral");
    require(amount < uint128(type(int128).max), "Amount too large");

    user.freeUSDCCollateral -= amount;
    Constants.USDC.transfer(to, amount);

    emit CollateralChange(from, -int128(amount));
  }

  function _withdrawAllFromTo(address from, address to)
    internal
    returns (uint256)
  {
    User storage user = users[from];
    uint128 amount = user.freeUSDCCollateral;

    require(amount > 0, "Can't withdraw zero");
    require(amount < uint128(type(int128).max), "Amount too large");

    user.freeUSDCCollateral = 0;
    Constants.USDC.transfer(to, amount);

    emit CollateralChange(from, -int128(amount));
    return amount;
  }

  function deposit(uint128 amount) external override {
    Constants.USDC.transferFrom(msg.sender, address(this), amount);

    User storage user = users[msg.sender];
    (user.freeUSDCCollateral, user.exists) = (
      user.freeUSDCCollateral + amount,
      true
    );

    emit CollateralChange(msg.sender, int256(uint256(amount)).toInt128());
  }

  function depositTo(address target, uint128 amount) external override {
    Constants.USDC.transferFrom(msg.sender, address(this), amount);

    User storage user = users[target];
    (user.freeUSDCCollateral, user.exists) = (
      user.freeUSDCCollateral + amount,
      true
    );

    emit CollateralChange(target, int256(uint256(amount)).toInt128());
  }

  function invalidate(uint64 newInvalidation) external override {
    _invalidate(msg.sender, newInvalidation);
  }

  function invalidateOther(
    InvalidationMessage calldata invalidationMsg,
    bytes calldata signature
  ) external override {
    address issuer = _hashTypedDataV4(
      keccak256(
        abi.encode(INVALIDATION_MESSAGE_TYPE, invalidationMsg.newInvalidation)
      )
    ).recover(signature);
    _invalidate(issuer, invalidationMsg.newInvalidation);
  }

  function _invalidate(address issuer, uint64 newInvalidation) internal {
    require(
      users[issuer].invalidation <= newInvalidation,
      "Too low invalidation"
    );
    users[issuer].invalidation = newInvalidation;
    emit Invalidation(issuer, newInvalidation);
  }

  function takeTicket(
    bytes memory signature,
    Ticket.Payload memory payload,
    bytes32 detailsHash,
    bytes32 takeParams
  ) external override returns (address) {
    address issuer = recoverTicketMaker(payload, detailsHash, signature);
    address trader = msg.sender;

    require(payload.nonce > users[issuer].invalidation, "Invalidated ticket");
    require(payload.deadline > block.timestamp, "Ticket expired");

    bytes32 hashVal = Ticket.hashVal(payload.details, issuer);
    // contr=0 if this is the first take
    ILogiumBinaryBetCore contr = contractFromTicketHash(
      hashVal,
      payload.betImplementation
    );

    uint256 issuerPrice;
    uint256 traderPrice;

    if (address(contr) == address(0x0))
      (contr, issuerPrice, traderPrice) = createAndIssue(
        hashVal,
        payload,
        detailsHash,
        trader,
        takeParams
      );
    else
      (issuerPrice, traderPrice) = contr.issue(
        detailsHash,
        trader,
        takeParams,
        payload.volume,
        payload.details
      );
    // note with specially crafted betImplementation reentrancy may happen here. In such a case issuer invalidation and freeCollateral may have changed.
    // Thus issuer can't relay on invalidation being triggered by some call made by betImplementation issue function that involves untrusted contracts.
    // Generally bet implementation should not perform any external calls that may call back to LogiumCore.
    // BetImplementation address was accepted by issuer by signing the ticket, thus we can ignore if it would be violated now.

    require(
      issuerPrice <= users[issuer].freeUSDCCollateral,
      "Collateral not available"
    );

    // perform contract issue state changes

    // checks not needed as checked just above, overflow not possible as availableCollateral fits uint128
    unchecked {
      users[issuer].freeUSDCCollateral -= uint128(issuerPrice);
    }

    Constants.USDC.transferFrom(trader, address(contr), traderPrice);
    Constants.USDC.transfer(address(contr), issuerPrice);

    // will not overflow as issuerPrice < availableCollateral <= uint128.max
    emit CollateralChange(issuer, (-int256(issuerPrice)).toInt128());
    emit BetEmitted(
      issuer,
      trader,
      payload.betImplementation,
      takeParams,
      payload.details
    );
    return address(contr);
  }

  function contractFromTicketHash(
    bytes32 hashVal,
    ILogiumBinaryBetCore logiumBinaryBetImplementation
  ) public view override returns (ILogiumBinaryBetCore) {
    ILogiumBinaryBetCore contr = ILogiumBinaryBetCore(
      Clones.predictDeterministicAddress(
        address(logiumBinaryBetImplementation),
        hashVal
      )
    );
    if (Address.isContract(address(contr)))
      //Call from constructor of contr is not possible
      return contr;
    else return ILogiumBinaryBetCore(address(0x0));
  }

  /// @notice Create contract for given ticket and issue specified amount of bet to trader
  /// @dev Uses CREATE2 to make a thin clone on a predictable address
  /// @param payload the bet ticket
  /// @param trader trader/ticket taker address
  /// @param takeParams BetImplementation implementation specific ticket take parameters eg. amount of bet units to open
  /// @return address of the created bet contract
  function createAndIssue(
    bytes32 hashVal,
    Ticket.Payload memory payload,
    bytes32 detailsHash,
    address trader,
    bytes32 takeParams
  )
    internal
    returns (
      ILogiumBinaryBetCore,
      uint256,
      uint256
    )
  {
    ILogiumBinaryBetCore newContr = ILogiumBinaryBetCore(
      Clones.cloneDeterministic(address(payload.betImplementation), hashVal)
    );

    (uint256 issuerPrice, uint256 traderPrice) = newContr.initAndIssue(
      detailsHash,
      trader,
      takeParams,
      payload.volume,
      payload.details
    );
    return (newContr, issuerPrice, traderPrice);
  }

  function recoverTicketMaker(
    Ticket.Payload memory payload,
    bytes32 detailsHash,
    bytes memory signature
  ) internal view returns (address) {
    bytes32 fullTypeHash = fullTypeHashForBetImplementation[
      payload.betImplementation
    ];
    require(fullTypeHash != 0x0, "Disallowed master");
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            fullTypeHash,
            payload.volume,
            payload.nonce,
            payload.deadline,
            payload.betImplementation,
            detailsHash
          )
        )
      ).recover(signature);
  }
}