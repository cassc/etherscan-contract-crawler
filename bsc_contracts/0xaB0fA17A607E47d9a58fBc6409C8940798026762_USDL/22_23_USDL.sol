// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./interfaces/IUSDL.sol";

contract USDL is
    IUSDL,
    ERC20PermitUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using SafeCastUpgradeable for uint256;

    // CONSTANTS

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    // INITIALIZER

    function initialize() external initializer {
        __ERC20_init("Leto USD", "USDL");
        __ERC20Permit_init("Leto USD");

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // PUBLIC FUNCTIONS

    function mint(address account, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _burn(account, amount);
    }
}