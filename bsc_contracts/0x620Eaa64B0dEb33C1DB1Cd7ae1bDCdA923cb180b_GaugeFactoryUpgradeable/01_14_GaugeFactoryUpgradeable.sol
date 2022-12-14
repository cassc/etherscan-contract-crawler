// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/interfaces/IGaugeFactory.sol';
import 'contracts/Gauge.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GaugeFactoryUpgradeable is IGaugeFactory, OwnableUpgradeable {
    
    address public last_gauge;
    constructor() {}
    function initialize() initializer  public {
        __Ownable_init();
    }

    function createGauge(address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        last_gauge = address(new Gauge(_pool, _internal_bribe, _external_bribe, _ve, msg.sender, isPair, allowedRewards));
        return last_gauge;
    }
}