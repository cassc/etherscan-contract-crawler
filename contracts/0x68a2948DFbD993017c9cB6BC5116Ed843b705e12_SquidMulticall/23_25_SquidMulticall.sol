// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISquidMulticall} from "./interfaces/ISquidMulticall.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SquidMulticall is ISquidMulticall {
    bool private isRunning;

    error TransferFailed();

    function run(Call[] calldata calls) external payable {
        // Prevents reentrancy
        if (isRunning) revert AlreadyRunning();
        isRunning = true;

        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];

            if (call.callType == CallType.FullTokenBalance) {
                (address token, uint256 amountParameterPosition) = abi.decode(call.payload, (address, uint256));
                uint256 amount = IERC20(token).balanceOf(address(this));
                _setCallDataParameter(call.callData, amountParameterPosition, amount);
            } else if (call.callType == CallType.FullNativeBalance) {
                call.value = address(this).balance;
            } else if (call.callType == CallType.CollectTokenBalance) {
                address token = abi.decode(call.payload, (address));
                _safeTransferFrom(token, msg.sender, IERC20(token).balanceOf(msg.sender));
                continue;
            }

            (bool success, bytes memory data) = call.target.call{value: call.value}(call.callData);
            if (!success) revert CallFailed(i, data);
        }

        isRunning = false;
    }

    function _safeTransferFrom(address token, address from, uint256 amount) private {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _setCallDataParameter(bytes memory callData, uint256 parameterPosition, uint256 value) private pure {
        assembly {
            // 36 bytes shift because 32 for prefix + 4 for selector
            mstore(add(callData, add(36, mul(parameterPosition, 32))), value)
        }
    }

    // Required to enable ETH reception with .transfer or .send
    receive() external payable {}
}