// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

interface IWETHGateway {
    event EmergencyTokenTransfer(address token, address to, uint256 amount);

    function depositETH(address onBehalfOf, uint16 referralCode)
        external
        payable;

    function withdrawETH(uint256 amount, address onBehalfOf) external;

    function repayETH(uint256 amount, address onBehalfOf) external payable;

    function borrowETH(uint256 amount, uint16 referralCode) external;

    function withdrawETHWithPermit(
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;
}