// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './interfaces/IGaugeFactoryV2.sol';
import './GaugeV2.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IGauge{
    function setDistribution(address _distro) external;

}
contract GaugeFactoryV2 is IGaugeFactory, OwnableUpgradeable {
    address public last_gauge;

    constructor() {}

    function initialize() initializer public {
        __Ownable_init();
    }

    function createGaugeV2(address _rewardToken, address _ve, address _token, address _distribution, address _internal_bribe, address _external_bribe, address _fees_collector, bool _isPair) external returns (address) {
        last_gauge = address(new GaugeV2(_rewardToken,_ve,_token,_distribution,_internal_bribe,_external_bribe,_fees_collector,_isPair) );
        return last_gauge;
    }

    function setDistribution(address _gauge, address _newDistribution) external onlyOwner {
        IGauge(_gauge).setDistribution(_newDistribution);
    }

}