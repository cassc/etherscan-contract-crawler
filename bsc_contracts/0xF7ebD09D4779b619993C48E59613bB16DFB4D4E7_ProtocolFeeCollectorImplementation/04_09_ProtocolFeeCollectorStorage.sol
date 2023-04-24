// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/Admin.sol";

abstract contract ProtocolFeeCollectorStorage is Admin {
    // admin will be truned in to Timelock after deployment

    address public implementation;
}