// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Multicall {
    function multicall(bytes[] calldata data) external payable virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                results[i] = _functionDelegateCall(data[i]);
            }
        }

        return results;
    }

    function _functionDelegateCall(bytes memory data) private returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(this).delegatecall(data);
        // M_LDCF: low-level delegate call failed
        return Address.verifyCallResult(success, returndata, "M_LDCF");
    }
}