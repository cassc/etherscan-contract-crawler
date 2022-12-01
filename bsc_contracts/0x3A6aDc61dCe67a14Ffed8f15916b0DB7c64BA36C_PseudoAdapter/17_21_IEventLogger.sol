// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "../types/types.sol";

interface IEventLogger {
    function log(EventData calldata data) external;
}