// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }

    function safeTransferBatch(address token, address[] memory receivers, uint256[] memory amounts) internal {
        for (uint i = 0; i < receivers.length; i++) {
            uint amount = amounts[i];
            if (amount > 0) {
                safeTransfer(token, receivers[i], amount);
            }
        }
    }

    function safeTransferFromBatch(address token, address from, address[] memory receivers, uint256[] memory amounts) internal {
        for (uint i = 0; i < receivers.length; i++) {
            uint amount = amounts[i];
            if (amount > 0) {
                safeTransferFrom(token, from, receivers[i], amount);
            }
        }
    }

    function safeTransferETHBatch(address[] memory receivers, uint256[] memory amounts) internal {
        for (uint i = 0; i < receivers.length; i++) {
            uint amount = amounts[i];
            if (amount > 0) {
                safeTransferETH(receivers[i], amount);
            }
        }
    }
}