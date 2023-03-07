// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library NativeClaimer {
    struct State {
        uint256 _valueClaimed;
    }

    function claimed(NativeClaimer.State memory claimer_) internal pure returns (uint256) {
        return claimer_._valueClaimed;
    }

    function unclaimed(NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return msg.value - claimer_._valueClaimed;
    }

    function claim(NativeClaimer.State memory claimer_, uint256 value_) internal view {
        require(unclaimed(claimer_) >= value_, "NC: insufficient msg value");
        claimer_._valueClaimed += value_;
    }
}