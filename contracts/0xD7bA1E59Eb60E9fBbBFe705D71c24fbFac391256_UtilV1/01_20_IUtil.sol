//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IxTypes.sol";

interface IUtil {
    event Approved(
        address indexed owner,
        address indexed spender,
        address token,
        uint256 value,
        string memo
    );
    event Transferred(
        address indexed from,
        address indexed to,
        address token,
        uint256 amount,
        string memo
    );

    /**
     * perform erc20 approve using permit
     * this function is designed to be integrated with opengsn, delegating gas fee
     */
    function approveWithPermit(
        address token,
        string calldata memo,
        IxTypes.PermitData calldata permission
    ) external;

    /**
     * perform erc20 transfer. the contract must be approved before the call
     * this function is designed to be integrated with opengsn, delegating gas fee
     */
    function transfer(address to, address token, uint256 amount, string calldata memo) external;

    /**
     * perform erc20 transfer using permit, not approve
     * this function is designed to be integrated with opengsn, delegating gas fee
     */
    function transferWithPermit(
        address to,
        address token,
        uint256 amount,
        string calldata memo,
        IxTypes.PermitData calldata permission
    ) external;
}