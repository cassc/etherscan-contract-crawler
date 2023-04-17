// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IBurnable.sol";
import "./utils/Errors.sol";
import "./utils/ERC20Fixed.sol";
import "./utils/Allowlistable.sol";
import "./utils/math/FixedPoint.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract BridgeEndpoint is
  OwnableUpgradeable,
  AccessControlEnumerableUpgradeable,
  EIP712Upgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  Allowlistable
{
  using ERC20Fixed for ERC20;
  using FixedPoint for uint256;

  bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
  bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
  bytes32 public constant APPROVED_TOKEN = keccak256("APPROVED_TOKEN");
  uint256 public constant MAX_REQUIRED_VALIDATORS = 100;

  struct SignaturePackage {
    bytes32 orderHash;
    address signer;
    bytes signature;
  }

  uint256 public requiredValidators;

  // constant, subject to governance
  mapping(bytes32 => bool) public orderSent;
  mapping(bytes32 => mapping(address => bool)) public orderValidatedBy;
  mapping(address => uint256) public feePerToken;
  mapping(address => uint256) public minAmountPerToken;
  mapping(address => uint256) public maxAmountPerToken;
  mapping(address => bool) public burnable;

  // variable
  mapping(address => uint256) public accruedFeePerToken;
  mapping(address => uint256) public feePctPerToken;
  mapping(address => uint256) public minFeePerToken;

  event TransferToWrapEvent(
    address indexed from,
    address indexed token,
    string settle,
    uint256 amount,
    uint256 fee
  );
  event TransferToUnwrapEvent(
    bytes32 orderHash,
    bytes32 salt,
    address indexed recipient,
    address indexed token,
    uint256 amount
  );
  event SetRequiredValidatorsEvent(uint256 requiredValidators);
  event SetApprovedTokenEvent(
    address indexed token,
    bool approved,
    uint256 feePct,
    uint256 minFee,
    uint256 minAmount,
    uint256 maxAmount
  );
  event CollectAccruedFeeEvent(address indexed token, uint256 collectAmount);
  event SetMinFeePerTokenEvent(address indexed token, uint256 minFee);

  modifier onlyApprovedToken(address token) {
    _require(hasRole(APPROVED_TOKEN, token), Errors.INVALID_TOKEN);
    _;
  }

  function initialize(
    address owner,
    string memory name,
    string memory version,
    uint256 _requiredValidators
  ) external initializer {
    _require(
      _requiredValidators < MAX_REQUIRED_VALIDATORS,
      Errors.INVALID_REQUIRED_VALIDATORS
    );
    __Ownable_init();
    __AccessControlEnumerable_init();
    __EIP712_init(name, version);
    __ReentrancyGuard_init();
    __Pausable_init();
    __Allowlistable_init();

    _transferOwnership(owner);
    _grantRole(DEFAULT_ADMIN_ROLE, owner);
    requiredValidators = _requiredValidators;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // external functions

  // @dev amount must be in 18-digit fixed
  function transferToWrap(
    address token,
    uint256 amount,
    string calldata settleData
  )
    external
    nonReentrant
    whenNotPaused
    onlyAllowlisted
    onlyApprovedToken(token)
  {
    _require(
      amount <= maxAmountPerToken[token] && amount >= minAmountPerToken[token],
      Errors.INVALID_AMOUNT
    );
    _require(amount > minFeePerToken[token], Errors.AMOUNT_SMALLER_THAN_FEE);

    uint256 feeDeducted = amount.mulDown(feePctPerToken[token]).max(
      minFeePerToken[token]
    );
    accruedFeePerToken[token] = accruedFeePerToken[token].add(feeDeducted);

    if (burnable[token]) {
      IBurnable(token).burnFrom(msg.sender, amount.sub(feeDeducted));
      ERC20(token).transferFromFixed(msg.sender, address(this), feeDeducted);
    } else {
      ERC20(token).transferFromFixed(msg.sender, address(this), amount);
    }

    emit TransferToWrapEvent(
      msg.sender,
      token,
      settleData,
      amount.sub(feeDeducted),
      feeDeducted
    );
  }

  // read-only functions

  function domainSeparatorV4() external view returns (bytes32) {
    return _domainSeparatorV4();
  }

  function hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
    return _hashTypedDataV4(structHash);
  }

  // priviledged functions

  // send unwrapped tokens to user
  // @dev salt should be tx hash of source chain
  // @dev amount must be in 18-digit fixed
  function transferToUnwrap(
    address token,
    address recipient,
    uint256 amount,
    bytes32 salt,
    SignaturePackage[] calldata proofs
  )
    external
    onlyRole(RELAYER_ROLE)
    nonReentrant
    whenNotPaused
    onlyApprovedToken(token)
  {
    bytes32 orderHash = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "Order(address recipient,address token,uint256 amountInFixed,bytes32 salt)"
          ),
          recipient,
          token,
          amount,
          salt
        )
      )
    );
    _require(proofs.length >= requiredValidators, Errors.INSUFFICIENT_PROOFS);
    _require(!orderSent[orderHash], Errors.ORDER_ALREADY_SENT);

    for (uint256 i = 0; i < proofs.length; i++) {
      _require(
        !orderValidatedBy[orderHash][proofs[i].signer],
        Errors.DUPLICATE_SIGNATURE
      );
      _require(proofs[i].orderHash == orderHash, Errors.ORDER_HASH_MISMATCH);
      _require(
        hasRole(VALIDATOR_ROLE, proofs[i].signer),
        Errors.SIGNER_VALIDATOR_MISMATCH
      );
      _require(
        proofs[i].signer ==
          ECDSAUpgradeable.recover(proofs[i].orderHash, proofs[i].signature),
        Errors.INVALID_SIGNATURE
      );

      orderValidatedBy[orderHash][proofs[i].signer] = true;
    }
    orderSent[orderHash] = true;

    if (burnable[token]) {
      IBurnable(token).mint(recipient, amount);
    } else {
      ERC20(token).transferFixed(recipient, amount);
    }

    emit TransferToUnwrapEvent(orderHash, salt, recipient, token, amount);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setMinFeePerToken(
    address _token,
    uint256 _minFee
  ) external onlyOwner {
    minFeePerToken[_token] = _minFee;
    emit SetMinFeePerTokenEvent(_token, _minFee);
  }

  function setRequiredValidators(
    uint256 _requiredValidators
  ) external onlyOwner {
    _require(
      _requiredValidators < MAX_REQUIRED_VALIDATORS,
      Errors.INVALID_REQUIRED_VALIDATORS
    );
    requiredValidators = _requiredValidators;
    emit SetRequiredValidatorsEvent(requiredValidators);
  }

  function setApprovedToken(
    address token,
    bool approved,
    bool isBurnable,
    uint256 feePct,
    uint256 minFee,
    uint256 minAmount,
    uint256 maxAmount
  ) external onlyOwner {
    _require(token != address(0), Errors.ZERO_TOKEN_ADDRESS);
    _require(ERC20(token).decimals() <= 18, Errors.INVALID_TOKEN_DECIMALS);
    if (approved) {
      _grantRole(APPROVED_TOKEN, token);
    } else {
      _revokeRole(APPROVED_TOKEN, token);
    }
    feePctPerToken[token] = feePct;
    minFeePerToken[token] = minFee;
    minAmountPerToken[token] = minAmount;
    maxAmountPerToken[token] = maxAmount;
    burnable[token] = isBurnable;
    emit SetApprovedTokenEvent(
      token,
      approved,
      feePct,
      minFee,
      minAmount,
      maxAmount
    );
  }

  function collectAccruedFee(
    address token
  ) external onlyOwner onlyApprovedToken(token) {
    uint256 collectAmount = 0;
    if (accruedFeePerToken[token] > 0) {
      collectAmount = accruedFeePerToken[token];
      accruedFeePerToken[token] = 0;
      ERC20(token).transferFixed(msg.sender, collectAmount);
    }
    emit CollectAccruedFeeEvent(token, collectAmount);
  }

  function grantValidators(address[] calldata added) external onlyOwner {
    for (uint256 i = 0; i < added.length; i++) {
      _grantRole(VALIDATOR_ROLE, added[i]);
    }
  }

  function revokeValidators(address[] calldata removed) external onlyOwner {
    for (uint256 i = 0; i < removed.length; i++) {
      _revokeRole(VALIDATOR_ROLE, removed[i]);
    }
  }

  function onAllowlist() external onlyOwner {
    _onAllowlist();
  }

  function offAllowlist() external onlyOwner {
    _offAllowlist();
  }

  function addAllowlist(address[] memory _allowed) external onlyOwner {
    _addAllowlist(_allowed);
  }

  function removeAllowlist(address[] memory _removed) external onlyOwner {
    _removeAllowlist(_removed);
  }
}