// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

import { EnumerableSetUpgradeable } from "openzeppelin/utils/structs/EnumerableSetUpgradeable.sol";

library ResolverStateHelper {
    /**
     * @notice Struct used to define the state variables for the resolver. This is used to ease the 
     * upgradeability process and help prevent against storage conflicts.
     * @param gatewayUrl Gateway URL to use to perform offchain lookup.
     * @param offChainDatabaseUrl Off-Chain Database Write Deferral Resolver URL to handle deferred mutations at.
     * @param offChainDatabaseTimeoutDuration Off-Chain Database Write Deferral Resolver Timeout Duration in seconds for deferred mutations.
     * @param signers Addresses for the set of signers.
     */
    struct ResolverState {
        string  gatewayUrl;
        string  offChainDatabaseUrl;
        uint256 offChainDatabaseTimeoutDuration;

        EnumerableSetUpgradeable.AddressSet signers;
    }

    /**
     * @dev Returns a `ResolverState` with member variables located at `slot`.
     */
    function getResolverState(bytes32 slot) internal pure returns (ResolverState storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}