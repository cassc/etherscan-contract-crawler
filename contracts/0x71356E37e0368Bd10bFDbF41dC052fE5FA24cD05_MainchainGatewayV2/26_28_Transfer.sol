// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Token.sol";

library Transfer {
  using ECDSA for bytes32;

  enum Kind {
    Deposit,
    Withdrawal
  }

  struct Request {
    // For deposit request: Recipient address on Ronin network
    // For withdrawal request: Recipient address on mainchain network
    address recipientAddr;
    // Token address to deposit/withdraw
    // Value 0: native token
    address tokenAddr;
    Token.Info info;
  }

  /**
   * @dev Converts the transfer request into the deposit receipt.
   */
  function into_deposit_receipt(
    Request memory _request,
    address _requester,
    uint256 _id,
    address _roninTokenAddr,
    uint256 _roninChainId
  ) internal view returns (Receipt memory _receipt) {
    _receipt.id = _id;
    _receipt.kind = Kind.Deposit;
    _receipt.mainchain.addr = _requester;
    _receipt.mainchain.tokenAddr = _request.tokenAddr;
    _receipt.mainchain.chainId = block.chainid;
    _receipt.ronin.addr = _request.recipientAddr;
    _receipt.ronin.tokenAddr = _roninTokenAddr;
    _receipt.ronin.chainId = _roninChainId;
    _receipt.info = _request.info;
  }

  /**
   * @dev Converts the transfer request into the withdrawal receipt.
   */
  function into_withdrawal_receipt(
    Request memory _request,
    address _requester,
    uint256 _id,
    address _mainchainTokenAddr,
    uint256 _mainchainId
  ) internal view returns (Receipt memory _receipt) {
    _receipt.id = _id;
    _receipt.kind = Kind.Withdrawal;
    _receipt.ronin.addr = _requester;
    _receipt.ronin.tokenAddr = _request.tokenAddr;
    _receipt.ronin.chainId = block.chainid;
    _receipt.mainchain.addr = _request.recipientAddr;
    _receipt.mainchain.tokenAddr = _mainchainTokenAddr;
    _receipt.mainchain.chainId = _mainchainId;
    _receipt.info = _request.info;
  }

  struct Receipt {
    uint256 id;
    Kind kind;
    Token.Owner mainchain;
    Token.Owner ronin;
    Token.Info info;
  }

  // keccak256("Receipt(uint256 id,uint8 kind,TokenOwner mainchain,TokenOwner ronin,TokenInfo info)TokenInfo(uint8 erc,uint256 id,uint256 quantity)TokenOwner(address addr,address tokenAddr,uint256 chainId)");
  bytes32 public constant TYPE_HASH = 0xb9d1fe7c9deeec5dc90a2f47ff1684239519f2545b2228d3d91fb27df3189eea;

  /**
   * @dev Returns token info struct hash.
   */
  function hash(Receipt memory _receipt) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          TYPE_HASH,
          _receipt.id,
          _receipt.kind,
          Token.hash(_receipt.mainchain),
          Token.hash(_receipt.ronin),
          Token.hash(_receipt.info)
        )
      );
  }

  /**
   * @dev Returns the receipt digest.
   */
  function receiptDigest(bytes32 _domainSeparator, bytes32 _receiptHash) internal pure returns (bytes32) {
    return _domainSeparator.toTypedDataHash(_receiptHash);
  }
}