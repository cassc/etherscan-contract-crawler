// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './@uniswap/lib/contracts/libraries/FixedPoint.sol';

struct OraclePrice {
    FixedPoint.uq112x112 base;
    FixedPoint.uq112x112 LP;
}

library PriceLibrary {
    using FixedPoint for FixedPoint.uq112x112;
    using PriceLibrary for OraclePrice;

    function isEmpty(OraclePrice memory self) internal pure returns (bool) {
        return self.base._x == 0;
    }

    function muluq(OraclePrice memory self, FixedPoint.uq112x112 memory scale) internal pure returns (OraclePrice memory) {
        return OraclePrice(
            self.base.muluq(scale),
            self.LP.muluq(scale.sqrt())
        );
    }

    function divuq(OraclePrice memory self, FixedPoint.uq112x112 memory scale) internal pure returns (OraclePrice memory) {
        return OraclePrice(
            self.base.divuq(scale),
            self.LP.divuq(scale.sqrt())
        );
    }
}