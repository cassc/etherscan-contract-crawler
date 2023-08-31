// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Base.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AssignedFoundryGuard is BaseFoundryGuard {
  using ECDSA for bytes32;

  event CriteriaCreated(address indexed signer, bytes32 indexed parent, uint256 id);

  struct Criterion {
    address signer;
    bytes32 parent;
  }

  // The array that will store authorization criteria
  Criterion[] public criteria;

  // Function to create a new authorization criterion
  function createCriteria(address signer, bytes32 parent) external returns (uint256) {
    criteria.push(Criterion(signer, parent));
    uint256 id = criteria.length - 1;
    emit CriteriaCreated(signer, parent, id);
    return id;
  }

  function authorize(
    uint256 id,
    address wallet,
    string calldata label,
    bytes calldata credentials
  ) external view override returns (bool) {
    // Check the id is valid
    require(id < criteria.length, "Invalid id");

    // Prepare the data hash
    bytes32 namehash = keccak256(
      abi.encodePacked(criteria[id].parent, keccak256(bytes(label)))
    );
    bytes32 message = keccak256(abi.encode(wallet, namehash))
      .toEthSignedMessageHash();

    // Recover the signer's address from the signature
    address signer = message.recover(credentials);

    // Verify that the signer's address matches the stored signer address
    return signer == criteria[id].signer;
  }
}