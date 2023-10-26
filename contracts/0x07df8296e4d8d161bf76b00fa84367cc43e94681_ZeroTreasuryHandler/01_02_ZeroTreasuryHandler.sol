// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ITreasuryHandler.sol";

contract ZeroTreasuryHandler is ITreasuryHandler {
    /**
     * @notice Perform operations before a transfer is executed.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function beforeTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external {}

    /**
     * @notice Perform operations after a transfer is executed.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function afterTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external {}
}