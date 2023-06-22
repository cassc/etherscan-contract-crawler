// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

library CastUint {
    /**
     * @dev Converts a `uint256` to `address`
     */
    function toAddress(uint256 value) internal pure returns (address) {
        bytes memory data = new bytes(32);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(data, 32), value)
        }
        return abi.decode(data, (address));
    }
}