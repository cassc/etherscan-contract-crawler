// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./MulDivMath.sol";
import "./TwoPower.sol";

library Liquidity {

    struct Data {
        uint128 liquidity;
        uint256 lastFeeScaleX_128;
        uint256 lastFeeScaleY_128;
        uint256 tokenOwedX;
        uint256 tokenOwedY;
    }
    
    // delta cannot be int128.min and liquidDelta of any one point will not be int128.min
    function liquidityAddDelta(uint128 l, int128 delta) internal pure returns (uint128 nl) {
        if (delta < 0) {
            // in the pool, max(liquidity) < 2 ** 127
            // so, -delta > -2**127, -delta <= int128.max
            nl = l - uint128(-delta);
        } else {
            nl = l + uint128(delta);
        }
    }

    function get(
        mapping(bytes32 => Data) storage self,
        address minter,
        int24 tl,
        int24 tr
    ) internal view returns (Liquidity.Data storage data) {
        data = self[keccak256(abi.encodePacked(minter, tl, tr))];
    }

    function update(
        Liquidity.Data storage self,
        int128 delta,
        uint256 feeScaleX_128,
        uint256 feeScaleY_128
    ) internal {
        Data memory data = self;
        uint128 liquidity;
        if (delta == 0) {
            require(data.liquidity > 0, "L>0");
            liquidity = data.liquidity;
        } else {
            liquidity = liquidityAddDelta(data.liquidity, delta);
        }
        uint256 deltaScaleX = data.lastFeeScaleX_128;
        uint256 deltaScaleY = data.lastFeeScaleY_128;
        // use assembly to prevent revert if overflow
        // data.lastFeeScaleX(Y)_128 may be "negative" (>=2^255)
        assembly {
            deltaScaleX := sub(feeScaleX_128, deltaScaleX)
            deltaScaleY := sub(feeScaleY_128, deltaScaleY)
        }
        uint256 feeX = MulDivMath.mulDivFloor(deltaScaleX, data.liquidity, TwoPower.Pow128);
        uint256 feeY = MulDivMath.mulDivFloor(deltaScaleY, data.liquidity, TwoPower.Pow128);
        data.liquidity = liquidity;

        // update the position
        if (delta != 0) self.liquidity = liquidity;
        self.lastFeeScaleX_128 = feeScaleX_128;
        self.lastFeeScaleY_128 = feeScaleY_128;
        if (feeX > 0 || feeY > 0) {
            // need to withdraw before overflow
            self.tokenOwedX += feeX;
            self.tokenOwedY += feeY;
        }
    }
    
}