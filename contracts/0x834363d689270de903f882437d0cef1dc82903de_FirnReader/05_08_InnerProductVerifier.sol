// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "./Utils.sol";

contract InnerProductVerifier {
    using Utils for uint256;
    using Utils for Utils.Point;

    bytes32 public immutable gX;
    bytes32 public immutable gY;
    bytes32 public immutable hX;
    bytes32 public immutable hY;
    // above, emulating immutable `Utils.Point`s using raw `bytes32`s. save some sloads later.
    Utils.Point[M << 1] public gs;
    Utils.Point[M << 1] public hs;
    // have to use storage, not immutable, because solidity doesn't support non-primitive immutable types

    constructor() {
        Utils.Point memory gTemp = Utils.mapInto("g");
        gX = gTemp.x;
        gY = gTemp.y;
        Utils.Point memory hTemp = Utils.mapInto("h");
        hX = hTemp.x;
        hY = hTemp.y;
        for (uint256 i = 0; i < M << 1; i++) {
            gs[i] = Utils.mapInto("g", i);
            hs[i] = Utils.mapInto("h", i);
        }
    }

    struct Locals {
        uint256 o;
        Utils.Point P;
        uint256[m + 1] challenges;
        uint256[M << 1] s;
    }

    function verify(Utils.InnerProductStatement calldata statement, Utils.InnerProductProof calldata proof, bool transfer) external view {
        Locals memory locals;
        locals.o = statement.salt;
        locals.P = statement.P;
        uint256 M_ = M << (transfer ? 1 : 0);
        uint256 m_ = m + (transfer ? 1 : 0);

        for (uint256 i = 0; i < m_; i++) {
            locals.o = uint256(keccak256(abi.encode(locals.o, proof.L[i], proof.R[i]))).mod(); // overwrites
            locals.challenges[i] = locals.o;
            uint256 inverse = locals.o.inv();
            locals.P = locals.P.add(proof.L[i].mul(locals.o.mul(locals.o))).add(proof.R[i].mul(inverse.mul(inverse)));
        }

        locals.s[0] = 1;
        for (uint256 i = 0; i < m_; i++) locals.s[0] = locals.s[0].mul(locals.challenges[i]);
        locals.s[0] = locals.s[0].inv();
        for (uint256 i = 0; i < m_; i++) {
            for (uint256 j = 0; j < M_; j += 1 << m_ - i) {
                locals.s[j + (1 << m_ - i - 1)] = locals.s[j].mul(locals.challenges[i]).mul(locals.challenges[i]);
            }
        }

        Utils.Point memory temp = statement.u.mul(proof.a.mul(proof.b));
        for (uint256 i = 0; i < M_; i++) {
            temp = temp.add(gs[i].mul(locals.s[i].mul(proof.a)));
            temp = temp.add(statement.hs[i].mul(locals.s[M_ - 1 - i].mul(proof.b)));
        }
        require(temp.eq(locals.P), "Inner product proof failed.");
    }
}