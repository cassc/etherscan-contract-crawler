// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../utils/Interfaces.sol";

/// @title ProxyFactory contract
contract ProxyFactory is IProxyFactory {
    /// @notice Creates a new contract based on the target contract address provided
    /// @param target contract address to be cloned
    /// @return result address of the new contract
    function clone(address target) external returns (address result) {
        bytes20 targetBytes = bytes20(target);
        // solhint-disable-next-line
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}