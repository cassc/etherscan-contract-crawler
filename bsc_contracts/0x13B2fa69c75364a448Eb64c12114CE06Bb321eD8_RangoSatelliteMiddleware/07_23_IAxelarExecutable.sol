// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IAxelarGateway } from './IAxelarGateway.sol';

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}

}