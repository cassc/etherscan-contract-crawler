// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

library Contracts {
    function deploy(bytes memory bytecode)
        internal
        returns (address implementation)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation := create(0, add(bytecode, 32), mload(bytecode))
        }
        require(isContract(implementation), "Could not deploy implementation");
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}