// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RooitStar is ERC20Burnable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and mint 2B token to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor() ERC20("Rooit Star", "STAR") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), 2000000000 * 10 ** decimals());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        _mint(to, amount);
    }
}