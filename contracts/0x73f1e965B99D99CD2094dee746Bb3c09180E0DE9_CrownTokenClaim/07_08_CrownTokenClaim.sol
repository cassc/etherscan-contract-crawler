// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VucaOwnable.sol";

contract CrownTokenClaim is VucaOwnable {
  using SafeERC20 for IERC20;

  address public crownAddress = 0xF3Bb9F16677F2B86EfD1DFca1c141A99783Fde58;
  address public verifier = 0x9f6B54d48AD2175e56a1BA9bFc74cd077213B68D;

  uint256 public startTime = 1679662800;
  uint256 public endTime = 1684933200;

  mapping(address => uint256) public claimed;

  /* User */
  function claim(
    uint256 _maxAmount,
    uint256 _amount,
    uint256 _expiredAt,
    bytes calldata _signature
  ) external {
    require(tx.origin == msg.sender, "Not allowed");
    require(_amount > 0, "Invalid amount");
    require(startTime <= block.timestamp && block.timestamp <= endTime, "Inactive");
    require(_expiredAt >= block.timestamp, "Signature expired");
    require(validSignature(keccak256(abi.encodePacked("vuca-crown-claim", msg.sender, _maxAmount, _expiredAt)), _signature), "Invalid signature");
    require(claimed[msg.sender] + _amount <= _maxAmount, "Exceeds max");

    IERC20(crownAddress).safeTransfer(msg.sender, _amount);
    claimed[msg.sender] += _amount;
  }

  /* Admin */
  // verified
  function setCrownAddress(address _contract) external onlyOwner {
    crownAddress = _contract;
  }

  // verified
  function setVerifier(address _signer) external onlyOwner {
    verifier = _signer;
  }

  // verified
  function setActiveTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
    require(_endTime > _startTime, "Invalid input");
    startTime = _startTime;
    endTime = _endTime;
  }

  /* Others */
  // in case anyone transfer eth by accident
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawCrown(address _to) public onlyOwner {
    require(block.timestamp > endTime, "Claim active");

    uint256 balance = IERC20(crownAddress).balanceOf(address(this));
    IERC20(crownAddress).safeTransfer(_to, balance);
  }

  /* Internal */
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  function validSignature(bytes32 _message, bytes memory _signature) public view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == verifier;
  }
}