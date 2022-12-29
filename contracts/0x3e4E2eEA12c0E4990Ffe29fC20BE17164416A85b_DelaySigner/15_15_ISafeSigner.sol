// SPDX-License-Identifier: MIT
// @author st4rgard3n, Collab.Land, Raid Guild
pragma solidity >=0.8.0;

interface ISafeSigner {

    /// @dev Access owner state of Gnosis Safe
    /// @param owner is valid signer address on Safe
    function isOwner(address owner) external view returns (bool);

}