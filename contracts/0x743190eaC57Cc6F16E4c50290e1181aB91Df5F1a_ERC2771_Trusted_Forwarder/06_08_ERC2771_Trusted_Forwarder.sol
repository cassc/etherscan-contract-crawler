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
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./ISystem.sol";
import "./ISystem_Delegate_Approver.sol";

contract ERC2771_Trusted_Forwarder is EIP712 {
  using ECDSA for bytes32;

  struct ForwardRequest {
    address from;
    address to;
    uint256 value;
    uint256 gas;
    uint256 nonce;
    bytes data;
  }

  bytes32 private constant _TYPEHASH =
    keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

  // mapping from account to gasless tx nonces to prevent replay
  mapping(address => mapping(uint256 => bool)) private _nonces;

  ISystem_Delegate_Approver immutable systemDelegateApprover;

  constructor(address _systemDelegateApprover) EIP712("ERC2771_Trusted_Forwarder", "1.0.0") {
    systemDelegateApprover = ISystem_Delegate_Approver(_systemDelegateApprover);
  }

  function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
    address signer = _hashTypedDataV4(
      keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
    ).recover(signature);

    return !_nonces[req.from][req.nonce] && (signer == req.from || systemDelegateApprover.isDelegateApprovedForSystem(req.from, 0x4168694de04c1b4d3bb81d9503f3f00c21c34bafce952643bcc05f16e2b7acef, signer));
  }

  function execute(ForwardRequest calldata req, bytes calldata signature) public payable returns (bool, bytes memory) {
    require(verify(req, signature), "ERC2771_Trusted_Forwarder: signature does not match request, signer is not approved for system, or nonce has been used");

    _nonces[req.from][req.nonce] = true;

    (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
      abi.encodePacked(req.data, req.from)
    );

    // Validate that the relayer has sent enough gas for the call.
    // See https://ronan.eth.link/blog/ethereum-gas-dangers/
    assert(gasleft() > req.gas / 63);

    return (success, returndata);
  }
}