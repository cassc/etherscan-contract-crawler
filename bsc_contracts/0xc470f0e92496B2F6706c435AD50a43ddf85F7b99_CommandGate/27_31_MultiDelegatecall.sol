// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract MultiDelegatecall {
    address public immutable original;

    constructor() payable {
        original = address(this);
    }

    function _multiDelegatecall(
        bytes[] calldata data_
    ) internal returns (bytes[] memory results) {
        require(address(this) == original, "MULTICALL: ONLY_DELEGATE");
        uint256 length = data_.length;
        results = new bytes[](length);
        bool ok;
        for (uint256 i; i < length; ) {
            (ok, results[i]) = address(this).delegatecall(data_[i]);
            require(ok, "MULTICALL: EXECUTION_FAILED");
            unchecked {
                ++i;
            }
        }
    }
}