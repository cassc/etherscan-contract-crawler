// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';

import './interfaces/IVerifier.sol';
import './libraries/SafeToken.sol';

contract Bridge is Multicall {
  using Address for address;
  using Address for address payable;
  using SafeToken for address;

  bytes32 public immutable DOMAIN_SEPARATOR;
  // keccak256('Out(bytes16 uuid,address token,uint256 amount,uint256 gas,address to,bytes data)')
  bytes32 public constant OUT_TYPEHASH = 0x128db24430fa2fc5b7de9305b8518573b5e9ed0bde3a71ed68fc27427fcdac9b;
  // keccak256('SetVerifier(address newVerifier,uint256 deadline)')
  bytes32 public constant SET_VERIFIER_TYPEHASH = 0x83ff2829503e6b25933e0c1d0422aeb9b68fe6259418bffd98b105c4ef89c4d4;

  mapping(bytes16 => uint256) public used;
  mapping(bytes16 => uint256) public usedPay;
  IVerifier public verifier;

  event Payed(bytes16 indexed uuid, address token, uint256 amount, address payer);
  event Outed(bytes16 indexed uuid, address token, uint256 amount, address to);

  modifier notUsed(bytes16 uuid) {
    require(used[uuid] == 0, 'Bridge: uuid already used');
    _;
    used[uuid] = block.number;
  }

  modifier notUsedPay(bytes16 uuid) {
    require(usedPay[uuid] == 0, 'Bridge: uuid already used');
    _;
    usedPay[uuid] = block.number;
  }

  constructor() {
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256('Bridge'),
        keccak256('1'),
        block.chainid,
        address(this)
      )
    );
  }

  function pay(
    bytes16 uuid,
    address token,
    uint256 amount
  ) external payable notUsedPay(uuid) {
    if (token == address(0)) {
      amount = msg.value;
    } else {
      amount = token.move(msg.sender, address(this), amount);
    }

    emit Payed(uuid, token, amount, msg.sender);
  }

  function out(
    bytes16 uuid,
    address token,
    uint256 amount,
    uint256 gas,
    address payable to,
    bytes calldata data,
    bytes[] calldata signatures
  ) external notUsed(uuid) {
    bytes32 structHash = keccak256(abi.encode(OUT_TYPEHASH, uuid, token, amount, gas, to, keccak256(data)));
    require(verifier.verify(DOMAIN_SEPARATOR, structHash, signatures), 'Bridge: invalid signatures');

    if (token == address(0)) {
      if (data.length > 0) {
        to.functionCallWithValue(data, amount + gas);
      } else {
        to.sendValue(amount + gas);
      }
    } else {
      if (data.length > 0) {
        token.approve(to, amount);
        to.functionCallWithValue(data, gas);
        token.approve(to, 0);
      } else {
        token.move(address(this), to, amount);
        if (gas > 0) {
          to.sendValue(gas);
        }
      }
    }

    emit Outed(uuid, token, amount, to);
  }

  function setVerifier(
    IVerifier newVerifier,
    uint256 deadline,
    bytes[] calldata newSigs,
    bytes[] calldata oldSigs
  ) external {
    require(block.timestamp <= deadline, 'Bridge: expired');

    bytes32 structHash = keccak256(abi.encode(SET_VERIFIER_TYPEHASH, newVerifier, deadline));
    require(newVerifier.verify(DOMAIN_SEPARATOR, structHash, newSigs), 'Bridge: invalid signature for new verifier');

    if (address(verifier) != address(0)) {
      require(verifier.verify(DOMAIN_SEPARATOR, structHash, oldSigs), 'Bridge: invalid signature for old verifier');
    }

    verifier = newVerifier;
  }

  receive() external payable {}
}