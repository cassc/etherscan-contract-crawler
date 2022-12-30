// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

struct Trade {
  address tokenAddress;
  uint tokenID;
  uint[] userTokenIDs;
  address trader;
  uint timestamp;
  bytes32 nonce;
}

interface IERC721 {
  function safeTransferFrom(address from, address to, uint tokenId) external;
}

contract Market {
  address public owner;

  bool public _marketOpen = false;
  address public txSigner;
  uint public tradeTimeout = 150;
  address public vault;

  mapping(bytes32 => bool) private _usedNonces;

  event TradeExecuted(address tokenAddress, uint tokenID, bytes32 nonce, address trader);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Sender not owner");
    _;
  }

  modifier marketOpen() {
    require(_marketOpen, "Market is not open.");
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    owner = newOwner;
  }

  function toggleMarket(bool status) onlyOwner public {
    _marketOpen = status;
  }

  function setup(address signer, uint timeout, address ownerVault) onlyOwner public {
    txSigner = signer;
    tradeTimeout = timeout;
    vault = ownerVault;
  }

  function nonceSeen(bytes32 nonce) public view returns(bool) {
    return _usedNonces[ nonce ];
  }

  function trade(address tokenAddress, uint tokenID, uint[] calldata userTokenIDs, bytes calldata signature, uint sigTimestamp, bytes32 nonce)
    marketOpen
    public {
    Trade memory t = Trade(
      tokenAddress,
      tokenID,
      userTokenIDs,
      msg.sender,
      sigTimestamp,
      nonce
    );

    require(t.timestamp > block.timestamp - tradeTimeout, "Trade authorization is too old.");
    require(_usedNonces[ nonce ] == false, "Duplicate trade.");
    require(verifySignature(t, signature), "Signature authorization is invalid.");

    _usedNonces[ nonce ] = true;

    for (uint i = 0; i < t.userTokenIDs.length; i++) {
      IERC721(t.tokenAddress).safeTransferFrom(t.trader, vault, t.userTokenIDs[ i ]);
    }
    IERC721(t.tokenAddress).safeTransferFrom(vault, t.trader, t.tokenID);

    emit TradeExecuted(t.tokenAddress, t.tokenID, t.nonce, t.trader);
  }

  function verifySignature(Trade memory t, bytes calldata signature) public view returns(bool) {
      return txSigner == getSigner(signature, getHash(getDigest(t)));
  }

  function getSigner(bytes memory signature, bytes32 digestHash) public pure returns(address) {
      bytes32 ethSignedHash = ECDSA.toEthSignedMessageHash(digestHash);
      return ECDSA.recover(ethSignedHash, signature);
  }

  function getHash(bytes memory digest) public pure returns (bytes32 hash) {
      return keccak256(digest);
  }

  function getDigest(Trade memory t) public pure returns (bytes memory) {
    return abi.encodePacked(
      t.tokenAddress,
      t.tokenID,
      t.trader,
      keccak256(abi.encodePacked(t.userTokenIDs)),
      t.nonce,
      t.timestamp
    );
  }
}