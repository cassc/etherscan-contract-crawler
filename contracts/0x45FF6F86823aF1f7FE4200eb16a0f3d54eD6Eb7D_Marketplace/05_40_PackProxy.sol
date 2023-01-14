// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/proxy/Proxy.sol';

/// @title Pack Proxy Contract
/// @notice Proxy contract for PackNFT

contract PackProxy is Proxy {
    uint256[100000] private move;
    address public immutable implementation;

    /// @dev Sets the address of the new implementation
    /// @param _address implementation address

    constructor(address _address) {
        implementation = _address;
    }

    /// @dev Return current implementation

    function _implementation() internal view override returns (address) {
        return implementation;
    }
}