// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @dev Backward compatible EIP-2612 contract definitions.
//  For more information, please refer to https://eips.ethereum.org/EIPS/eip-2612#backwards-compatibility
interface IPermit2612Compatible {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @dev Base contract for supporting the EIP-2612 specification.
/// For more information, please refer to https://eips.ethereum.org/EIPS/eip-2612
abstract contract AbstractSelfPermit2612 {
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (IERC20(token).allowance(msg.sender, address(this)) < value)
            IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitCompatible(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        IPermit2612Compatible(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    function selfPermitCompatibleIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (IERC20(token).allowance(msg.sender, address(this)) < type(uint256).max)
            IPermit2612Compatible(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }
}