// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {TokenData} from "../lib/CoreStructs.sol";

interface IExecutor {
    error OnlyCoreAuth();

    event CoreUpdated(address newCore);

    /**
     * @dev executes call from dispatcher, creating additional checks on arbitrary calldata
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param data The token swap data and post bridge execution payload.
     */
    function execute(address target, address paymentOperator, TokenData memory data)
        external
        payable
        returns (bool success);

    /**
     * @dev sets core address
     * @param core core implementation address
     */
    function setCore(address core) external;
}