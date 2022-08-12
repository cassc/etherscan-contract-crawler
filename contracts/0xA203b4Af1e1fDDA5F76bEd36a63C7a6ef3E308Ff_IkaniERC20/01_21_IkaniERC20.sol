// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { AccessControl } from "../deps/oz_c_4_7_2/AccessControl.sol";
import { ERC20 } from "../deps/oz_c_4_7_2/ERC20.sol";
import { ERC20Permit } from "../deps/oz_c_4_7_2/draft-ERC20Permit.sol";
import { ERC20Votes } from "../deps/oz_c_4_7_2/ERC20Votes.sol";
import { Pausable } from "../deps/oz_c_4_7_2/Pausable.sol";

import { IIkaniERC20 } from "./interfaces/IIkaniERC20.sol";

/**
 * @title IkaniERC20
 * @author Cyborg Labs, LLC
 *
 * @notice The IKANI.AI ERC-20 utility token.
 *
 *  Has the following features:
 *    - Mintable
 *    - Burnable
 *    - Pausable
 *    - Permit
 *    - Votes
 *
 *  When paused, transfers are disabled, except for minting and burning.
 */
contract IkaniERC20 is
    ERC20,
    Pausable,
    AccessControl,
    ERC20Permit,
    ERC20Votes,
    IIkaniERC20
{
    //---------------- Constants ----------------//

    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ADMIN_ROLE = keccak256("PAUSER_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //---------------- Constructor ----------------//

    constructor(
        string memory name,
        string memory symbol,
        address admin
    )
        ERC20(name, symbol)
        ERC20Permit(name)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ADMIN_ROLE, admin);

        // Define separate admins for each role. This gives us the flexibility to be able to fully
        // renounce minter or pauser capabilities independently of each other while retaining
        // the ability to separate role-granters from role-bearers.
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, PAUSER_ADMIN_ROLE);
    }

    //---------------- Admin-Only External Functions ----------------//

    function pause()
        external
        onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole(PAUSER_ROLE)
    {
        _unpause();
    }

    function mint(
        address to,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external
        override
        onlyRole(MINTER_ROLE)
    {
        _mint(to, amount);
        emit Minted(to, amount, receipt, receiptData);
    }

    //---------------- External Functions ----------------//

    function burn(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external
        override
    {
        require(
            msg.sender == from,
            "Not authorized to burn"
        );
        _burn(from, amount);
        emit Burned(from, amount, receipt, receiptData);
    }

    /**
     * @notice Convenience function for the specific use case of burning exactly the permit amount.
     */
    function burnWithPermit(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
    {
        permit(from, msg.sender, amount, deadline, v, r, s);
        burnFrom(from, amount, receipt, receiptData);
    }

    //---------------- Public Functions ----------------//

    function burnFrom(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        public
        override
    {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        emit Burned(from, amount, receipt, receiptData);
    }

    //---------------- Overrides ----------------//

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
    {
        require(
            (
                !paused() ||
                to == address(0) ||
                from == address(0)
            ),
            "Transfers are disabled"
        );
        super._beforeTokenTransfer(from, to, amount);
    }

    //---------------- Trivial Overrides ----------------//

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    )
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    )
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}