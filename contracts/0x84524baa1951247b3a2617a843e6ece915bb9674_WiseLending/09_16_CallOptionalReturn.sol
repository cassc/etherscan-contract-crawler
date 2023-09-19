// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "../InterfaceHub/IERC20.sol";

error CallFailed();

contract CallOptionalReturn {

    /**
     * @dev
     * Helper function to do low-level call
     */
    function _callOptionalReturn(
        address token,
        bytes memory data
    )
        internal
        returns (bool call)
    {
        (
            bool success,
            bytes memory returndata
        ) = token.call(
            data
        );

        bool results = returndata.length == 0 || abi.decode(
            returndata,
            (bool)
        );

        call = success
            && results
            && token.code.length > 0;

        if (call == false) {
            revert CallFailed();
        }
    }
}