// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ITreasury.sol";

interface IWhiteList is ITreasury {
    event WhiteListUserAdded(address indexed user);
    event WhiteListUserRemoved(address indexed user);

    function addWhiteLists(address[] memory _user) external;

    function removeWhiteLists(address[] memory _user) external;

    function whiteListWithdraw(
        IERC20Upgradeable token_,
        address to_,
        uint256 amount_
    ) external;
    function setMaxWithdrawAmount(uint256 amount_) external;
}