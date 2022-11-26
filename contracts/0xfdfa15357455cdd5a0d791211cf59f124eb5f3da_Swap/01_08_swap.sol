// SPDX-License-Identifier: MIT

/* solhint-disable var-name-mixedcase */
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "ISwap.sol";

/**
 * @title TradeOffer.fi forked and modified from Airswap under MIT
 * @notice https://www.tradeoffer.fi | https://airswap.com
 * 
 */
contract Swap is ISwap, Ownable {
  using SafeERC20 for IERC20;

  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

  bytes32 public constant ORDER_TYPEHASH =
    keccak256(
      "Order(uint256 nonce,uint256 expiry,address signerWallet,address signerToken,uint256 signerAmount,uint256 protocolFee,address senderWallet,address senderToken,uint256 senderAmount)"
    );

  bytes32 public constant DOMAIN_NAME = keccak256("TROF");
  bytes32 public constant DOMAIN_VERSION = keccak256("1");
  bytes32 public immutable DOMAIN_SEPARATOR;

  uint32 public immutable DOMAIN_CHAIN_ID;
  uint32 internal constant MAX_ERROR_COUNT = 6;
  uint32 public constant FEE_DIVISOR = 10000;

  /**
   * @notice Double mapping of signers to nonce groups to nonce states
   * @dev The nonce group is computed as nonce / 256, so each group of 256 sequential nonces uses the same key
   * @dev The nonce states are encoded as 256 bits, for each nonce in the group 0 means available and 1 means used
   */
  mapping(address => mapping(uint256 => uint256)) internal _nonceGroups;
  mapping(address => address) public override authorized;

  uint256 public protocolFee;
  address public protocolFeeWallet;

  constructor(
    uint256 _protocolFee,
    address _protocolFeeWallet
  ) {
    require(_protocolFee < FEE_DIVISOR, "INVALID_FEE");
    require(_protocolFeeWallet != address(0), "INVALID_FEE_WALLET");

    uint32 currentChainId = getChainId();
    DOMAIN_CHAIN_ID = currentChainId;
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        DOMAIN_NAME,
        DOMAIN_VERSION,
        currentChainId,
        this
      )
    );
    protocolFee = _protocolFee;
    protocolFeeWallet = _protocolFeeWallet;
  }

  /**
   * @notice Atomic ERC20 Swap for Any Sender
   * @param recipient address Wallet to receive sender proceeds
   * @param nonce uint256 Unique and should be sequential
   * @param expiry uint256 Expiry in seconds since 1 January 1970
   * @param signerWallet address Wallet of the signer
   * @param signerToken address ERC20 token transferred from the signer
   * @param signerAmount uint256 Amount transferred from the signer
   * @param senderToken address ERC20 token transferred from the sender
   * @param senderAmount uint256 Amount transferred from the sender
   * @param v uint8 "v" value of the ECDSA signature
   * @param r bytes32 "r" value of the ECDSA signature
   * @param s bytes32 "s" value of the ECDSA signature
   */
  function swapAnySender(
    address recipient,
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    // Ensure the order is valid
    _checkValidOrder(
      nonce,
      expiry,
      signerWallet,
      signerToken,
      signerAmount,
      address(0),
      senderToken,
      senderAmount,
      v,
      r,
      s
    );

    // Transfer token from sender to signer
    IERC20(senderToken).safeTransferFrom(
      msg.sender,
      signerWallet,
      senderAmount
    );

    // Transfer token from signer to recipient
    IERC20(signerToken).safeTransferFrom(signerWallet, recipient, signerAmount);

    // Calculate and transfer protocol fee and any rebate
    // _transferProtocolFee(signerToken, signerWallet, signerAmount);
    IERC20(signerToken).safeTransferFrom(
      signerWallet,
      protocolFeeWallet,
      (signerAmount * protocolFee) / FEE_DIVISOR
    );

    // Emit a Swap event
    emit Swap(
      nonce,
      block.timestamp,
      signerWallet,
      signerToken,
      signerAmount,
      protocolFee,
      msg.sender,
      senderToken,
      senderAmount
    );
  }

  /**
   * @notice Atomic ERC20 Swap for Whitelisted Sender 
   * @param nonce uint256 Unique and should be sequential
   * @param expiry uint256 Expiry in seconds since 1 January 1970
   * @param signerWallet address Wallet of the signer
   * @param signerToken address ERC20 token transferred from the signer
   * @param signerAmount uint256 Amount transferred from the signer
   * @param senderToken address ERC20 token transferred from the sender
   * @param senderAmount uint256 Amount transferred from the sender
   * @param v uint8 "v" value of the ECDSA signature
   * @param r bytes32 "r" value of the ECDSA signature
   * @param s bytes32 "s" value of the ECDSA signature
   */
  function swapWithRecipient(
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(DOMAIN_CHAIN_ID == getChainId(), "CHAIN_ID_CHANGED");

    // Ensure the expiry is not passed
    require(expiry > block.timestamp, "EXPIRY_PASSED");

    // Recover the signatory from the hash and signature
    address signatory = ecrecover(
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(
            abi.encode(
              ORDER_TYPEHASH,
              nonce,
              expiry,
              signerWallet,
              signerToken,
              signerAmount,
              protocolFee,
              msg.sender,
              senderToken,
              senderAmount
            )
          )
        )
      ),
      v,
      r,
      s
    );

    // Ensure the signatory is not null
    require(signatory != address(0), "SIGNATURE_INVALID");

    // Ensure the nonce is not yet used and if not mark it used
    require(_markNonceAsUsed(signatory, nonce), "NONCE_ALREADY_USED");

    // Ensure the signatory is authorized by the signer wallet
    if (signerWallet != signatory) {
      require(authorized[signerWallet] == signatory, "UNAUTHORIZED");
    }

    // Transfer token from sender to signer
    IERC20(senderToken).safeTransferFrom(
      msg.sender,
      signerWallet,
      senderAmount
    );

    // Transfer token from signer to recipient
    IERC20(signerToken).safeTransferFrom(
      signerWallet,
      msg.sender,
      signerAmount
    );

    // Transfer fee from signer to feeWallet
    IERC20(signerToken).safeTransferFrom(
      signerWallet,
      protocolFeeWallet,
      (signerAmount * protocolFee) / FEE_DIVISOR
    );

    // Emit a Swap event
    emit Swap(
      nonce,
      block.timestamp,
      signerWallet,
      signerToken,
      signerAmount,
      protocolFee,
      msg.sender,
      senderToken,
      senderAmount
    );
  }

  /**
   * @notice Set the fee
   * @param _protocolFee uint256 Value of the fee in basis points
   */
  function setProtocolFee(uint256 _protocolFee) external onlyOwner {
    // Ensure the fee is less than divisor
    require(_protocolFee < FEE_DIVISOR, "INVALID_FEE");
    protocolFee = _protocolFee;
    emit SetProtocolFee(_protocolFee);
  }

  /**
   * @notice Set the fee wallet
   * @param _protocolFeeWallet address Wallet to transfer fee to
   */
  function setProtocolFeeWallet(address _protocolFeeWallet) external onlyOwner {
    // Ensure the new fee wallet is not null
    require(_protocolFeeWallet != address(0), "INVALID_FEE_WALLET");
    protocolFeeWallet = _protocolFeeWallet;
    emit SetProtocolFeeWallet(_protocolFeeWallet);
  }

  /**
   * @notice Authorize a signer
   * @param signer address Wallet of the signer to authorize
   * @dev Emits an Authorize event
   */
  function authorize(address signer) external override {
    require(signer != address(0), "SIGNER_INVALID");
    authorized[msg.sender] = signer;
    emit Authorize(signer, msg.sender);
  }

  /**
   * @notice Revoke the signer
   * @dev Emits a Revoke event
   */
  function revoke() external override {
    address tmp = authorized[msg.sender];
    delete authorized[msg.sender];
    emit Revoke(tmp, msg.sender);
  }

  /**
   * @notice Cancel one or more nonces
   * @dev Cancelled nonces are marked as used
   * @dev Emits a Cancel event
   * @dev Out of gas may occur in arrays of length > 400
   * @param nonces uint256[] List of nonces to cancel
   */
  function cancel(uint256[] calldata nonces) external override {
    for (uint256 i = 0; i < nonces.length; i++) {
      uint256 nonce = nonces[i];
      if (_markNonceAsUsed(msg.sender, nonce)) {
        emit Cancel(nonce, msg.sender);
      }
    }
  }

  /**
   * @notice Validates Swap Order for any potential errors
   * @param senderWallet address Wallet that would send the order
   * @param nonce uint256 Unique and should be sequential
   * @param expiry uint256 Expiry in seconds since 1 January 1970
   * @param signerWallet address Wallet of the signer
   * @param signerToken address ERC20 token transferred from the signer
   * @param signerAmount uint256 Amount transferred from the signer
   * @param senderToken address ERC20 token transferred from the sender
   * @param senderAmount uint256 Amount transferred from the sender
   * @param v uint8 "v" value of the ECDSA signature
   * @param r bytes32 "r" value of the ECDSA signature
   * @param s bytes32 "s" value of the ECDSA signature
   * @return tuple of error count and bytes32[] memory array of error messages
   */
  function check(
    address senderWallet,
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public view returns (uint256, bytes32[] memory) {
    bytes32[] memory errors = new bytes32[](MAX_ERROR_COUNT);
    Order memory order;
    uint256 errCount;
    order.nonce = nonce;
    order.expiry = expiry;
    order.signerWallet = signerWallet;
    order.signerToken = signerToken;
    order.signerAmount = signerAmount;
    order.senderToken = senderToken;
    order.senderAmount = senderAmount;
    order.v = v;
    order.r = r;
    order.s = s;
    order.senderWallet = senderWallet;
    bytes32 hashed = _getOrderHash(
      order.nonce,
      order.expiry,
      order.signerWallet,
      order.signerToken,
      order.signerAmount,
      order.senderWallet,
      order.senderToken,
      order.senderAmount
    );
    address signatory = _getSignatory(hashed, order.v, order.r, order.s);

    if (signatory == address(0)) {
      errors[errCount] = "SIGNATURE_INVALID";
      errCount++;
    }

    if (order.expiry < block.timestamp) {
      errors[errCount] = "EXPIRY_PASSED";
      errCount++;
    }

    if (
      order.signerWallet != signatory &&
      authorized[order.signerWallet] != signatory
    ) {
      errors[errCount] = "UNAUTHORIZED";
      errCount++;
    } else {
      if (nonceUsed(signatory, order.nonce)) {
        errors[errCount] = "NONCE_ALREADY_USED";
        errCount++;
      }
    }

    if (order.senderWallet != address(0)) {
      uint256 senderBalance = IERC20(order.senderToken).balanceOf(
        order.senderWallet
      );

      uint256 senderAllowance = IERC20(order.senderToken).allowance(
        order.senderWallet,
        address(this)
      );

      if (senderAllowance < order.senderAmount) {
        errors[errCount] = "SENDER_ALLOWANCE_LOW";
        errCount++;
      }

      if (senderBalance < order.senderAmount) {
        errors[errCount] = "SENDER_BALANCE_LOW";
        errCount++;
      }
    }

    uint256 signerBalance = IERC20(order.signerToken).balanceOf(
      order.signerWallet
    );

    uint256 signerAllowance = IERC20(order.signerToken).allowance(
      order.signerWallet,
      address(this)
    );

    uint256 signerFeeAmount = (order.signerAmount * protocolFee) / FEE_DIVISOR;

    if (signerAllowance < order.signerAmount + signerFeeAmount) {
      errors[errCount] = "SIGNER_ALLOWANCE_LOW";
      errCount++;
    }

    if (signerBalance < order.signerAmount + signerFeeAmount) {
      errors[errCount] = "SIGNER_BALANCE_LOW";
      errCount++;
    }

    return (errCount, errors);
  }



  /**
   * @notice Returns true if the nonce has been used
   * @param signer address Address of the signer
   * @param nonce uint256 Nonce being checked
   */
  function nonceUsed(address signer, uint256 nonce)
    public
    view
    override
    returns (bool)
  {
    uint256 groupKey = nonce / 256;
    uint256 indexInGroup = nonce % 256;
    return (_nonceGroups[signer][groupKey] >> indexInGroup) & 1 == 1;
  }

  /**
   * @notice Returns the current chainId using the chainid opcode
   * @return id uint256 The chain id
   */
  function getChainId() public view returns (uint32 id) {
    // no-inline-assembly
    assembly {
      id := chainid()
    }
  }

  /**
   * @notice Marks a nonce as used for the given signer
   * @param signer address Address of the signer for which to mark the nonce as used
   * @param nonce uint256 Nonce to be marked as used
   * @return bool True if the nonce was not marked as used already
   */
  function _markNonceAsUsed(address signer, uint256 nonce)
    internal
    returns (bool)
  {
    uint256 groupKey = nonce / 256;
    uint256 indexInGroup = nonce % 256;
    uint256 group = _nonceGroups[signer][groupKey];

    // If it is already used, return false
    if ((group >> indexInGroup) & 1 == 1) {
      return false;
    }

    _nonceGroups[signer][groupKey] = group | (uint256(1) << indexInGroup);

    return true;
  }

  /**
   * @notice Checks Order Expiry, Nonce, Signature
   * @param nonce uint256 Unique and should be sequential
   * @param expiry uint256 Expiry in seconds since 1 January 1970
   * @param signerWallet address Wallet of the signer
   * @param signerToken address ERC20 token transferred from the signer
   * @param signerAmount uint256 Amount transferred from the signer
   * @param senderToken address ERC20 token transferred from the sender
   * @param senderAmount uint256 Amount transferred from the sender
   * @param v uint8 "v" value of the ECDSA signature
   * @param r bytes32 "r" value of the ECDSA signature
   * @param s bytes32 "s" value of the ECDSA signature
   */
  function _checkValidOrder(
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderWallet,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    require(DOMAIN_CHAIN_ID == getChainId(), "CHAIN_ID_CHANGED");

    // Ensure the expiry is not passed
    require(expiry > block.timestamp, "EXPIRY_PASSED");
  

    bytes32 hashed = _getOrderHash(
      nonce,
      expiry,
      signerWallet,
      signerToken,
      signerAmount,
      senderWallet,
      senderToken,
      senderAmount
    );

    // Recover the signatory from the hash and signature
    address signatory = _getSignatory(hashed, v, r, s);

    // Ensure the signatory is not null
    require(signatory != address(0), "SIGNATURE_INVALID");

    // Ensure the nonce is not yet used and if not mark it used
    require(_markNonceAsUsed(signatory, nonce), "NONCE_ALREADY_USED");

    // Ensure the signatory is authorized by the signer wallet
    if (signerWallet != signatory) {
      require(
        authorized[signerWallet] != address(0) &&
          authorized[signerWallet] == signatory,
        "UNAUTHORIZED"
      );
    }
  }

  /**
   * @notice Hash order parameters
   * @param nonce uint256
   * @param expiry uint256
   * @param signerWallet address
   * @param signerToken address
   * @param signerAmount uint256
   * @param senderToken address
   * @param senderAmount uint256
   * @return bytes32
   */
  function _getOrderHash(
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderWallet,
    address senderToken,
    uint256 senderAmount
  ) internal view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          ORDER_TYPEHASH,
          nonce,
          expiry,
          signerWallet,
          signerToken,
          signerAmount,
          protocolFee,
          senderWallet,
          senderToken,
          senderAmount
        )
      );
  }

  /**
   * @notice Recover the signatory from a signature
   * @param hash bytes32
   * @param v uint8
   * @param r bytes32
   * @param s bytes32
   */
  function _getSignatory(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal view returns (address) {
    return
      ecrecover(
        keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash)),
        v,
        r,
        s
      );
  }
}