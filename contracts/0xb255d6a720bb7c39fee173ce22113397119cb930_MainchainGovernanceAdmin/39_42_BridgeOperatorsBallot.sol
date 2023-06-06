// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library BridgeOperatorsBallot {
  struct BridgeOperatorSet {
    uint256 period;
    uint256 epoch;
    address[] operators;
  }

  // keccak256("BridgeOperatorsBallot(uint256 period,uint256 epoch,address[] operators)");
  bytes32 public constant BRIDGE_OPERATORS_BALLOT_TYPEHASH =
    0xd679a49e9e099fa9ed83a5446aaec83e746b03ec6723d6f5efb29d37d7f0b78a;

  /**
   * @dev Verifies whether the ballot is valid or not.
   *
   * Requirements:
   * - The ballot is not for an empty operator set.
   * - The operator address list is in order.
   *
   */
  function verifyBallot(BridgeOperatorSet calldata _ballot) internal pure {
    require(_ballot.operators.length > 0, "BridgeOperatorsBallot: invalid array length");
    address _addr = _ballot.operators[0];
    for (uint _i = 1; _i < _ballot.operators.length; _i++) {
      require(_addr < _ballot.operators[_i], "BridgeOperatorsBallot: invalid order of bridge operators");
      _addr = _ballot.operators[_i];
    }
  }

  /**
   * @dev Returns hash of the ballot.
   */
  function hash(BridgeOperatorSet calldata _ballot) internal pure returns (bytes32) {
    bytes32 _operatorsHash;
    address[] memory _operators = _ballot.operators;

    assembly {
      _operatorsHash := keccak256(add(_operators, 32), mul(mload(_operators), 32))
    }

    return keccak256(abi.encode(BRIDGE_OPERATORS_BALLOT_TYPEHASH, _ballot.period, _ballot.epoch, _operatorsHash));
  }
}