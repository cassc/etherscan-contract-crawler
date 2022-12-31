// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "../types/types.sol";

interface IEventLogger {
    function log(EventData calldata data) external;
}