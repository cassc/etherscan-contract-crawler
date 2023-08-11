// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title MultiCall Contract
 * @author Opty.fi
 * @dev Provides functions used commonly for decoding codes and execute
 * the code calls for Opty.fi contracts
 */
abstract contract MultiCall {
    /**
     * @notice Executes any functionlaity and check if it is working or not
     * @dev Execute the code and revert with error message if code provided is incorrect
     * @param _code Encoded data in bytes which acts as code to execute
     * @param _errorMsg Error message to throw when code execution call fails
     */
    function executeCode(bytes memory _code, string memory _errorMsg) internal {
        (address _contract, bytes memory _data) = abi.decode(_code, (address, bytes));
        (bool _success, bytes memory _returnData) = _contract.call(_data); //solhint-disable-line avoid-low-level-calls
        require(_success, string(_returnData));
    }

    /**
     * @notice Executes bunch of functionlaities and check if they are working or not
     * @dev Execute the codes array and revert with error message if code provided is incorrect
     * @param _codes Array of encoded data in bytes which acts as code to execute
     * @param _errorMsg Error message to throw when code execution call fails
     */
    function executeCodes(bytes[] memory _codes, string memory _errorMsg) internal {
        for (uint256 _j = 0; _j < _codes.length; _j++) {
            executeCode(_codes[_j], _errorMsg);
        }
    }
}