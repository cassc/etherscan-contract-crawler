/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.18;

contract Utils {
    uint24 private constant _SECS_IN_FOUR_WEEKS = 2419200; // 3600 * 24 * 7 * 4

    function _callAndParseAddressReturn(address token, bytes4 selector)
        internal
        view
        returns (address)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return address(0);
        }

        // if implemented, or returns data, return decoded int24 else return 0
        if (data.length == 32) {
            return abi.decode(data, (address));
        }

        return address(0);
    }

    function _callAndParseUint24Return(address token, bytes4 selector)
        internal
        view
        returns (uint24)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return 0;
        }

        // if implemented, or returns data, return decoded int24 else return 0
        if (data.length == 32) {
            return abi.decode(data, (uint24));
        }

        return 0;
    }

    function _getFee(address target) internal view returns (uint24 targetFee) {
        targetFee = _callAndParseUint24Return(
            target,
            hex"ddca3f43" // fee()
        );

        return targetFee;
    }

    function _getToken0(address target)
        internal
        view
        returns (address targetToken0)
    {
        targetToken0 = _callAndParseAddressReturn(
            target,
            hex"0dfe1681" // token0()
        );

        return targetToken0;
    }

    function _getToken1(address target)
        internal
        view
        returns (address targetToken1)
    {
        targetToken1 = _callAndParseAddressReturn(
            target,
            hex"d21220a7" // token1()
        );

        return targetToken1;
    }

    /**
     * @notice Calculates penalty basis points for given from and to timestamps in seconds since epoch
     */
    function _penaltyFor(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 penaltyBasis)
    {
        // penaltyBasis = 0;
        if (fromTimestamp + 52 weeks > toTimestamp) {
            uint256 fourWeeksElapsed = (toTimestamp - fromTimestamp) /
                _SECS_IN_FOUR_WEEKS;
            if (fourWeeksElapsed < 13) {
                penaltyBasis = ((13 - fourWeeksElapsed) * 100); // If one four weeks have elapsed - penalty is 12% or 1200/10000
            }
        }
        return penaltyBasis;
    }
}