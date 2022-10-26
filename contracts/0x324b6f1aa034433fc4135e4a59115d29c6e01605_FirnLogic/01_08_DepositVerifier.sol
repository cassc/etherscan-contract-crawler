// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "./InnerProductVerifier.sol";
import "./Utils.sol";

contract DepositVerifier {
    using Utils for uint256;
    using Utils for Utils.Point;

    InnerProductVerifier immutable _ip;

    constructor(address ip_) {
        _ip = InnerProductVerifier(ip_);
    }

    function g() internal view returns (Utils.Point memory) {
        return Utils.Point(_ip.gX(), _ip.gY());
    }

    function h() internal view returns (Utils.Point memory) {
        return Utils.Point(_ip.hX(), _ip.hY());
    }

    function gs(uint256 i) internal view returns (Utils.Point memory) {
        (bytes32 x, bytes32 y) = _ip.gs(i);
        return Utils.Point(x, y);
    }

    function hs(uint256 i) internal view returns (Utils.Point memory) {
        (bytes32 x, bytes32 y) = _ip.hs(i);
        return Utils.Point(x, y);
    }

    struct Locals {
        uint256 v;
        uint256 w;
        uint256 vPow;
        uint256 wPow;
        uint256[n][2] f; // could just allocate extra space in the proof?
        uint256[N] r; // each poly is an array of length N. evaluations of prods
        Utils.Point temp;
        Utils.Point C_XR;
        Utils.Point y_XR;

        uint256 c;
        Utils.Point A_D;
        Utils.Point A_X;
    }

    function verify(uint256 amount, Utils.Statement calldata statement, Utils.DepositProof calldata proof) external view {
        Locals memory locals;
        locals.v = uint256(keccak256(abi.encode(amount, statement.Y, statement.C, statement.D, proof.A, proof.B))).mod();
        locals.w = uint256(keccak256(abi.encode(locals.v, proof.C_XG, proof.y_XG))).mod();
        for (uint256 k = 0; k < n; k++) {
            locals.f[1][k] = proof.f[k];
            locals.f[0][k] = locals.w.sub(proof.f[k]);

            locals.temp = locals.temp.add(gs(k).mul(locals.f[1][k]));
            locals.temp = locals.temp.add(hs(k).mul(locals.f[1][k].mul(locals.f[0][k])));
        }
        require(proof.B.mul(locals.w).add(proof.A).eq(locals.temp.add(h().mul(proof.z_A))), "Bit-proof verification failed.");

        locals.r = Utils.assemblePolynomials(locals.f);
        locals.wPow = 1;
        for (uint256 k = 0; k < n; k++) {
            locals.C_XR = locals.C_XR.add(proof.C_XG[k].mul(locals.wPow.neg()));
            locals.y_XR = locals.y_XR.add(proof.y_XG[k].mul(locals.wPow.neg()));

            locals.wPow = locals.wPow.mul(locals.w);
        }
        locals.vPow = locals.v; // used to be 1
        for (uint256 i = 0; i < N; i++) {
            uint256 multiplier = locals.r[i].add(locals.vPow.mul(locals.wPow.sub(locals.r[i]))); // locals. ?
            locals.C_XR = locals.C_XR.add(statement.C[i].mul(multiplier));
            locals.y_XR = locals.y_XR.add(statement.Y[i].mul(multiplier));
            locals.vPow = locals.vPow.mul(locals.v); // used to do this only if (i > 0)
        }
        locals.C_XR = locals.C_XR.add(g().mul(amount.neg().mul(locals.wPow))); // this line is new

        locals.A_D = g().mul(proof.s_r).add(statement.D.mul(proof.c.neg())); // add(mul(locals.gR, proof.s_r), mul(locals.DR, proof.c.neg()));
        locals.A_X = locals.y_XR.mul(proof.s_r).add(locals.C_XR.mul(proof.c.neg()));

        locals.c = uint256(keccak256(abi.encode(locals.v, locals.A_D, locals.A_X))).mod();
        require(locals.c == proof.c, "Sigma protocol failure.");
    }
}