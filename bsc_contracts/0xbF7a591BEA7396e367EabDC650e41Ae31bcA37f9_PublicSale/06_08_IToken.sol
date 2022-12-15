// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IToken {
    function getITransferInvestment(
        address account
    ) external view returns (uint256);

    function getITransferAirdrop(
        address account
    ) external view returns (uint256);
}