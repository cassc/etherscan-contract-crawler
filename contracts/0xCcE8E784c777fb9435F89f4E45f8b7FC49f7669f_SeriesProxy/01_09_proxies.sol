// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovernedUpgradeabilityProxy} from '../governance/GovernedUpgradeabilityProxy.sol';

/**
 * @notice FeeVaultProxy
 */
contract FeeVaultProxy is GovernedUpgradeabilityProxy {
    constructor(address logic_, address controller_)
        GovernedUpgradeabilityProxy(
            logic_,
            abi.encodeWithSignature('initialize(address)', controller_)
        )
    {}
}

/**
 * @notice SeriesProxy
 */
contract SeriesProxy is GovernedUpgradeabilityProxy {
    constructor(
        address _logic,
        address _ogn,
        address _vault
    )
        GovernedUpgradeabilityProxy(
            _logic,
            abi.encodeWithSignature('initialize(address,address)', _ogn, _vault)
        )
    {}
}