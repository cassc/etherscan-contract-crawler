// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Gauge.sol';

contract BaseV1GaugeFactory {
    address public last_gauge;

    // @param _stake address of the LP tokens
    // @param _bribe address of the bribe contract linked to the Gauge
    // @param _ve address of the VotingEscrow contract
    // @return the gauge address
    function createGauge(address _stake, address _bribe, address _ve) external returns (address) {
        last_gauge = address(new Gauge(_stake, _bribe, _ve, msg.sender));
        return last_gauge;
    }
}