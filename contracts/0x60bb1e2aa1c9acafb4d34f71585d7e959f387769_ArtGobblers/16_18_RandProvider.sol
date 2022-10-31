// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Randomness Provider Interface.
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Generic asynchronous randomness provider interface.
interface RandProvider {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RandomBytesRequested(bytes32 requestId);
    event RandomBytesReturned(bytes32 requestId, uint256 randomness);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Request random bytes from the randomness provider.
    function requestRandomBytes() external returns (bytes32 requestId);
}