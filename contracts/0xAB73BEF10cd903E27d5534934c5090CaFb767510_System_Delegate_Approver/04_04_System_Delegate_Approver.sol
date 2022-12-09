// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract System_Delegate_Approver {
  using ECDSA for bytes32;

  // mapping from account to nonces to prevent replay
  mapping(address => mapping(uint256 => bool)) private _nonces;

  // mapping from account address -> system id -> delegate signer address approvals
  mapping(address => mapping(bytes32 => mapping(address => bool))) private _systemDelegateApprover;

  function isDelegateApprovedForSystem(address account, bytes32 systemId, address delegate) public view returns (bool) {
    return _systemDelegateApprover[account][systemId][delegate];
  }

  function setDelegateApprovalForSystem(bytes32 systemId, address delegate, bool approved) external {
    _systemDelegateApprover[msg.sender][systemId][delegate] = approved;
  }

  function setDelegateApprovalForSystemBySignature(bytes32 systemId, address delegate, bool approved, address signer, uint256 nonce, bytes calldata signature) external {
    address recoveredSigner = keccak256(abi.encode(systemId, delegate, approved, signer, nonce)).toEthSignedMessageHash().recover(signature);
    require(signer == recoveredSigner, "Signer recovered from signature mismatched signer");
    require(!_nonces[signer][nonce], "nonce has been used");

    _nonces[signer][nonce] = true;
    _systemDelegateApprover[signer][systemId][delegate] = approved;
  }
}