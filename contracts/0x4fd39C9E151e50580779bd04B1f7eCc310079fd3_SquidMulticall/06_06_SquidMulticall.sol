// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISquidMulticall} from "./interfaces/ISquidMulticall.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract SquidMulticall is ISquidMulticall, IERC721Receiver, IERC1155Receiver {
    bytes4 constant public ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 constant public ERC721_TOKENRECEIVER_INTERFACE_ID = 0x150b7a02;
    bytes4 constant public ERC1155_TOKENRECEIVER_INTERFACE_ID = 0x4e2312e0;

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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == ERC1155_TOKENRECEIVER_INTERFACE_ID ||
            interfaceId == ERC721_TOKENRECEIVER_INTERFACE_ID ||
            interfaceId == ERC165_INTERFACE_ID;
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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    // Required to enable ETH reception with .transfer or .send
    receive() external payable {}
}