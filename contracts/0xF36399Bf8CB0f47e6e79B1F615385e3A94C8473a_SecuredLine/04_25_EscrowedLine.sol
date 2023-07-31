// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/test-org2222/Line-Of-Credit/blog/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {IEscrow} from "../../interfaces/IEscrow.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {IEscrowedLine} from "../../interfaces/IEscrowedLine.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";

// used for importing NATSPEC docs, not used
import {LineOfCredit} from "./LineOfCredit.sol";

// import { SecuredLine } from "./SecuredLine.sol";

abstract contract EscrowedLine is IEscrowedLine, ILineOfCredit {
    // contract holding all collateral for borrower
    IEscrow public immutable escrow;

    constructor(address _escrow) {
        escrow = IEscrow(_escrow);
    }

    /**
     * see LineOfCredit._init and SecuredLine.init
     * @notice requires this Line is owner of the Escrowed collateral else Line will not init
     */
    function _init() internal virtual {
        if (escrow.line() != address(this)) revert BadModule(address(escrow));
    }

    /**
     * see LineOfCredit._healthcheck and SecuredLine._healthcheck
     * @notice returns LIQUIDATABLE if Escrow contract is undercollateralized, else returns ACTIVE
     */
    function _healthcheck() internal virtual returns (LineLib.STATUS) {
        if (escrow.isLiquidatable()) {
            return LineLib.STATUS.LIQUIDATABLE;
        }

        return LineLib.STATUS.ACTIVE;
    }

    /**
     * see SecuredlLine.liquidate
     * @notice sends escrowed tokens to liquidation.
     * @dev priviliegad function. Do checks before calling.
     *
     * @param id - The credit line being repaid via the liquidation
     * @param amount - amount of tokens to take from escrow and liquidate
     * @param targetToken - the token to take from escrow
     * @param to - the liquidator to send tokens to. could be OTC address or smart contract
     *
     * @return amount - the total amount of `targetToken` sold to repay credit
     */
    function _liquidate(
        bytes32 id,
        uint256 amount,
        address targetToken,
        address to
    ) internal virtual returns (uint256) {
        IEscrow escrow_ = escrow; // gas savings
        require(escrow_.liquidate(amount, targetToken, to));

        emit Liquidate(id, amount, targetToken, address(escrow_));

        return amount;
    }

    /**
     * see SecuredLine.declareInsolvent
     * @notice require all collateral sold off before declaring insolvent
     *(@dev priviliegad internal function.
     * @return isInsolvent - if Escrow contract is currently insolvent or not
     */
    function _canDeclareInsolvent() internal virtual returns (bool) {
        if (escrow.getCollateralValue() != 0) {
            revert NotInsolvent(address(escrow));
        }
        return true;
    }

    /**
     * see SecuredlLine.rollover
     * @notice helper function to allow borrower to easily swithc collateral to a new Line after repyment
     *(@dev priviliegad internal function.
     * @dev MUST only be callable if line is REPAID
     * @return - if function successfully executed
     */
    function _rollover(address newLine) internal virtual returns (bool) {
        require(escrow.updateLine(newLine));
        return true;
    }
}