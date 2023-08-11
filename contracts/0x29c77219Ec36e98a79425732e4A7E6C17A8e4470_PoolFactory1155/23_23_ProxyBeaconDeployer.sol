// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title ProxyBeaconDeployer
 * @author Souq.Finance
 * @notice The proxy beacon deployer inherited by the pool factory
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
contract ProxyBeaconDeployer {
    bool private _isSetBeacon;
    UpgradeableBeacon private beacon;

    event BeaconDeployed(address _beacon);

    /**
     * @dev Returns the beacon address
     * @return address The address of the beacon
     */
    function getBeaconAddress() external view returns (address) {
        return address(beacon);
    }

    /**
     * @dev Creates a new beacon pointing to the logic address
     * @param logic The logic address
     */
    function _createBeacon(address logic) internal {
        if (!_isSetBeacon) {
            beacon = new UpgradeableBeacon(logic);
            _isSetBeacon = true;
            emit BeaconDeployed(address(beacon));
        }
    }

    /**
     * @dev Upgrades the beacon to use the new logic address
     * @param newLogic The new logic address
     */
    function upgradeBeacon(address newLogic) internal {
        beacon.upgradeTo(newLogic);
    }

    /**
     * @dev Deploys a new proxy, returns the proxy address and creates a beacon from the logic if not created before
     * @param logic The logic address
     * @param payload The payload data
     * @return address The proxy address
     */
    function deployBeaconProxy(address logic, bytes memory payload) internal returns (address) {
        if (!_isSetBeacon) {
            _createBeacon(logic);
        }
        address payable addr;
        bytes memory _bytecode = type(BeaconProxy).creationCode;
        bytes memory _code = abi.encodePacked(_bytecode, abi.encode(address(beacon), payload));
        assembly {
            addr := create(0, add(_code, 0x20), mload(_code))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        BeaconProxy proxy = BeaconProxy(addr);
        //_beaconProxies[address (proxy)] = true;
        return address(proxy);
    }
}