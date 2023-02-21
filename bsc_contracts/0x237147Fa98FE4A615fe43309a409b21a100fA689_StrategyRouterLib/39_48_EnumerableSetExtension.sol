pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableSetExtension {
    /// @dev Function will revert if address is not in set.
    function indexOf(EnumerableSet.AddressSet storage set, address value) internal view returns (uint256 index) {
        return set._inner._indexes[bytes32(uint256(uint160(value)))] - 1;
    }
}