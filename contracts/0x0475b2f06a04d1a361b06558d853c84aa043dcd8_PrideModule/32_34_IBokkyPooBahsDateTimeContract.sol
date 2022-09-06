// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IBokkyPooBahsDateTimeContract {
    function timestampToDateTime(uint256 timestamp)
        external
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        );
}