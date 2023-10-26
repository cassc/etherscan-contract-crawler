// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./FailSafeBeacon.sol";
import "./FailSafeOrchestrator.sol";

/**
 * @dev FailSafeOrchestratorFactory used to spin up 
 * upgradable FailSafeOrchestrator.
 * 
 */
contract FailSafeOrchestratorFactory is Ownable {
    mapping(string => address) private orchestrators;
    FailSafeBeacon immutable beacon;
    address public failSafeWalletBlueprint;

    constructor(address _orchestratorBlueprint, address _failSafeWalletBlueprint) {
        require(_orchestratorBlueprint != address(0), "invalid orch blueprint addr");
        require(_failSafeWalletBlueprint != address(0), "invalid wallet blueprint addr");

        beacon = new FailSafeBeacon(_orchestratorBlueprint);
        failSafeWalletBlueprint = _failSafeWalletBlueprint;
    }

    function updateFailSafeWalletBlueprintAddress(address addr) external onlyOwner {
        require(addr != address(0), "invalid addr!");
        failSafeWalletBlueprint = addr;
    }

    address payable _zero_addr = payable(address(0));

    function buildFailSafeOrchestrator(string memory orchestratorId) public onlyOwner {
        require(orchestrators[orchestratorId] == address(0), "Id already taken");
        BeaconProxy _proxyContract = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                FailSafeOrchestrator(_zero_addr).initialize.selector,
                failSafeWalletBlueprint
            )
        );
        orchestrators[orchestratorId] = address(_proxyContract);
    }

    function getOrchestratorAddress(string memory orchestratorId) external view returns (address) {
        return orchestrators[orchestratorId];
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }
}