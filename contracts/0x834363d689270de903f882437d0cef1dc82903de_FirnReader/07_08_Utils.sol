// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

uint256 constant n = 4;
uint256 constant N = 1 << n;
uint256 constant m = 5;
uint256 constant M = 1 << m;

library Utils {
    uint256 constant GROUP_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 constant PPLUS1DIV4 = 0x0c19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;

    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        return addmod(x, y, GROUP_ORDER);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulmod(x, y, GROUP_ORDER);
    }

    function inv(uint256 x) internal view returns (uint256) {
        return exp(x, GROUP_ORDER - 2);
    }

    function mod(uint256 x) internal pure returns (uint256) {
        return x % GROUP_ORDER;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x - y : GROUP_ORDER - y + x;
    }

    function neg(uint256 x) internal pure returns (uint256) {
        return GROUP_ORDER - x;
    }

    function exp(uint256 base, uint256 exponent) internal view returns (uint256 output) {
        uint256 order = GROUP_ORDER;
        assembly {
            let location := mload(0x40)
            mstore(location, 0x20)
            mstore(add(location, 0x20), 0x20)
            mstore(add(location, 0x40), 0x20)
            mstore(add(location, 0x60), base)
            mstore(add(location, 0x80), exponent)
            mstore(add(location, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, location, 0xc0, location, 0x20)) {
                revert(0, 0)
            }
            output := mload(location)
        }
    }

    function fieldExp(uint256 base, uint256 exponent) internal view returns (uint256 output) { // warning: mod p, not q
        uint256 order = FIELD_ORDER;
        assembly {
            let location := mload(0x40)
            mstore(location, 0x20)
            mstore(add(location, 0x20), 0x20)
            mstore(add(location, 0x40), 0x20)
            mstore(add(location, 0x60), base)
            mstore(add(location, 0x80), exponent)
            mstore(add(location, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, location, 0xc0, location, 0x20)) {
                revert(0, 0)
            }
            output := mload(location)
        }
    }

    struct Point {
        bytes32 x;
        bytes32 y;
    }

    function add(Point memory p1, Point memory p2) internal view returns (Point memory r) {
        assembly {
            let location := mload(0x40)
            mstore(location, mload(p1))
            mstore(add(location, 0x20), mload(add(p1, 0x20)))
            mstore(add(location, 0x40), mload(p2))
            mstore(add(location, 0x60), mload(add(p2, 0x20)))
            if iszero(staticcall(gas(), 0x06, location, 0x80, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function mul(Point memory p, uint256 s) internal view returns (Point memory r) {
        assembly {
            let location := mload(0x40)
            mstore(location, mload(p))
            mstore(add(location, 0x20), mload(add(p, 0x20)))
            mstore(add(location, 0x40), s)
            if iszero(staticcall(gas(), 0x07, location, 0x60, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function neg(Point memory p) internal pure returns (Point memory) {
        return Point(p.x, bytes32(FIELD_ORDER - uint256(p.y))); // p.y should already be reduced mod P?
    }

    function eq(Point memory p1, Point memory p2) internal pure returns (bool) {
        return p1.x == p2.x && p1.y == p2.y;
    }

    function decompress(bytes32 input) internal view returns (Point memory) {
        if (input == 0x00) return Point(0x00, 0x00);
        uint256 x = uint256(input);
        uint256 sign = (x & 0x8000000000000000000000000000000000000000000000000000000000000000) >> 255;
        x &= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 ySquared = fieldExp(x, 3) + 3;
        uint256 y = fieldExp(ySquared, PPLUS1DIV4);
        Point memory result = Point(bytes32(x), bytes32(y));
        if (sign != y & 0x01) return neg(result);
        return result;
    }

    function compress(Point memory input) internal pure returns (bytes32) {
        uint256 result = uint256(input.x);
        if (uint256(input.y) & 0x01 == 0x01) result |= 0x8000000000000000000000000000000000000000000000000000000000000000;
        return bytes32(result);
    }

    function mapInto(uint256 seed) internal view returns (Point memory) {
        uint256 y;
        while (true) {
            uint256 ySquared = fieldExp(seed, 3) + 3; // addmod instead of add: waste of gas, plus function overhead cost
            y = fieldExp(ySquared, PPLUS1DIV4);
            if (fieldExp(y, 2) == ySquared) {
                break;
            }
            seed += 1;
        }
        return Point(bytes32(seed), bytes32(y));
    }

    function mapInto(string memory input) internal view returns (Point memory) {
        return mapInto(uint256(keccak256(abi.encodePacked(input))) % FIELD_ORDER);
    }

    function mapInto(string memory input, uint256 i) internal view returns (Point memory) {
        return mapInto(uint256(keccak256(abi.encodePacked(input, i))) % FIELD_ORDER);
    }

    function slice(bytes memory input, uint256 start) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(add(input, 0x20), start))
        }
    }

    struct Statement {
        Point[N] Y;
        Point[N] CLn;
        Point[N] CRn;
        Point[N] C;
        Point D;
        uint256 epoch;
        Point u;
        uint256 fee;
    }

    struct DepositProof {
        Point A;
        Point B;

        Point[n] C_XG;
        Point[n] y_XG;

        uint256[n] f;
        uint256 z_A;

        uint256 c;
        uint256 s_r;
    }

    function deserializeDeposit(bytes memory arr) internal view returns (DepositProof memory proof) {
        proof.A = decompress(slice(arr, 0));
        proof.B = decompress(slice(arr, 32));

        for (uint256 k = 0; k < n; k++) {
            proof.C_XG[k] = decompress(slice(arr, 64 + k * 32));
            proof.y_XG[k] = decompress(slice(arr, 64 + (k + n) * 32));
            proof.f[k] = uint256(slice(arr, 64 + n * 64 + k * 32));
        }
        uint256 starting = n * 96;
        proof.z_A = uint256(slice(arr, 64 + starting));

        proof.c = uint256(slice(arr, 96 + starting));
        proof.s_r = uint256(slice(arr, 128 + starting));

        return proof;
    }

    struct TransferProof {
        Point BA;
        Point BS;
        Point A;
        Point B;

        Point[n] CLnG;
        Point[n] CRnG;
        Point[n] C_0G;
        Point[n] DG;
        Point[n] y_0G;
        Point[n] gG;
        Point[n] C_XG;
        Point[n] y_XG;

        uint256[n][2] f;
        uint256 z_A;

        Point T_1;
        Point T_2;
        uint256 tHat;
        uint256 mu;

        uint256 c;
        uint256 s_sk;
        uint256 s_r;
        uint256 s_b;
        uint256 s_tau;

        InnerProductProof ip;
    }

    function deserializeTransfer(bytes memory arr) internal view returns (TransferProof memory proof) {
        proof.BA = decompress(slice(arr, 0));
        proof.BS = decompress(slice(arr, 32));
        proof.A = decompress(slice(arr, 64));
        proof.B = decompress(slice(arr, 96));

        for (uint256 k = 0; k < n; k++) {
            proof.CLnG[k] = decompress(slice(arr, 128 + k * 32));
            proof.CRnG[k] = decompress(slice(arr, 128 + (k + n) * 32));
            proof.C_0G[k] = decompress(slice(arr, 128 + n * 64 + k * 32));
            proof.DG[k] = decompress(slice(arr, 128 + n * 96 + k * 32));
            proof.y_0G[k] = decompress(slice(arr, 128 + n * 128 + k * 32));
            proof.gG[k] = decompress(slice(arr, 128 + n * 160 + k * 32));
            proof.C_XG[k] = decompress(slice(arr, 128 + n * 192 + k * 32));
            proof.y_XG[k] = decompress(slice(arr, 128 + n * 224 + k * 32));
            proof.f[0][k] = uint256(slice(arr, 128 + n * 256 + k * 32));
            proof.f[1][k] = uint256(slice(arr, 128 + n * 288 + k * 32));
        }

        uint256 starting = n * 320;
        proof.z_A = uint256(slice(arr, 128 + starting));

        proof.T_1 = decompress(slice(arr, 160 + starting));
        proof.T_2 = decompress(slice(arr, 192 + starting));
        proof.tHat = uint256(slice(arr, 224 + starting));
        proof.mu = uint256(slice(arr, 256 + starting));

        proof.c = uint256(slice(arr, 288 + starting));
        proof.s_sk = uint256(slice(arr, 320 + starting));
        proof.s_r = uint256(slice(arr, 352 + starting));
        proof.s_b = uint256(slice(arr, 384 + starting));
        proof.s_tau = uint256(slice(arr, 416 + starting));

        for (uint256 i = 0; i < m + 1; i++) {
            proof.ip.L[i] = decompress(slice(arr, 448 + starting + i * 32));
            proof.ip.R[i] = decompress(slice(arr, 448 + starting + (i + m + 1) * 32));
        }
        proof.ip.a = uint256(slice(arr, 448 + starting + (m + 1) * 64));
        proof.ip.b = uint256(slice(arr, 480 + starting + (m + 1) * 64));

        return proof;
    }

    struct WithdrawalProof {
        Point BA;
        Point BS;
        Point A;
        Point B;

        Point[n] CLnG;
        Point[n] CRnG;
        Point[n] y_0G;
        Point[n] gG;
        Point[n] C_XG;
        Point[n] y_XG;

        uint256[n] f;
        uint256 z_A;

        Point T_1;
        Point T_2;
        uint256 tHat;
        uint256 mu;

        uint256 c;
        uint256 s_sk;
        uint256 s_r;
        uint256 s_b;
        uint256 s_tau;

        InnerProductProof ip;
    }

    function deserializeWithdrawal(bytes memory arr) internal view returns (WithdrawalProof memory proof) {
        proof.BA = decompress(slice(arr, 0));
        proof.BS = decompress(slice(arr, 32));
        proof.A = decompress(slice(arr, 64));
        proof.B = decompress(slice(arr, 96));

        for (uint256 k = 0; k < n; k++) {
            proof.CLnG[k] = decompress(slice(arr, 128 + k * 32));
            proof.CRnG[k] = decompress(slice(arr, 128 + (k + n) * 32));
            proof.y_0G[k] = decompress(slice(arr, 128 + n * 64 + k * 32));
            proof.gG[k] = decompress(slice(arr, 128 + n * 96 + k * 32));
            proof.C_XG[k] = decompress(slice(arr, 128 + n * 128 + k * 32));
            proof.y_XG[k] = decompress(slice(arr, 128 + n * 160 + k * 32));
            proof.f[k] = uint256(slice(arr, 128 + n * 192 + k * 32));
        }
        uint256 starting = n * 224;
        proof.z_A = uint256(slice(arr, 128 + starting));

        proof.T_1 = decompress(slice(arr, 160 + starting));
        proof.T_2 = decompress(slice(arr, 192 + starting));
        proof.tHat = uint256(slice(arr, 224 + starting));
        proof.mu = uint256(slice(arr, 256 + starting));

        proof.c = uint256(slice(arr, 288 + starting));
        proof.s_sk = uint256(slice(arr, 320 + starting));
        proof.s_r = uint256(slice(arr, 352 + starting));
        proof.s_b = uint256(slice(arr, 384 + starting));
        proof.s_tau = uint256(slice(arr, 416 + starting));

        for (uint256 i = 0; i < m; i++) { // will leave the `m`th element empty
            proof.ip.L[i] = decompress(slice(arr, 448 + starting + i * 32));
            proof.ip.R[i] = decompress(slice(arr, 448 + starting + (i + m) * 32));
        }
        proof.ip.a = uint256(slice(arr, 448 + starting + m * 64));
        proof.ip.b = uint256(slice(arr, 480 + starting + m * 64));

        return proof;
    }

    struct InnerProductStatement {
        uint256 salt;
        Point[M << 1] hs; // "overridden" parameters.
        Point u;
        Point P;
    }

    struct InnerProductProof {
        Point[m + 1] L;
        Point[m + 1] R;
        uint256 a;
        uint256 b;
    }

    function assemblePolynomials(uint256[n][2] memory f) internal pure returns (uint256[N] memory result) {
        // f is a 2m-by-2 array... containing the f's and x - f's, twice (i.e., concatenated).
        // output contains two "rows", each of length N.
        result[0] = 1;
        for (uint256 k = 0; k < n; k++) {
            for (uint256 i = 0; i < N; i += 1 << n - k) {
                result[i + (1 << n - 1 - k)] = mul(result[i], f[1][n - 1 - k]);
                result[i] = mul(result[i], f[0][n - 1 - k]);
            }
        }
    }
}