// SPDX-License-Identifier: MIT
// Omnikit Inc
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SubscriptionReceiver {
  using ECDSA for bytes32;

  address private owner;
  address payable private forwardTo;

  address public signer = 0x00000000116Ac2B09EBd44b5e34fAB4B8C8828eD;

  bool private forward;
  bool public paused;

  event ReceivedPayment(bytes32 indexed userId, uint16 indexed numOfDays, uint256 indexed price);

  constructor(address _owner, address payable _forwardTo) {
    owner = _owner;
    forwardTo = _forwardTo;
    forward = true;
    paused = false;
  }

  function pay(bytes32 userId, uint16 numOfDays, uint256 sigExpiration, bytes memory signature) external payable isNotPaused {
    require(block.timestamp <= sigExpiration, "Signature has expired");
    require(_verifySignature(userId, msg.value, numOfDays, sigExpiration, signature, signer), "Invalid signature");
    emit ReceivedPayment(userId, numOfDays, msg.value);
    if (forward) {
      forwardTo.transfer(msg.value);
    }
  }

  function _verifySignature(bytes32 userId, uint256 price, uint16 numOfDays, uint256 sigExpiration, bytes memory signature, address expectedSigner) private pure returns(bool) {
    bytes32 messageHash = keccak256(abi.encodePacked(userId, price, numOfDays, sigExpiration));
    address actualSigner = messageHash.toEthSignedMessageHash().recover(signature);
    return actualSigner == expectedSigner;
  }

  function togglePaused() external onlyOwner {
    paused = !paused;
  }

  function setForwardAddress(address payable _forwardTo) external onlyOwner {
    forwardTo = _forwardTo;
  }

  function forwardBalance() external onlyOwner {
    forwardTo.transfer(address(this).balance);
  }

  function toggleForward() external onlyOwner {
    forward = !forward;
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function withdraw(address payable _address, uint256 _amount) external onlyOwner {
    _address.transfer(_amount);
  }

  function transferOwnership(address _owner) external onlyOwner {
    owner = _owner;
  }

  modifier isNotPaused() {
    require(!paused, "Contract paused");
    _;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Caller must be owner!");
    _;
  }
}