//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "dss-interfaces/src/dss/DaiAbstract.sol";
import {ConfigStorageLib} from "../libraries/StorageLib.sol";

abstract contract PermitForwarder {
    using SafeERC20 for IERC20Permit;

    error UnknownToken(address token);

    /// @dev Execute an ERC2612 permit for the selected token
    function forwardPermit(
        IERC20Permit token,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (ConfigStorageLib.isTrustedToken(address(token))) {
            token.safePermit(msg.sender, spender, amount, deadline, v, r, s);
        } else {
            revert UnknownToken(address(token));
        }
    }

    /// @dev Execute a Dai-style permit for the selected token
    function forwardDaiPermit(
        DaiAbstract token,
        address spender,
        uint256 nonce,
        uint256 deadline,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (ConfigStorageLib.isTrustedToken(address(token))) {
            token.permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
        } else {
            revert UnknownToken(address(token));
        }
    }
}