// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

import "./AccessControlCustom.sol";
import "./TokenRecover.sol";

contract VegasONE is
    ERC1363,
    ERC20Burnable,
    ERC20Capped,
    TokenRecover,
    AccessControlCustom
{
    /**
     * Global Variables
     */

    string public constant VERSION = "v1.0.0";

    /**
     * Errors
     */

    error ErrForbidden();

    /**
     * Constructor
     */

    constructor(
        string memory newName,
        string memory newSymbol,
        uint256 newCap
    ) ERC20(newName, newSymbol) ERC20Capped(newCap) {}

    /**
     * External/Public Functions
     */

    function mint(address to, uint256 amount) external {
        address sender = _msgSender();

        // only admin
        if (!hasRole(DEFAULT_ADMIN_ROLE, sender)) {
            revert ErrForbidden();
        }

        _mint(to, amount);
    }

    function recoverERC20(
        address token,
        address to,
        uint256 amount
    ) external {
        // only admin
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert ErrForbidden();
        }

        _recoverERC20(token, to, amount);
    }

    /**
     * Misc
     */

    // The following functions are overrides required by Solidity.

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        ERC20Capped._mint(to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1363, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}