// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IGaugeController {
    function vote_for_gauge_weights(address gauge, uint weight) external;

    function gauge_types(address gauge) external view returns (int128);
}