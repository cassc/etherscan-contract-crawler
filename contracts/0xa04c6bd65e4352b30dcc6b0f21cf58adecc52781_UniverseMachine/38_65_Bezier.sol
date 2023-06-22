// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/Vector2.sol";
import "../Kohi/Fix64V1.sol";
import "../Kohi/Trig256.sol";

struct Bezier
{
    Vector2 a;
    Vector2 b;
    Vector2 c;
    Vector2 d;
    int32 len;
    int64[] arcLengths;
}

library BezierMethods {

    function create(Vector2 memory t, Vector2 memory h, Vector2 memory s, Vector2 memory i) internal pure returns (Bezier memory result) {
        result.a = t;
        result.b = h;
        result.c = s;
        result.d = i;
        result.len = 100;
        result.arcLengths = new int64[](uint32(result.len + 1));
        result.arcLengths[0] = 0;

        int64 n = xFunc(result, 0);
        int64 r = yFunc(result, 0);
        int64 e = 0;

        for (int32 ax = 1; ax <= result.len; ax += 1)
        {
            int64 z = Fix64V1.mul(42949672 /* 0.01 */, ax * Fix64V1.ONE);
            int64 c = xFunc(result, z);
            int64 u = yFunc(result, z);

            int64 y = Fix64V1.sub(n, c);
            int64 o = Fix64V1.sub(r, u);

            int64 t0 = Fix64V1.mul(y, y);
            int64 t1 = Fix64V1.mul(o, o);

            int64 sqrt = Fix64V1.add(t0, t1);
            e = Fix64V1.add(e, Trig256.sqrt(sqrt));
            result.arcLengths[uint32(ax)] = e;
            n = c;
            r = u;
        }
    }

    function xFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.x)));
        int64 t2 = Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(t0, t0), 3 * Fix64V1.ONE), t), self.b.x);
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.x)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.x)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));
    }

    function yFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.y)));
        int64 t2 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t, self.b.y))));
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.y)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.y)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));        
    }

    function mx(Bezier memory self,int64 t) internal pure returns (int64) {
        return xFunc(self, map(self, t));
    }

    function my(Bezier memory self,int64 t) internal pure returns (int64) {
        return yFunc(self, map(self, t));
    }

    function map(Bezier memory self, int64 t) private pure returns (int64) {
        int64 h = Fix64V1.mul(t, self.arcLengths[uint32(self.len)]);
        int32 n = 0;
        int32 s = 0;
        for (int32 i = self.len; s < i;)
        {
            n = s + ((i - s) / 2 | 0);
            if (self.arcLengths[uint32(n)] < h)
            {
                s = n + 1;
            }
            else
            {
                i = n;
            }
        }
        if (self.arcLengths[uint32(n)] > h)
        {
            n--;
        }
        int64 r = self.arcLengths[uint32(n)];
        return r == h ? Fix64V1.div(n * Fix64V1.ONE, self.len * Fix64V1.ONE) :
            Fix64V1.div(
                Fix64V1.add(n * Fix64V1.ONE, Fix64V1.div(Fix64V1.sub(h, r), Fix64V1.sub(self.arcLengths[uint32(n + 1)], r))),
                self.len * Fix64V1.ONE);
    }
}