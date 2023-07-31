// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {IEscrow} from "./IEscrow.sol";

interface IEscrowedLine {
    event Liquidate(bytes32 indexed id, uint256 indexed amount, address indexed token, address escrow);

    /**
     * @notice - Forcefully take collateral from Escrow and repay debt for lender
     *          - current implementation just sends "liquidated" tokens to Arbiter to sell off how the deem fit and then manually repay with DepositAndRepay
     * @dev - only callable by Arbiter
     * @dev - Line status MUST be LIQUIDATABLE
     * @dev - callable by `arbiter`
     * @param amount - amount of `targetToken` expected to be sold off in  _liquidate
     * @param targetToken - token in escrow that will be sold of to repay position
     */
    function liquidate(uint256 amount, address targetToken) external returns (uint256);

    /// @notice the escrow contract backing this Line
    function escrow() external returns (IEscrow);
}