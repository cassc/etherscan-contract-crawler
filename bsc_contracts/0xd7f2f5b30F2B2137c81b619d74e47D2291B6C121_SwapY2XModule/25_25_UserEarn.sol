// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./MulDivMath.sol";
import "./TwoPower.sol";
import "./Converter.sol";
import "./MaxMinMath.sol";

library UserEarn {

    // describe user's earning info for a limit order
    struct Data {
        // total amount of earned token by all users at this point 
        // with same direction (sell x or sell y) as of the last update(add/dec)
        uint256 lastAccEarn;
        // remaing amount of token on sale in this limit order
        uint128 sellingRemain;
        // uncollected decreased token
        uint128 sellingDec;
        // unassigned and unlegacy earned token
        // earned token before collected need to be assigned
        uint128 earn;
        // unassigned and legacy earned token
        uint128 legacyEarn;
        // assigned but uncollected earned token (both unlegacy and legacy)
        uint128 earnAssign;
    }
    
    function get(
        mapping(bytes32 => Data) storage self,
        address user,
        int24 point
    ) internal view returns (UserEarn.Data storage data) {
        data = self[keccak256(abi.encodePacked(user, point))];
    }

    /// @notice update UserEarn info for an unlegacy (uncleared during swap) limit order.
    ///    update strategy is 'first claim first earn', etc, earned token will be transformed for
    ///    limit orders which is update first
    /// @param self UserEarn storage object of target limit order
    /// @param currAccEarn 'accEarn' value of corresponding point order on swap pool.
    ///    accumulate amount of earned token 
    /// @param sqrtPrice_96 describe price of limit order
    /// @param totalEarn remained(undistributed) amount of earned token of unlegacy limit order on corresponding point
    /// @param isEarnY direction of corresponding limit order.
    function updateUnlegacyOrder(
        UserEarn.Data storage self,
        uint256 currAccEarn,
        uint160 sqrtPrice_96,
        uint128 totalEarn,
        bool isEarnY
    ) internal returns (uint128 totalEarnRemain, uint128 claimSold, uint128 claimEarn) {
        Data memory data = self;

        // first, we compute how many earned token remained on the point order
        uint256 earn = currAccEarn - data.lastAccEarn;
        if (earn > totalEarn) {
            earn = totalEarn;
        }
        // second, compute how many sold token according to the 'first claim first earn' strategy,
        // etc, for earnY, sold = min(sellingRemain, earn / price)
        //      for earnX, sold = min(sellingRemain, earn * price)
        uint256 sold;
        if (isEarnY) {
            uint256 l = MulDivMath.mulDivCeil(earn, TwoPower.Pow96, sqrtPrice_96);
            sold = MulDivMath.mulDivCeil(l, TwoPower.Pow96, sqrtPrice_96);
        } else {
            uint256 l = MulDivMath.mulDivCeil(earn, sqrtPrice_96, TwoPower.Pow96);
            sold = MulDivMath.mulDivCeil(l, sqrtPrice_96, TwoPower.Pow96);
        }
        if (sold > data.sellingRemain) {
            sold = data.sellingRemain;
            if (isEarnY) {
                uint256 l = MulDivMath.mulDivFloor(sold, sqrtPrice_96, TwoPower.Pow96);
                earn = MulDivMath.mulDivFloor(l, sqrtPrice_96, TwoPower.Pow96);
            } else {
                uint256 l = MulDivMath.mulDivFloor(sold, TwoPower.Pow96, sqrtPrice_96);
                earn = MulDivMath.mulDivFloor(l, TwoPower.Pow96, sqrtPrice_96);
            }
        }
        // sold1 = ceil(ceil(earn1 * Q / P) * Q / P)
        // if sold1 <= data.sellingRemain, earn = earn1 <= totalEarn, sold=sold1 <= data.sellingRemain
        // if sold1 > data.sellingRemain, sold = data.sellingRemain
        //     sold1 - 1 < ceil(ceil(earn1 * Q / P) * Q / P)
        //  => sold1 - 1 < ceil(earn1 * Q / P) * Q / P
        //  => floor((sold1 - 1) * P / Q) < ceil(earn1 * Q / P)
        //  => floor((sold1 - 1) * P / Q) < earn1 * Q / P
        //  => earn = floor(floor((sold1 - 1) * P / Q) * P / Q) < earn1 <= totalEarn

        // thirdly, update info of userEarn object

        // earn <= totalEarn
        data.earn += uint128(earn);
        // sold <= data.sellingRemain
        data.sellingRemain -= uint128(sold);
        self.lastAccEarn = currAccEarn;
        if (earn > 0) {
            self.earn = data.earn;
        }
        if (sold > 0) {
            self.sellingRemain = data.sellingRemain;
        }
        claimSold = uint128(sold);
        claimEarn = uint128(earn);
        // earn <= totalEarn
        totalEarnRemain = totalEarn - claimEarn;
    }

    /// @notice update UserEarn info for an unlegacy (uncleared during swap) limit order.
    ///    and then add some amount of selling token
    ///    update strategy is 'first claim first earn', etc, earned token will be transformed for
    ///    limit orders which is update first
    /// @param self UserEarn storage object of target limit order
    /// @param currAccEarn 'accEarn' value of corresponding point order on swap pool.
    ///    accumulate amount of earned token 
    /// @param sqrtPrice_96 describe price of limit order
    /// @param totalEarn remained(undistributed) amount of earned token of unlegacy limit order on corresponding point
    /// @param isEarnY direction of corresponding limit order.
    function addUnlegacyOrder(
        UserEarn.Data storage self,
        uint128 delta,
        uint256 currAccEarn,
        uint160 sqrtPrice_96,
        uint128 totalEarn,
        bool isEarnY
    ) internal returns(uint128 totalEarnRemain, uint128 claimSold, uint128 claimEarn) {
        // first, call `updateUnlegacyOrder` to update unlegacy order
        (totalEarnRemain, claimSold, claimEarn) = updateUnlegacyOrder(self, currAccEarn, sqrtPrice_96, totalEarn, isEarnY);
        // then, add
        self.sellingRemain = self.sellingRemain + delta;
    }

    /// @notice update UserEarn info for an unlegacy (uncleared during swap) limit order.
    ///    and then decrease some amount of selling token (if remain)
    ///    update strategy is 'first claim first earn', etc, earned token will be transformed for
    ///    limit orders which is update first
    /// @param self UserEarn storage object of target limit order
    /// @param currAccEarn 'accEarn' value of corresponding point order on swap pool.
    ///    accumulate amount of earned token 
    /// @param sqrtPrice_96 describe price of limit order
    /// @param totalEarn remained(undistributed) amount of earned token of unlegacy limit order on corresponding point
    /// @param isEarnY direction of corresponding limit order.
    function decUnlegacyOrder(
        UserEarn.Data storage self,
        uint128 delta,
        uint256 currAccEarn,
        uint160 sqrtPrice_96,
        uint128 totalEarn,
        bool isEarnY
    ) internal returns(uint128 actualDelta, uint128 totalEarnRemain, uint128 claimSold, uint128 claimEarn) {
        // first, call `updateUnlegacyOrder` to update unlegacy order
        (totalEarnRemain, claimSold, claimEarn) = updateUnlegacyOrder(self, currAccEarn, sqrtPrice_96, totalEarn, isEarnY);
        // then decrease
        actualDelta = MaxMinMath.min(delta, self.sellingRemain);
        self.sellingRemain = self.sellingRemain - actualDelta;
        self.sellingDec = self.sellingDec + actualDelta;
    }

    /// @notice update UserEarn info for a legacy (cleared during swap) limit order.
    ///    an limit order we call it 'legacy' if it together with other limit order of same
    ///    direction and same point on the pool is cleared during one time of exchanging.
    ///    if an limit order is convinced to be 'legacy', we should mark it as 'sold out',
    ///    etc, transform all its remained selling token to earned token.
    /// @param self UserEarn storage object of target limit order
    /// @param addDelta addition of selling amount
    /// @param currAccEarn 'accEarn' value of corresponding point order on swap pool.
    ///    accumulate amount of earned token 
    /// @param sqrtPrice_96 describe price of limit order
    /// @param totalLegacyEarn remained(undistributed) amount of earned token of legacy limit order on corresponding point
    /// @param isEarnY direction of corresponding limit order.
    function updateLegacyOrder(
        UserEarn.Data storage self,
        uint128 addDelta,
        uint256 currAccEarn,
        uint160 sqrtPrice_96,
        uint128 totalLegacyEarn,
        bool isEarnY
    ) internal returns(uint128 totalLegacyEarnRemain, uint128 sold, uint128 claimedEarn) {
        sold = self.sellingRemain;
        uint256 earn = 0;
        if (sold > 0) {
            // transform all its remained selling token to earned token.
            if (isEarnY) {
                uint256 l = MulDivMath.mulDivFloor(sold, sqrtPrice_96, TwoPower.Pow96);
                // for earnY, earn = sold * price
                earn = MulDivMath.mulDivFloor(l, sqrtPrice_96, TwoPower.Pow96);
            } else {
                uint256 l = MulDivMath.mulDivFloor(sold, TwoPower.Pow96, sqrtPrice_96);
                // for earnX, earn = sold / price
                earn = MulDivMath.mulDivFloor(l, TwoPower.Pow96, sqrtPrice_96);
            }
            if (earn > totalLegacyEarn) {
                earn = totalLegacyEarn;
            }
            self.sellingRemain = 0;
            // count earned token into legacyEarn field, not earn field
            self.legacyEarn += uint128(earn);
        }
        claimedEarn = uint128(earn);
        self.lastAccEarn = currAccEarn;
        totalLegacyEarnRemain = totalLegacyEarn - claimedEarn;
        if (addDelta > 0) {
            // sellingRemain has been clear to 0
            self.sellingRemain = addDelta;
        }
    }

}