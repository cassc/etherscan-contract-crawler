// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/// @title ContractSafe
/// @author Metacrypt (https://www.metacrypt.org/)
abstract contract ContractSafe {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function isSentViaEOA() internal view returns (bool) {
        // Use with caution, tx.origin may become unreliable in the future.
        // https://ethereum.stackexchange.com/a/200
        return msg.sender == tx.origin;
    }
}