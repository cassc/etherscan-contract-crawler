// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Administrable.sol";

contract WrappedPeercoin is ERC20, Ownable, Pausable, Administrable {
  uint32 fee = 10000;
  mapping(string => bool) usedExternalAddresses;

  constructor() ERC20("WrappedPeercoin", "wPPC") {}

  event WPPCBurned (
    address indexed from,
    address indexed to,
    uint256 tokens,
    string externalAddress
  );

  modifier onlyEOA() {
    require(msg.sender == tx.origin, "wPPC: must use externally owned address.");
    _;
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }

  function claimTokens(uint256 _amount, string memory _externalAddress, address _receiver, address _signerA, bytes memory _signatureA, address _signerB, bytes memory _signatureB, address _signerC, bytes memory _signatureC) public onlyEOA {
      require(!usedExternalAddresses[_externalAddress], "wPPC: invalid nonce");

      address witnessA = recoverSigner(prefixed(keccak256(abi.encodePacked(_receiver, _amount, _externalAddress, _signerA))), _signatureA);
      address witnessB = recoverSigner(prefixed(keccak256(abi.encodePacked(_receiver, _amount, _externalAddress, _signerB))), _signatureB);
      address witnessC = recoverSigner(prefixed(keccak256(abi.encodePacked(_receiver, _amount, _externalAddress, _signerC))), _signatureC);

      if (witnessA == witnessB || witnessB == witnessC) {
        revert("Same witness cannot sign twice");
      }

      if (!admins[witnessA] || !admins[witnessB] || !admins[witnessC]) {
        revert('Could not validate one or more signatures');
      }

      usedExternalAddresses[_externalAddress] = true;

      _mint(_receiver, (_amount-fee));
  }

  function burnTokens(uint256 _amount, string memory _externalAddress) public onlyEOA {
      _burn(msg.sender, _amount);

      emit WPPCBurned(msg.sender, address(0), _amount, _externalAddress);
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

      return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(sig.length == 65, "invalid signature length");

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    return (r, s, v);
  }
}