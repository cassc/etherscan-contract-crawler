// SPDX-License-Identifier: LGPL 3.0
pragma solidity ^0.8.18;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author ARPA-Network adapted from https://github.com/musalbas/solidity-BN256G2
 * @dev Homepage: https://github.com/ARPA-Network/BLS-TSS-Network
 */

library BN256G2 {
    uint256 public constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 public constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 public constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint256 public constant PTXX = 0;
    uint256 public constant PTXY = 1;
    uint256 public constant PTYX = 2;
    uint256 public constant PTYY = 3;
    uint256 public constant PTZX = 4;
    uint256 public constant PTZY = 5;

    function ecTwistAdd(uint256[4] memory pt1, uint256[4] memory pt2) internal view returns (uint256[4] memory pt) {
        (uint256 xx, uint256 xy, uint256 yx, uint256 yy) =
            ecTwistAdd(pt1[0], pt1[1], pt1[2], pt1[3], pt2[0], pt2[1], pt2[2], pt2[3]);
        pt = [xx, xy, yx, yy];
    }

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ecTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    ) internal view returns (uint256, uint256, uint256, uint256) {
        if (pt1xx == 0 && pt1xy == 0 && pt1yx == 0 && pt1yy == 0) {
            if (!(pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0)) {
                assert(isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));
            }
            return (pt2xx, pt2xy, pt2yx, pt2yy);
        } else if (pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0) {
            assert(isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
            return (pt1xx, pt1xy, pt1yx, pt1yy);
        }

        assert(isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
        assert(isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));

        uint256[6] memory pt1 = [pt1xx, pt1xy, pt1yx, pt1yy, 1, 0];
        uint256[6] memory pt2 = [pt2xx, pt2xy, pt2yx, pt2yy, 1, 0];
        uint256[6] memory pt3 = ecTwistAddJacobian(pt1, pt2);

        return fromJacobian(pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]);
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function fq2Mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function fq2Muc(uint256 xx, uint256 xy, uint256 c) internal pure returns (uint256, uint256) {
        return (mulmod(xx, c, FIELD_MODULUS), mulmod(xy, c, FIELD_MODULUS));
    }

    function fq2Sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256 rx, uint256 ry) {
        return (submod(xx, yx, FIELD_MODULUS), submod(xy, yy, FIELD_MODULUS));
    }

    function fq2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv =
            modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (mulmod(x, inv, FIELD_MODULUS), FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS));
    }

    function isOnCurve(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = fq2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = fq2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = fq2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = fq2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = fq2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), a)
            mstore(add(freemem, 0x80), sub(n, 2))
            mstore(add(freemem, 0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        // solhint-disable-next-line reason-string
        require(success);
    }

    function fromJacobian(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy)
        internal
        view
        returns (uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy)
    {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = fq2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = fq2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = fq2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function ecTwistAddJacobian(uint256[6] memory pt1, uint256[6] memory pt2)
        public
        pure
        returns (uint256[6] memory pt3)
    {
        if (pt1[4] == 0 && pt1[5] == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                (pt2[0], pt2[1], pt2[2], pt2[3], pt2[4], pt2[5]);
            return pt3;
        } else if (pt2[4] == 0 && pt2[5] == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                (pt1[0], pt1[1], pt1[2], pt1[3], pt1[4], pt1[5]);
            return pt3;
        }

        (pt2[2], pt2[3]) = fq2Mul(pt2[2], pt2[3], pt1[4], pt1[5]); // U1 = y2 * z1
        (pt3[PTYX], pt3[PTYY]) = fq2Mul(pt1[2], pt1[3], pt2[4], pt2[5]); // U2 = y1 * z2
        (pt2[0], pt2[1]) = fq2Mul(pt2[0], pt2[1], pt1[4], pt1[5]); // V1 = x2 * z1
        (pt3[PTZX], pt3[PTZY]) = fq2Mul(pt1[0], pt1[1], pt2[4], pt2[5]); // V2 = x1 * z2

        if (pt2[0] == pt3[PTZX] && pt2[1] == pt3[PTZY]) {
            if (pt2[2] == pt3[PTYX] && pt2[3] == pt3[PTYY]) {
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                    ecTwistDoubleJacobian(pt1[0], pt1[1], pt1[2], pt1[3], pt1[4], pt1[5]);
                return pt3;
            }
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (1, 0, 1, 0, 0, 0);
            return pt3;
        }

        (pt2[4], pt2[5]) = fq2Mul(pt1[4], pt1[5], pt2[4], pt2[5]); // W = z1 * z2
        (pt1[0], pt1[1]) = fq2Sub(pt2[2], pt2[3], pt3[PTYX], pt3[PTYY]); // U = U1 - U2
        (pt1[2], pt1[3]) = fq2Sub(pt2[0], pt2[1], pt3[PTZX], pt3[PTZY]); // V = V1 - V2
        (pt1[4], pt1[5]) = fq2Mul(pt1[2], pt1[3], pt1[2], pt1[3]); // V_squared = V * V
        (pt2[2], pt2[3]) = fq2Mul(pt1[4], pt1[5], pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
        (pt1[4], pt1[5]) = fq2Mul(pt1[4], pt1[5], pt1[2], pt1[3]); // V_cubed = V * V_squared
        (pt3[PTZX], pt3[PTZY]) = fq2Mul(pt1[4], pt1[5], pt2[4], pt2[5]); // newz = V_cubed * W
        (pt2[0], pt2[1]) = fq2Mul(pt1[0], pt1[1], pt1[0], pt1[1]); // U * U
        (pt2[0], pt2[1]) = fq2Mul(pt2[0], pt2[1], pt2[4], pt2[5]); // U * U * W
        (pt2[0], pt2[1]) = fq2Sub(pt2[0], pt2[1], pt1[4], pt1[5]); // U * U * W - V_cubed
        (pt2[4], pt2[5]) = fq2Muc(pt2[2], pt2[3], 2); // 2 * V_squared_times_V2
        (pt2[0], pt2[1]) = fq2Sub(pt2[0], pt2[1], pt2[4], pt2[5]); // A = U * U * W - V_cubed - 2 * V_squared_times_V2
        (pt3[PTXX], pt3[PTXY]) = fq2Mul(pt1[2], pt1[3], pt2[0], pt2[1]); // newx = V * A
        (pt1[2], pt1[3]) = fq2Sub(pt2[2], pt2[3], pt2[0], pt2[1]); // V_squared_times_V2 - A
        (pt1[2], pt1[3]) = fq2Mul(pt1[0], pt1[1], pt1[2], pt1[3]); // U * (V_squared_times_V2 - A)
        (pt1[0], pt1[1]) = fq2Mul(pt1[4], pt1[5], pt3[PTYX], pt3[PTYY]); // V_cubed * U2
        (pt3[PTYX], pt3[PTYY]) = fq2Sub(pt1[2], pt1[3], pt1[0], pt1[1]); // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function ecTwistDoubleJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    ) public pure returns (uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) {
        (pt2xx, pt2xy) = fq2Muc(pt1xx, pt1xy, 3); // 3 * x
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = fq2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = fq2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = fq2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = fq2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = fq2Muc(pt2yx, pt2yy, 8); // 8 * B
        (pt1xx, pt1xy) = fq2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = fq2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = fq2Muc(pt2yx, pt2yy, 4); // 4 * B
        (pt2yx, pt2yy) = fq2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = fq2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = fq2Muc(pt1yx, pt1yy, 8); // 8 * y
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = fq2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = fq2Muc(pt1xx, pt1xy, 2); // 2 * H
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = fq2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = fq2Muc(pt2zx, pt2zy, 8); // newz = 8 * S * S_squared
    }
}