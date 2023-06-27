//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/ITokensRescuer.sol";

import "./CheckerZeroAddr.sol";

abstract contract TokensRescuer is
    Initializable,
    ITokensRescuer,
    CheckerZeroAddr
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __TokensRescuer_init_unchained() internal onlyInitializing {}

    function _rescueNativeToken(
        uint256 amount,
        address receiver
    ) internal onlyNonZeroAddress(receiver) {
        AddressUpgradeable.sendValue(payable(receiver), amount);
    }

    function _rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) internal virtual onlyNonZeroAddress(receiver) onlyNonZeroAddress(token) {
        IERC20Upgradeable(token).safeTransfer(receiver, amount);
    }

    uint256[50] private __gap;
}