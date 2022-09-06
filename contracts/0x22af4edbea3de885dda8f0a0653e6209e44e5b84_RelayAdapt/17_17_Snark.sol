// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import { G1Point, G2Point, VerifyingKey, SnarkProof, SNARK_SCALAR_FIELD } from "./Globals.sol";

library Snark {
  uint256 private constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
  uint256 private constant PAIRING_INPUT_SIZE = 24;
  uint256 private constant PAIRING_INPUT_WIDTH = 768; // PAIRING_INPUT_SIZE * 32

  /**
   * @notice Computes the negation of point p
   * @dev The negation of p, i.e. p.plus(p.negate()) should be zero.
   * @return result
   */
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    if (p.x == 0 && p.y == 0) return G1Point(0, 0);

    // check for valid points y^2 = x^3 +3 % PRIME_Q
    uint256 rh = mulmod(p.x, p.x, PRIME_Q); //x^2
    rh = mulmod(rh, p.x, PRIME_Q); //x^3
    rh = addmod(rh, 3, PRIME_Q); //x^3 + 3
    uint256 lh = mulmod(p.y, p.y, PRIME_Q); //y^2
    require(lh == rh, "Snark: Invalid negation");

    return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
    }

  /**
   * @notice Adds 2 G1 points
   * @return result
   */
  function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory) {
    // Format inputs
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;

    // Setup output variables
    bool success;
    G1Point memory result;

    // Add points
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0x80, result, 0x40)
    }

    // Check if operation succeeded
    require(success, "Snark: Add Failed");

    return result;
  }

  /**
   * @notice Scalar multiplies two G1 points p, s
   * @dev The product of a point on G1 and a scalar, i.e.
   * p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
   * points p.
   * @return r - result
   */
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;
    
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
    }

    // Check multiplication succeeded
    require(success, "Snark: Scalar Multiplication Failed");
  }

  /**
   * @notice Performs pairing check on points
   * @dev The result of computing the pairing check
   * e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
   * For example,
   * pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
   * @return if pairing check passed
   */
  function pairing(
    G1Point memory _a1,
    G2Point memory _a2,
    G1Point memory _b1,
    G2Point memory _b2,
    G1Point memory _c1,
    G2Point memory _c2,
    G1Point memory _d1,
    G2Point memory _d2
  ) internal view returns (bool) {
    uint256[PAIRING_INPUT_SIZE] memory input = [
      _a1.x,
      _a1.y,
      _a2.x[0],
      _a2.x[1],
      _a2.y[0],
      _a2.y[1],
      _b1.x,
      _b1.y,
      _b2.x[0],
      _b2.x[1],
      _b2.y[0],
      _b2.y[1],
      _c1.x,
      _c1.y,
      _c2.x[0],
      _c2.x[1],
      _c2.y[0],
      _c2.y[1],
      _d1.x,
      _d1.y,
      _d2.x[0],
      _d2.x[1],
      _d2.y[0],
      _d2.y[1]
    ];

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(
        sub(gas(), 2000),
        8,
        input,
        PAIRING_INPUT_WIDTH,
        out,
        0x20
      )
    }

    // Check if operation succeeded
    require(success, "Snark: Pairing Verification Failed");

    return out[0] != 0;
  }

  /**
    * @notice Verifies snark proof against proving key
    * @param _vk - Verification Key
    * @param _proof - snark proof
    * @param _inputs - inputs
    */
  function verify(
    VerifyingKey memory _vk,
    SnarkProof memory _proof,
    uint256[] memory _inputs
  ) internal view returns (bool) {
    // Compute the linear combination vkX
    G1Point memory vkX = G1Point(0, 0);
    
    // Loop through every input
    for (uint i = 0; i < _inputs.length; i++) {
      // Make sure inputs are less than SNARK_SCALAR_FIELD
      require(_inputs[i] < SNARK_SCALAR_FIELD, "Snark: Input > SNARK_SCALAR_FIELD");

      // Add to vkX point
      vkX = add(vkX, scalarMul(_vk.ic[i + 1], _inputs[i]));
  }

    // Compute final vkX point
    vkX = add(vkX, _vk.ic[0]);

    // Verify pairing and return
    return pairing(
      negate(_proof.a),
      _proof.b,
      _vk.alpha1,
      _vk.beta2,
      vkX,
      _vk.gamma2,
      _proof.c,
      _vk.delta2
    );
  }
}