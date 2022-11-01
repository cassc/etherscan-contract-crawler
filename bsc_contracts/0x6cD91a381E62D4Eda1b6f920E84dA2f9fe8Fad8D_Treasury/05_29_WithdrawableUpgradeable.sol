// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./TransferableUpgradeable.sol";

import "./interfaces/IWithdrawableUpgradeable.sol";

abstract contract WithdrawableUpgradeable is
    ContextUpgradeable,
    TransferableUpgradeable,
    IWithdrawableUpgradeable
{
    receive() external payable virtual {
        emit Received(_msgSender(), msg.value);
    }

    function __Withdrawable_init() internal onlyInitializing {}

    function __Withdrawable_init_unchained() internal onlyInitializing {}

    function withdraw(
        IERC20Upgradeable token_,
        address to_,
        uint256 amount_
    ) external virtual override;

    uint256[50] private __gap;
}