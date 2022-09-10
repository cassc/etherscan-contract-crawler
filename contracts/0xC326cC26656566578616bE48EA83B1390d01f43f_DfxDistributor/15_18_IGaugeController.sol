// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IGaugeController {
    function admin() external view returns (address);

    function gauge_types(address addr) external view returns (int128);

    function gauge_relative_weight_write(address addr, uint256 timestamp) external returns (uint256);

    function gauge_relative_weight(address addr, uint256 timestamp) external view returns (uint256);

    function add_gauge(address addr, int128 gauge_type) external;

    function add_gauge(address addr, int128 gauge_type, uint256 weight) external;

    function commit_transfer_ownership(address account) external;

    function accept_transfer_ownership() external;    
}