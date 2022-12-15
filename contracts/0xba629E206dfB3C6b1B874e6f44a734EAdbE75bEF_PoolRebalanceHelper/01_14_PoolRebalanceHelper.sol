// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IAggregationRouterV4.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IStarkEx.sol";
import "../interfaces/IFactRegister.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *
 * PoolRebalanceHelper
 * ============
 *
 * Basic multi-signer wallet designed for use in a co-signing environment where 2 signatures are require to move funds.
 * Typically used in a 2-of-3 signing configuration. Uses ecrecover to allow for 2 signatures in a single transaction.
 *
 * The signatures are created on the operation hash and passed to withdrawETH/withdrawERC20
 * The signer is determined by ECDSA.recover().
 *
 * The signature is created with ethereumjs-util.ecsign(operationHash).
 * Like the eth_sign RPC call, it packs the values as a 65-byte array of [r, s, v].
 * Unlike eth_sign, the message is not prefixed.
 *
 */
contract PoolRebalanceHelper is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // Events
  event Deposit(address token, uint256 amount, uint256 starkKey, uint256 positionId);
  event WithdrawETH(uint256 orderId, address to, uint256 amount);
  event WithdrawERC20(uint256 orderId, address token, address to, uint256 amount);

  // Public fields
  address immutable public USDC_ADDRESS;                  // USDC contract address
  address immutable public STARKEX_ADDRESS;               // stark exchange adress
  uint256 immutable public L2POOL_ACCOUNT_ID;             // l2pool account id
  uint256 immutable public L2POOL_STARK_KEY;              // l2pool stark key

  address[] public signers;                               // The addresses that can co-sign transactions on the wallet
  mapping(uint256 => order) orders;                       // history orders
  uint256 public ASSET_TYPE;                              // stark exchange defined USDC

  struct order{
    address to;     // The address the transaction was sent to
    uint256 amount; // Amount of Wei sent to the address
    address token;  // The address of the ERC20 token contract, 0 means ETH
    bool executed;  // If the order was executed
  }

  /**
   * Set up a simple 2-3 multi-sig wallet by specifying the signers allowed to be used on this wallet.
   * 2 signers will be require to send a transaction from this wallet.
   * Note: The sender is NOT automatically added to the list of signers.
   * Signers CANNOT be changed once they are set
   *
   * @param allowedSigners      An array of signers on the wallet
   * @param usdc                The USDC contract address
   * @param starkex             The stark exchange address
   * @param assetType           The USDC asset type in starkex
   * @param l2poolAccountId     The fixed l2pool account id
   * @param l2poolStarkKey      The fixed l2key
   * 
   */
  constructor(address[] memory allowedSigners, address usdc,address starkex,  uint256 assetType,uint256 l2poolAccountId, uint256 l2poolStarkKey) {
    require(allowedSigners.length == 3, "invalid allSigners length");
    require(allowedSigners[0] != allowedSigners[1], "must be different signers");
    require(allowedSigners[0] != allowedSigners[2], "must be different signers");
    require(allowedSigners[1] != allowedSigners[2], "must be different signers");
    require(usdc != address(0), "invalid usdc address");
    require(block.chainid == 1 || block.chainid == 5, "invalid chain id");

    signers = allowedSigners;
    USDC_ADDRESS = usdc;
    STARKEX_ADDRESS = starkex;
    ASSET_TYPE = assetType;
    L2POOL_ACCOUNT_ID = l2poolAccountId;
    L2POOL_STARK_KEY = l2poolStarkKey;
  }

  /**
   * Gets called when a transaction is received without calling a method
   */
  receive() external payable { }

  /**
    * @notice Make a deposit to the Starkware Layer2.
    *  Funds will be transferred from this contract to starkware, and 
    *  generate a deposit event specified by the starkKey and positionId.
    */
  function deposit() public nonReentrant returns (uint256) {
    uint256 balance =  IERC20(USDC_ADDRESS).balanceOf(address(this));
    require(balance > 0, "insufficient balance");
    require(block.chainid == 1 || block.chainid == 5, "invalid chain id");

    // safeApprove requires unsetting the allowance first.
    IERC20(USDC_ADDRESS).safeApprove(STARKEX_ADDRESS, 0);
    IERC20(USDC_ADDRESS).safeApprove(STARKEX_ADDRESS, balance);

    // deposit to starkex
    IStarkEx starkEx = IStarkEx(STARKEX_ADDRESS);
    starkEx.depositERC20(L2POOL_STARK_KEY, ASSET_TYPE, L2POOL_ACCOUNT_ID, balance);

    emit Deposit(
      address(USDC_ADDRESS),
      balance,
      L2POOL_STARK_KEY,
      L2POOL_ACCOUNT_ID
    );

    return balance;
  }

  /**
   * Withdraw ETHER from this wallet using 2 signers.
   *
   * @param  to         the destination address to send an outgoing transaction
   * @param  amount     the amount in Wei to be sent
   * @param  expireTime the number of seconds since 1970 for which this transaction is valid
   * @param  orderId    the unique order id 
   * @param  allSigners all signers who sign the tx
   * @param  signatures the signatures of tx
   */
  function withdrawETH(
    address payable to,
    uint256 amount,
    uint256 expireTime,
    uint256 orderId,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(allSigners.length >= 2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer
    require(expireTime >= block.timestamp,"expired transaction");

    bytes32 operationHash = keccak256(abi.encodePacked("ETHER", to, amount, expireTime, orderId, address(this), block.chainid));
    operationHash = ECDSA.toEthSignedMessageHash(operationHash);
    
    for (uint8 index = 0; index < allSigners.length; index++) {
      address signer = ECDSA.recover(operationHash, signatures[index]);
      require(signer == allSigners[index], "invalid signer");
      require(isAllowedSigner(signer), "not allowed signer");
    }

    // Try to insert the order ID. Will revert if the order id was invalid
    tryInsertOrderId(orderId, to, amount, address(0));

    // send ETHER
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success, ) = to.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");

    emit WithdrawETH(orderId, to, amount);
  }
  
  /**
   * Withdraw ERC20 from this wallet using 2 signers.
   *
   * @param  to         the destination address to send an outgoing transactioni
   * @param  amount     the amount in Wei to be sent
   * @param  token      the address of the erc20 token contract
   * @param  expireTime the number of seconds since 1970 for which this transaction is valid
   * @param  orderId    the unique order id 
   * @param  allSigners all signer who sign the tx
   * @param  signatures the signatures of tx
   */
  function withdrawErc20(
    address to,
    uint256 amount,
    address token,
    uint256 expireTime,
    uint256 orderId,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(allSigners.length >=2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer
    require(expireTime >= block.timestamp,"expired transaction");

    bytes32 operationHash = keccak256(abi.encodePacked("ERC20", to, amount, token, expireTime, orderId, address(this), block.chainid));
    operationHash = ECDSA.toEthSignedMessageHash(operationHash);

    for (uint8 index = 0; index < allSigners.length; index++) {
      address signer = ECDSA.recover(operationHash, signatures[index]);
      require(signer == allSigners[index], "invalid signer");
      require(isAllowedSigner(signer),"not allowed signer");
    }

    // Try to insert the order ID. Will revert if the order id was invalid
    tryInsertOrderId(orderId, to, amount, token);

    // Success, send ERC20 token
    IERC20(token).safeTransfer(to, amount);
    emit WithdrawERC20(orderId, token, to, amount);
  }

  /**
   * Determine if an address is a signer on this wallet
   *
   * @param signer address to check
   */
  function isAllowedSigner(address signer) public view returns (bool) {
    // Iterate through all signers on the wallet and
    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == signer) {
        return true;
      }
    }
    return false;
  }
  
  /**
   * Verify that the order id has not been used before and inserts it. Throws if the order ID was not accepted.
   *
   * @param orderId   the unique order id 
   * @param to        the destination address to send an outgoing transaction
   * @param amount     the amount in Wei to be sent
   * @param token     the address of the ERC20 contract
   */
  function tryInsertOrderId(
      uint256 orderId, 
      address to,
      uint256 amount, 
      address token
    ) internal {
    if (orders[orderId].executed) {
        // This order ID has been excuted before. Disallow!
        revert("repeated order");
    }

    orders[orderId].executed = true;
    orders[orderId].to = to;
    orders[orderId].amount = amount;
    orders[orderId].token = token;
  }

  /**
   * calcSigHash is a helper function that to help you generate the sighash needed for withdrawal.
   *
   * @param to          the destination address
   * @param amount      the amount in Wei to be sent
   * @param token       the address of the ERC20 contract
   * @param expireTime  the number of seconds since 1970 for which this transaction is valid
   * @param orderId     the unique order id 
   */

  function calcSigHash(
    address to,
    uint256 amount,
    address token,
    uint256 expireTime,
    uint256 orderId) public view returns (bytes32) {
    bytes32 operationHash;
    if (token == address(0)) {
      operationHash = keccak256(abi.encodePacked("ETHER", to, amount, expireTime, orderId, address(this), block.chainid));
    } else {
      operationHash = keccak256(abi.encodePacked("ERC20", to, amount, token, expireTime, orderId, address(this), block.chainid));
    }
    return operationHash;
  }
}