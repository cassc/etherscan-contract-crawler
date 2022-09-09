// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CedarPaymentSplitterV0.sol";
import "../api/deploy/ICedarDeployer.sol";

contract CedarPaymentSplitterV0Factory is Ownable, ICedarDeployerEventsV3, ICedarImplementationVersionedV0 {
    CedarPaymentSplitterV0 public implementation;

    struct EventParams {
        address contractAddress;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
        address[] payees;
        uint256[] shares;
    }

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new CedarPaymentSplitterV0();
        address[] memory recipients = new address[](1); recipients[0] = msg.sender;
        uint[] memory shares = new uint[](1); shares[0] = 10000;

        implementation.initialize(recipients, shares);

        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit CedarImplementationDeployed(address(implementation), major, minor, patch, "CedarPaymentSplitter");
    }

    function emitEvent(
        EventParams memory params
    ) private {
        emit CedarPaymentSplitterDeployment(params.contractAddress, params.majorVersion, params.minorVersion, params.patchVersion, params.payees, params.shares);
    }

    function deploy(
        address[] memory payees, uint256[] memory shares_
    ) external onlyOwner returns (CedarPaymentSplitterV0 newClone) {
        // newClone = PaymentSplitter(Clones.clone(address((implementation)));
        newClone =  new CedarPaymentSplitterV0();
        newClone.initialize(payees, shares_);

        (uint major, uint minor, uint patch) = newClone.implementationVersion();

        EventParams memory params;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;
        params.payees = payees;
        params.shares = shares_;

        emitEvent(params);
    }

    function implementationVersion()
    external override
    view
    returns (
        uint256 major,
        uint256 minor,
        uint256 patch
    ) {
        return implementation.implementationVersion();
    }
}