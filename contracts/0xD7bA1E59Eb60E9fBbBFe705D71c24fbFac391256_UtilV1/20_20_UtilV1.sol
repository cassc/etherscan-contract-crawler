//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./libs/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUtil.sol";
import "./IxBaseV1.sol";

contract UtilV1 is IUtil, IxBaseV1 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    constructor(address admin, address forwarder) IxBaseV1(admin, forwarder) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function versionRecipient() external pure override returns (string memory) {
        return "intella-util-v1;opengsn-2.2.5";
    }

    /**
     * perform erc20 approve using permit
     * this function is designed to be integrated with opengsn, delegating gas fee
     */
    function approveWithPermit(
        address token,
        string calldata memo,
        IxTypes.PermitData calldata permission
    ) external nonReentrant {
        // permit for token to transfer
        IERC20Permit(token).safePermit(
            permission.owner,
            permission.spender,
            permission.value,
            permission.deadline,
            permission.v,
            permission.r,
            permission.s
        );

        emit Approved(permission.owner, permission.spender, token, permission.value, memo);
    }

    /**
     * perform erc20 transfer. the contract must be approved before the call
     * this function is designed to be integrated with opengsn, delegating gas fee
     */
    function transfer(
        address to,
        address token,
        uint256 amount,
        string calldata memo
    ) external nonReentrant {
        // set msg sender to from address
        address from = _msgSender();

        // transfer token
        IERC20(token).safeTransferFrom(from, to, amount);

        emit Transferred(from, to, token, amount, memo);
    }

    /**
     * perform erc20 transfer using permit
     * this function is designed to be integrated with opengsn, delegating gas fee
     */
    function transferWithPermit(
        address to,
        address token,
        uint256 amount,
        string calldata memo,
        IxTypes.PermitData calldata permission
    ) external nonReentrant {
        // permit for token to transfer
        IERC20Permit(token).safePermit(
            permission.owner,
            permission.spender,
            permission.value,
            permission.deadline,
            permission.v,
            permission.r,
            permission.s
        );

        // set msg sender to from address
        address from = _msgSender();

        // transfer token
        IERC20(token).safeTransferFrom(from, to, amount);

        emit Transferred(from, to, token, amount, memo);
    }
}