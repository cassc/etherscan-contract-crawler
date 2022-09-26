// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Owner proxy to run atomic actions.
/// @notice DSProxy-like contract without a cache to simply run
///         a sequence of atomic actions.
contract OwnerProxy is Ownable {
    /// @notice Execute atomic actions. Only the owner can call this function (e.g. the timelock)
    /// @param _target Address of the "script" to perform a delegatecall
    /// @param _data The bytes calldata
    /// @return response The delegatecall response
    /// @dev Fork from https://github.com/dapphub/ds-proxy/blob/e17a2526ad5c9877ba925ff25c1119f519b7369b/src/proxy.sol#L53
    /// @dev bytes4 selector must be included in the calldata (_data)
    function execute(address _target, bytes memory _data) public payable onlyOwner returns (bytes memory response) {
        require(_target != address(0), "OP: INVALID_TARGET");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }
}