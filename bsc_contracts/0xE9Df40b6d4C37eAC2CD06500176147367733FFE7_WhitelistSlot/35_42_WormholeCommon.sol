// SPDX-License-Identifier: Apache2
pragma solidity ^0.8.0;

import "./interfaces/IWormhole.sol";
import "./libraries/BytesLib.sol";

contract WormholeCommon {
  using BytesLib for bytes;
  struct WTransfer {
    // PayloadID uint8 = 1
    // TokenID of the token, if an NFT; amount if a transfer; encoded uint for something else
    uint256 payload;
    // Address of the recipient. Left-zero-padded if shorter than 32 bytes
    bytes32 to;
    // Chain ID of the recipient
    uint16 toChain;
  }

  struct State {
    // Wormhole bridge contract address and chainId
    address payable wormhole;
    uint16 chainId;
    // Mapping of consumed token transfers
    mapping(bytes32 => bool) completedTransfers;
    // Mapping of contracts on other chains
    mapping(uint16 => bytes32) contractsByChainId;
  }

  State _wormholeState;

  function isTransferCompleted(bytes32 hash) public view returns (bool) {
    return _wormholeState.completedTransfers[hash];
  }

  function contractByChainId(uint16 chainId_) public view returns (bytes32) {
    return _wormholeState.contractsByChainId[chainId_];
  }

  function wormhole() public view returns (IWormhole) {
    return IWormhole(_wormholeState.wormhole);
  }

  function chainId() public view returns (uint16) {
    return _wormholeState.chainId;
  }

  function _setWormhole(address wh) internal {
    _wormholeState.wormhole = payable(wh);
  }

  function _setChainId(uint16 chainId_) internal {
    _wormholeState.chainId = chainId_;
  }

  function _setTransferCompleted(bytes32 hash) internal {
    _wormholeState.completedTransfers[hash] = true;
  }

  function _setContract(uint16 chainId_, bytes32 contractExtendedAddress) internal {
    _wormholeState.contractsByChainId[chainId_] = contractExtendedAddress;
  }

  function _wormholeCompleteTransfer(bytes memory encodedVm) internal returns (address to, uint256 payload) {
    (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVm);

    require(valid, reason);

    require(_verifyContractVM(vm), "invalid emitter");

    WTransfer memory wTransfer = _parseTransfer(vm.payload);

    require(!isTransferCompleted(vm.hash), "transfer already completed");
    _setTransferCompleted(vm.hash);

    require(wTransfer.toChain == chainId(), "invalid target chain");

    // transfer bridged NFT to recipient
    address transferRecipient = address(uint160(uint256(wTransfer.to)));

    return (transferRecipient, wTransfer.payload);
  }

  function _wormholeTransferWithValue(
    uint256 payload,
    uint16 recipientChain,
    bytes32 recipient,
    uint32 nonce,
    uint256 value
  ) internal returns (uint64 sequence) {
    require(contractByChainId(recipientChain) != 0, "recipientChain not allowed");
    sequence = _logTransfer(WTransfer({payload: payload, to: recipient, toChain: recipientChain}), value, nonce);
    return sequence;
  }

  function _logTransfer(
    WTransfer memory wTransfer,
    uint256 callValue,
    uint32 nonce
  ) internal returns (uint64 sequence) {
    bytes memory encoded = _encodeTransfer(wTransfer);
    sequence = wormhole().publishMessage{value: callValue}(nonce, encoded, 15);
  }

  function _verifyContractVM(IWormhole.VM memory vm) internal view returns (bool) {
    if (contractByChainId(vm.emitterChainId) == vm.emitterAddress) {
      return true;
    }
    return false;
  }

  function _encodeTransfer(WTransfer memory wTransfer) internal pure returns (bytes memory encoded) {
    encoded = abi.encodePacked(uint8(1), wTransfer.payload, wTransfer.to, wTransfer.toChain);
  }

  function _parseTransfer(bytes memory encoded) internal pure returns (WTransfer memory wTransfer) {
    uint256 index = 0;

    uint8 payloadId = encoded.toUint8(index);
    index += 1;

    require(payloadId == 1, "invalid WTransfer");

    wTransfer.payload = encoded.toUint256(index);
    index += 32;

    wTransfer.to = encoded.toBytes32(index);
    index += 32;

    wTransfer.toChain = encoded.toUint16(index);
    index += 2;

    require(encoded.length == index, "invalid WTransfer");
    return wTransfer;
  }
}