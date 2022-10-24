// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./proxies/NonRewardPoolProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Manages deployment of non reward pool Proxies
 * Deploys proxies pointing to non reward pool implementation
 */
contract NonRewardPoolDeployer is Ownable {
    address public nonRewardPoolImplementation;

    constructor(address _nonRewardPoolImplementation) {
        nonRewardPoolImplementation = _nonRewardPoolImplementation;
        emit NonRewardPoolImplementationSet(_nonRewardPoolImplementation);
    }

    function deployNonRewardPool(address _proxyAdmin)
        external
        returns (address pool)
    {
        NonRewardPoolProxy poolInstance = new NonRewardPoolProxy(
            nonRewardPoolImplementation,
            _proxyAdmin,
            address(this)
        );
        return address(poolInstance);
    }

    function setNonRewardPoolImplementation(address _poolImplementation)
        external
        onlyOwner
    {
        nonRewardPoolImplementation = _poolImplementation;
        emit NonRewardPoolImplementationSet(_poolImplementation);
    }

    // Events
    event NonRewardPoolImplementationSet(address indexed poolImplementation);
}