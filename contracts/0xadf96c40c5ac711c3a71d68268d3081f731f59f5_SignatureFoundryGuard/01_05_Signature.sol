// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Base.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureFoundryGuard is BaseFoundryGuard {
  using ECDSA for bytes32;

  struct Criterion {
    address signer;
    bytes32 salt;
  }

  // The array that will store authorization criteria
  Criterion[] public criteria;

  // Function to create a new authorization criterion
  function createCriteria(address signer, bytes32 salt) external {
    criteria.push(Criterion(signer, salt));
  }

  // Override the BaseFoundryGuard's authorize function
  function authorize(
    uint256 id,
    address wallet,
    string calldata,
    bytes calldata credentials
  ) external view override returns (bool) {
    // Check the id is valid
    require(id < criteria.length, "Invalid id");

    // Prepare the data hash
    bytes32 dataHash = keccak256(abi.encode(wallet, criteria[id].salt))
      .toEthSignedMessageHash();

    // Recover the signer's address from the signature
    address signer = dataHash.recover(credentials);

    // Verify that the signer's address matches the stored signer address
    return signer == criteria[id].signer;
  }
}