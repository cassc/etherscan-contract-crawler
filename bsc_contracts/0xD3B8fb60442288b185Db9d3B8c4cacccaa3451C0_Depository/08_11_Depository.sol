// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../access/roles/AccessControlInternal.sol";
import "../../security/ReentrancyGuard.sol";

import "./IDepository.sol";

/**
 * @title Depository
 * @notice A simple depository contract to hold native or ERC20 tokens and allow certain roles to transfer or disperse.
 *
 * @custom:type eip-2535-facet
 * @custom:category Finance
 * @custom:provides-interfaces IDepository
 */
contract Depository is IDepository, ReentrancyGuard, AccessControlInternal {
    using Address for address payable;

    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    function transferNative(address wallet, uint256 amount) external payable onlyRole(DEPOSITOR_ROLE) nonReentrant {
        payable(wallet).sendValue(amount);
    }

    function transferNative(address[] calldata wallets, uint256[] calldata amounts)
        external
        payable
        onlyRole(DEPOSITOR_ROLE)
        nonReentrant
    {
        require(wallets.length == amounts.length, "Depository: invalid length");

        for (uint256 i = 0; i < wallets.length; i++) {
            payable(wallets[i]).sendValue(amounts[i]);
        }
    }

    function transferERC20(
        address token,
        address wallet,
        uint256 amount
    ) external payable onlyRole(DEPOSITOR_ROLE) nonReentrant {
        IERC20(token).transfer(address(wallet), amount);
    }

    function transferERC20(
        address[] calldata tokens,
        address[] calldata wallets,
        uint256[] calldata amounts
    ) external payable onlyRole(DEPOSITOR_ROLE) nonReentrant {
        require(wallets.length == amounts.length, "Depository: invalid length");
        require(wallets.length == tokens.length, "Depository: invalid length");

        for (uint256 i = 0; i < wallets.length; i++) {
            IERC20(tokens[i]).transfer(address(wallets[i]), amounts[i]);
        }
    }
}