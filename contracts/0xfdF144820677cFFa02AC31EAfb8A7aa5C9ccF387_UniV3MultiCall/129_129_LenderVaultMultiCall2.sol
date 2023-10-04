// SPDX-License-Identifier: GPL-3.0
// @dev: this contract is a helper contract and should only be used for backend jobs

pragma solidity 0.8.19;

import {ILenderVaultImpl} from "../peer-to-peer/interfaces/ILenderVaultImpl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract LenderVaultMultiCall2 {

    struct AdminInfo {
        address[] signers;
        address onChainQuotingDelegate;
        address circuitBreaker;
        address reverseCircuitBreaker;
        bool isPaused;
    }

    function getAdminInfo(address[] calldata vaults) external view returns (AdminInfo[] memory adminInfos) {
        adminInfos = new AdminInfo[](vaults.length);
        for (uint256 i = 0; i < vaults.length; ) {
            adminInfos[i] = _getAdminInfo(vaults[i]);
            unchecked {
                ++i;
            }
            if (gasleft() < 1_000_000) {
                break;
            }
        }
    }

    function _getAdminInfo(address vault) internal view returns (AdminInfo memory adminInfo) {
        try ILenderVaultImpl(vault).totalNumSigners() returns (uint256 numSigners) {
            address onChainQuotingDelegate = ILenderVaultImpl(vault).onChainQuotingDelegate();
            address circuitBreaker = ILenderVaultImpl(vault).circuitBreaker();
            address reverseCircuitBreaker = ILenderVaultImpl(vault).reverseCircuitBreaker();
            bool isPaused = Pausable(vault).paused();
            address[] memory signers = new address[](numSigners);
            for (uint256 j = 0; j < numSigners; ) {
                signers[j] = ILenderVaultImpl(vault).signers(j);
                unchecked {
                    ++j;
                }
            }
            adminInfo = AdminInfo(signers, onChainQuotingDelegate, circuitBreaker, reverseCircuitBreaker, isPaused);
        // solhint-disable no-empty-blocks
        } catch {
        }        
    }
}