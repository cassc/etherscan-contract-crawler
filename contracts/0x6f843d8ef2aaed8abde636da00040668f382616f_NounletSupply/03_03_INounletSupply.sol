// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NounletSupply target contract
interface INounletSupply {
    function batchBurn(address _from, uint256[] memory _ids) external;

    function mint(address _to, uint256 _id) external;
}