// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev FailSafeBeacon to support being able to change the
 * implementation of {FailSafeOrchestrator} & {FailSafeWallet}
 * without impacting the state of those contracts.
 */
contract FailSafeBeacon is Ownable {
    UpgradeableBeacon immutable beacon;

    address public blueprint;

    constructor(address _initBlueprint) {
        require(_initBlueprint != address(0), "invalid blueprint addr");
        beacon = new UpgradeableBeacon(_initBlueprint);
        blueprint = _initBlueprint;
        transferOwnership(tx.origin);
    }

    function update(address _newBlueprint) public onlyOwner {
        require(_newBlueprint != address(0), "invalid blueprint addr");
        beacon.upgradeTo(_newBlueprint);
        blueprint = _newBlueprint;
    }

    function implementation() public view returns (address) {
        return beacon.implementation();
    }
}