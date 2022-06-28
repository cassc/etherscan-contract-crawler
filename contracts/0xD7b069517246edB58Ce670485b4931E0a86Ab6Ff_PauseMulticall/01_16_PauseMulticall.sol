// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {ACLTrait} from "../core/ACLTrait.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {ACL} from "../core/ACL.sol";
import {ContractsRegister} from "../core/ContractsRegister.sol";
import {CallerNotPausableAdminException} from "../interfaces/IErrors.sol";

contract PauseMulticall is ACLTrait {
    ACL public immutable acl;
    ContractsRegister public immutable cr;

    modifier pausableAdminOnly() {
        if (!acl.isPausableAdmin(msg.sender))
            revert CallerNotPausableAdminException(); // F:[PM-05]
        _;
    }

    constructor(address _addressProvider) ACLTrait(_addressProvider) {
        IAddressProvider ap = IAddressProvider(_addressProvider);
        acl = ACL(ap.getACL()); // F: [PM-01]

        cr = ContractsRegister(ap.getContractsRegister()); // F: [PM-01]
    }

    function pauseAllCreditManagers()
        external
        pausableAdminOnly // F:[PM-05]
    {
        // F: [PM-05]
        _pauseBatchOfContractrs(cr.getCreditManagers()); // F: [PM-02]
    }

    function pauseAllPools()
        external
        pausableAdminOnly // F:[PM-05]
    {
        _pauseBatchOfContractrs(cr.getPools()); // F: [PM-03]
    }

    function pauseAllContracts()
        external
        pausableAdminOnly // F:[PM-05]
    {
        _pauseBatchOfContractrs(cr.getPools()); // F: [PM-04]
        _pauseBatchOfContractrs(cr.getCreditManagers()); // F: [PM-04]
    }

    function _pauseBatchOfContractrs(address[] memory contractsToPause)
        internal
    {
        uint256 len = contractsToPause.length;
        for (uint256 i = 0; i < len; ) {
            ACLTrait(contractsToPause[i]).pause();
            unchecked {
                i++;
            }
        }
    }
}