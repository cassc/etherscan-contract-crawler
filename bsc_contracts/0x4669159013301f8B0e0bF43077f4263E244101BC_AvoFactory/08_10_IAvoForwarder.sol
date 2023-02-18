// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoForwarder {
    /// @notice AvoFactory (proxy) address
    /// @return contract address
    function avoFactory() external view returns (address);
}