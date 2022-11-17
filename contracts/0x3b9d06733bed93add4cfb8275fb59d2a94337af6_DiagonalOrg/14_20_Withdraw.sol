// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { IWithdraw } from "../../../interfaces/core/organization/modules/IWithdraw.sol";
import { Base } from "./Base.sol";

import { ERC20 } from "openzeppelin-contracts/token/ERC20/ERC20.sol";

abstract contract Withdraw is Base, IWithdraw {
    /*******************************
     * Errors *
     *******************************/
    error InvalidReceiverAddress();
    error InvalidTokenAddress();
    error InvalidAmount();

    /*******************************
     * Events *
     *******************************/

    event WithdrawSuccessful(address indexed receiver, address indexed token, uint256 amount);

    /*******************************
     * Constants *
     *******************************/

    /**
     * @notice Token fee recipient
     */
    address public constant TOKEN_FEE_RECIPIENT = 0x11a938315d40408a8C802dd62d207bB8a10F7c64;

    /*******************************
     * State vars *
     *******************************/

    /**
     * @notice Gap array, for further state variable changes
     */
    uint256[50] private __gap;

    /*******************************
     * Functions start *
     *******************************/

    function withdraw(
        address receiver,
        address token,
        uint256 amount,
        uint256 fee
    ) external onlyDiagonalAdmin {
        if (receiver == address(0)) revert InvalidReceiverAddress();
        if (token == address(0)) revert InvalidTokenAddress();
        if (amount == 0) revert InvalidAmount();

        _safeCall(token, abi.encodeWithSelector(ERC20.transfer.selector, receiver, amount));

        if (fee > 0) {
            _safeCall(token, abi.encodeWithSelector(ERC20.transfer.selector, TOKEN_FEE_RECIPIENT, fee));
        }
        emit WithdrawSuccessful(receiver, token, amount);
    }
}