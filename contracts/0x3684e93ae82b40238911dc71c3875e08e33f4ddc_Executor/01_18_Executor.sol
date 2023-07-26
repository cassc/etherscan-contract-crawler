// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Callbacks} from "../utils/Callbacks.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {TokenData} from "../lib/CoreStructs.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract Executor is IExecutor, Ownable, Callbacks {
    address public coreAddress;

    /**
     * @dev executes call from dispatcher, creating additional checks on arbitrary calldata
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param data The token swap data and post bridge execution payload.
     */
    function execute(address target, address paymentOperator, TokenData memory data)
        external
        payable
        returns (bool success)
    {
        if (msg.sender != coreAddress) {
            revert OnlyCoreAuth();
        }

        if (data.tokenOut != address(0)) {
            SafeERC20.safeTransferFrom(IERC20(data.tokenOut), coreAddress, address(this), data.amountOut);
            SafeERC20.safeIncreaseAllowance(IERC20(data.tokenOut), paymentOperator, data.amountOut);
            (success,) = target.call(data.payload);
        } else {
            (success,) = target.call{value: data.amountOut}(data.payload);
        }

        // send back to core if failed
        if (!success) {
            if (data.tokenOut == address(0)) {
                payable(coreAddress).call{value: data.amountOut}("");
            } else {
                SafeERC20.safeTransfer(IERC20(data.tokenOut), coreAddress, data.amountOut);
            }
        }
    }

    /**
     * @dev sets core address
     * @param core core implementation address
     */
    function setCore(address core) external onlyOwner {
        coreAddress = core;
        emit CoreUpdated(core);
    }
}