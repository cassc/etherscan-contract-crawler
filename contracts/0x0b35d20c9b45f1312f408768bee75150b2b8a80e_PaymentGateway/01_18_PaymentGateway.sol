// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EIP712, ECDSA} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPaymentGateway} from "./IPaymentGateway.sol";

/// @title PaymentGateway
/// @author @lopotras
/// @notice Contract used to process one-time payments via Sphere Payment Link. Supports native network currency and ERC20 tokens.
contract PaymentGateway is
  IPaymentGateway,
  ReentrancyGuard,
  Ownable2Step,
  EIP712
{
  using SafeERC20 for IERC20;

  ///////////////////// CONSTANTS /////////////////////

  /// Version's numeric component.
  string private constant _VERSION_ID = "v0.4";

  /// Hash of typed data structure, used in EP712 signatures. Not exposed via any getter.
  /// keccak256("Payment(bytes32 paymentId,uint256 amount,address token,address receiver,uint256 deadline)")
  bytes32 private constant _PAYMENT_TYPEHASH =
    0x547a9282e76bbaf5e088ab694b5ae1f0deb331dc55506385833f49cdaad89198;

  ///////////////////// STORAGE VARIABLES /////////////////////

  /// Address of signer used to approve payments.
  address private _signer;

  /// Mapping of approved ERC20 tokens for payments.
  mapping(address token => bool isTokenApproved) private _supportedTokens;
  /// Mapping of used signatures.
  mapping(bytes signature => bool isSignatureUsed) private _signatures;

  ///////////////////// CONSTRUCTOR /////////////////////

  /// @param setName Contract's name used to build EIP712 domain.
  /// @param setNetwork String identifying target network. Used to build version for EIP712 domain.
  /// @param setSigner Address of signer used to approve payments.
  constructor(
    string memory setName,
    string memory setNetwork,
    address setSigner
  ) EIP712(setName, string.concat(setNetwork, "-", _VERSION_ID)) {
    if (setSigner == address(0)) revert SignerAddressZero();
    _signer = setSigner;
  }

  ///////////////////// EXTERNAL FUNCTIONS /////////////////////

  /// Entry point for ERC20 token payments.
  /// @dev Each ERC20 token must be pre-approved, see `_supportedTokens`.
  /// @dev In order to avoid processing unregistered payment requests, payment data must be signed by `signer`.
  ///
  /// @param paymentId Unique identifier of an idividual payment.
  /// @param amount Amount of payment token to be tranferred in wei.
  /// @param token Address of payment token contract.
  /// @param receiver Address to which `amount` of `token` will be sent.
  /// @param deadline Timestamp limiting payment execution.
  /// @param signature Signature confirming data approval.
  function pay(
    bytes32 paymentId,
    uint256 amount,
    address token,
    address receiver,
    uint256 deadline,
    bytes memory signature
  ) external override nonReentrant {
    // Check if `token` parameter is correct.
    if (token == address(0)) revert ZeroAddressToken();
    if (!_supportedTokens[token]) revert TokenNotAllowed();

    // Verify `receiver`, `deadline` and `signature`.
    _verifyPayment(paymentId, amount, token, receiver, deadline, signature);

    // Transfer tokens directly from `msg.sender` to `receiver`.
    IERC20(token).safeTransferFrom(msg.sender, receiver, amount);

    // Emit if token transfer was successful.
    emit PaymentExecuted(paymentId, msg.sender);
  }

  /// Entry point for ETH (or other native network currency) payments.
  /// @dev In order to avoid processing unregistered payment requests, payment data must be signed by `signer`.
  ///
  /// @param paymentId Unique identifier of an idividual payment.
  /// @param amount Amount of ETH to be tranferred in wei.
  /// @param receiver Address to which `amount` of ETH will be sent.
  /// @param deadline Timestamp limiting payment execution.
  /// @param signature Signature confirming data approval.
  function payETH(
    bytes32 paymentId,
    uint256 amount,
    address receiver,
    uint256 deadline,
    bytes memory signature
  ) external payable override nonReentrant {
    // Check if `msg.value` is consistent with supplied payment data.
    if (msg.value != amount) revert ETHPaymentWrongValue();

    // Verify `receiver`, `deadline` and `signature`.
    _verifyPayment(
      paymentId,
      amount,
      address(0),
      receiver,
      deadline,
      signature
    );

    // Transfer ETH passed with this call by `msg.sender` to receiver.
    (bool success, ) = receiver.call{value: msg.value}("");
    if (!success) revert EthTransferFailed();

    // Emit if ETH transfer was successful.
    emit PaymentExecuted(paymentId, msg.sender);
  }

  ///////////////////// GETTERS /////////////////////

  /// Expose private `_VERSION_ID`.
  ///
  /// @return Current PaymentGateway version identifier.
  function getVersionId() external pure returns (string memory) {
    return _VERSION_ID;
  }

  /// Expose private `_signer`.
  ///
  /// @return Current signer.
  function getSigner() external view returns (address) {
    return _signer;
  }

  /// View if `token` is approved for payments.
  ///
  /// @param token ERC20 token address to be verified.
  /// @return `true` if token is approved. Defaults to `false`.
  function getIsTokenSupported(address token) external view returns (bool) {
    return _supportedTokens[token];
  }

  /// View if `signature` has already been used.
  ///
  /// @param signature EIP712 compliant singature to be verified.
  /// @return `true` if signature has been used. Defaults to `false`.
  function getIsSignatureUsed(
    bytes calldata signature
  ) external view returns (bool) {
    return _signatures[signature];
  }

  ///////////////////// OWNER FUNCTIONS /////////////////////

  /// Restricted function to update `_signer`.
  ///
  /// @param newSigner Non-zero new signer address.
  function updateSigner(address newSigner) external onlyOwner {
    if (newSigner == address(0)) revert SignerAddressZero();
    if (newSigner == _signer) revert SameSigner();

    // Save old `_signer` to be emitted in event.
    address oldSigner = _signer;
    _signer = newSigner;

    emit SignerUpdated(newSigner, oldSigner);
  }

  /// Restricted function to add ERC20 token to approved payment tokens.
  ///
  /// @param token ERC20 token address to be approved as valid payment token.
  function addToken(address token) external onlyOwner {
    if (token == address(0)) revert TokenAddressZero();
    if (_supportedTokens[token]) revert AlreadyAllowed();

    // Add `token` to approved tokens.
    _supportedTokens[token] = true;

    emit TokenAdded(token);
  }

  /// Restricted function to remove ERC20 token from approved payment tokens.
  ///
  /// @param token ERC20 token address to be removed from valid payment tokens.
  function removeToken(address token) external onlyOwner {
    if (token == address(0)) revert TokenAddressZero();
    if (!_supportedTokens[token]) revert AlreadyRemoved();

    // remove `token` from approved tokens.
    _supportedTokens[token] = false;

    emit TokenRemoved(token);
  }

  /// Restricted function to be used in emergency situations to recover ERC20 tokens sent to this contract by mistake.
  ///
  /// @param token ERC20 compliant token to be recovered from this contract.
  function recover(IERC20 token) external onlyOwner {
    if (address(token) == address(0)) revert TokenAddressZero();
    if (token.balanceOf(address(this)) == 0) revert NoBalance();
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  ///////////////////// INTERNAL FUNCTIONS /////////////////////

  /// Internal function used to verify commmon parameters for `pay` and `payETH` functions.
  ///
  /// @param paymentId Unique identifier of an idividual payment.
  /// @param amount Amount of payment token to be tranferred in wei
  /// @param token Address of payment token contract.
  /// @param receiver Address to which `amount` of `token` will be sent.
  /// @param deadline Timestamp limiting payment execution.
  /// @param signature Signature confirming data approval.
  function _verifyPayment(
    bytes32 paymentId,
    uint256 amount,
    address token,
    address receiver,
    uint256 deadline,
    bytes memory signature
  ) internal {
    if (receiver == address(0)) revert ReceiverAddressZero();
    if (deadline < block.timestamp) revert PastDeadline();
    if (_signatures[signature]) revert SignatureUsed();

    // Build EIP712 compliant typed structred data.
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          _PAYMENT_TYPEHASH,
          paymentId,
          amount,
          token,
          receiver,
          deadline
        )
      )
    );

    // Verify if signature is correct.
    address recovered = ECDSA.recover(digest, signature);
    if (recovered == address(0)) revert InvalidSignature();
    if (recovered != _signer) revert WrongSigner();

    // Mark signature as used.
    _signatures[signature] = true;
  }
}