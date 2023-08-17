// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity 0.8.19;

// LightLink 2023
/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
  function createClone(bytes32 _salt, address _target) internal returns (address _result) {
    bytes20 _targetBytes = bytes20(_target);

    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), _targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      _result := create2(0, clone, 0x37, _salt)
    }

    require(_result != address(0), "Create2: Failed on minimal deploy");
  }

  function createClone2(bytes32 _salt, bytes memory _bytecode) internal returns (address _result) {
    assembly {
      _result := create2(0, add(_bytecode, 0x20), mload(_bytecode), _salt)

      if iszero(extcodesize(_result)) {
        revert(0, 0)
      }
    }

    require(_result != address(0), "Create2: Failed on deploy");
  }

  /**
   * @dev Deploys a contract using `CREATE2`. The address where the contract
   * will be deployed can be known in advance via {computeAddress}.
   *
   * The bytecode for a contract can be obtained from Solidity with
   * `type(contractName).creationCode`.
   *
   * Requirements:
   *
   * - `bytecode` must not be empty.
   * - `salt` must have not been used for `bytecode` already.
   * - the factory must have a balance of at least `amount`.
   * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
   */
  function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
    require(address(this).balance >= amount, "Create2: insufficient balance");
    require(bytecode.length != 0, "Create2: bytecode length is zero");
    /// @solidity memory-safe-assembly
    assembly {
      addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
    }
    require(addr != address(0), "Create2: Failed on deploy");
  }

  /**
   * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
   * `bytecodeHash` or `salt` will result in a new destination address.
   */
  function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
    return computeAddress(salt, bytecodeHash, address(this));
  }

  /**
   * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
   * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
   */
  function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
    /// @solidity memory-safe-assembly
    assembly {
      let ptr := mload(0x40) // Get free memory pointer

      // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
      // |-------------------|---------------------------------------------------------------------------|
      // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
      // | salt              |                                      BBBBBBBBBBBBB...BB                   |
      // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
      // | 0xFF              |            FF                                                             |
      // |-------------------|---------------------------------------------------------------------------|
      // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
      // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

      mstore(add(ptr, 0x40), bytecodeHash)
      mstore(add(ptr, 0x20), salt)
      mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
      let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
      mstore8(start, 0xff)
      addr := keccak256(start, 85)
    }
  }
}