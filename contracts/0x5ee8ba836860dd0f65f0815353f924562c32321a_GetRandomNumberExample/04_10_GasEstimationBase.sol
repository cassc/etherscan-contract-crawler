// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// solhint-disable-next-line no-global-import
import "./StringAndUintConverter.sol" as StringAndUintConverter;

contract GasEstimationBase {
    /**
     * @notice Estimates gas used by actually calling that function then reverting with the gas used as string
     * @param to Destination address
     * @param value Ether value
     * @param data Data payload
     */
    function requiredTxGas(address to, uint256 value, bytes calldata data) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        // solhint-disable-next-line reason-string
        require(_executeCall(to, value, data, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        string memory s = StringAndUintConverter.uintToString(requiredGas);
        // Convert response to string and return via error message
        revert(s);
    }

    function _executeCall(address to, uint256 value, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /**
     * @notice Parses the gas used from the revert msg
     * @param _returnData the return data of requiredTxGas
     */
    function _parseGasUsed(bytes memory _returnData) internal pure returns (uint256) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 0; //"Transaction reverted silently";

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return StringAndUintConverter.stringToUint(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}