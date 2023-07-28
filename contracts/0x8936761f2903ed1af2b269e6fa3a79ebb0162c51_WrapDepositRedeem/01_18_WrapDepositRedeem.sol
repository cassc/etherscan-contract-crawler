// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWrap } from "./interfaces/IWrap.sol";
import { IWrapDepositRedeem } from "./interfaces/IWrapDepositRedeem.sol";
import { Multisig } from "./libraries/Multisig.sol";
import { Wrap } from "./Wrap.sol";

contract WrapDepositRedeem is IWrapDepositRedeem, Wrap {
    using Multisig for Multisig.DualMultisig;

    using SafeERC20 for IERC20;

    constructor(
        Multisig.Config memory config,
        uint16 _validatorFeeBPS
    ) Wrap(config, _validatorFeeBPS) {}

    /// @dev Internal function to calculate the deposit fees.
    function depositFees(uint256) internal pure returns (uint256 fee) {
        return 0;
    }

    /// @inheritdoc Wrap
    function onDeposit(
        address token,
        uint256 amount
    ) internal virtual override returns (uint256) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return depositFees(amount);
    }

    /// @inheritdoc Wrap
    function onExecute(
        address token,
        uint256 amount,
        address to
    )
        internal
        virtual
        override
        returns (uint256 totalFee, uint256 validatorFee)
    {
        totalFee = validatorFee = calculateFee(amount, validatorFeeBPS);
        IERC20(token).safeTransfer(to, amount - totalFee);
    }

    /// @inheritdoc Wrap
    function onMigrate(address _newContract) internal override {
        // Transfer all the token reserves to the new contract.
        // Notice that this will also transfer all the validator fees.
        // Therefore, either the new bridge should respect the existing validator fees or
        // all the validator fees must be claimed before the migration.
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(_newContract, tokenBalance);
        }
    }

    /// @inheritdoc IWrapDepositRedeem
    function addToken(
        address token,
        address mirrorToken,
        TokenInfo calldata tokenInfo
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addToken(token, mirrorToken, tokenInfo);
    }
}