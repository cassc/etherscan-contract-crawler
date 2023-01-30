// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInviteManager {
    struct DynamicIncome {
        address user;
        uint256 rate;
    }

    function onTransferToNozeroAddress(
        address from,
        address to,
        uint256 amount
    ) external;

    function nodeConfig(address user) external returns (bool);

    function allocationUsersWhenDeal(address user)
        external
        view
        returns (address[] memory);

    function allocationDynamicIncome(address user)
        external
        view
        returns (DynamicIncome[] memory);
}