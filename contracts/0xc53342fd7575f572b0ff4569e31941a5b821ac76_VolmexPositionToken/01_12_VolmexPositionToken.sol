// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";

/**
 * @title Token Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexPositionToken is
    Initializable,
    AccessControlUpgradeable,
    ERC20PausableUpgradeable
{
    // Position token role, calculated as keccak256("VOLMEX_PROTOCOL_ROLE")
    bytes32 public constant VOLMEX_PROTOCOL_ROLE =
        0x33ba6006595f7ad5c59211bde33456cab351f47602fc04f644c8690bc73c4e16;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `VOLMEX_PROTOCOL_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function initialize(string memory name, string memory symbol)
        external
        initializer
    {
        __ERC20_init_unchained(name, symbol);
        __AccessControl_init_unchained();

        __ERC20Pausable_init();
        __ERC165_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VOLMEX_PROTOCOL_ROLE, msg.sender);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `VOLMEX_PROTOCOL_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(address from, uint256 amount) public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to burn"
        );
        _burn(from, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `VOLMEX_PROTOCOL_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `VOLMEX_PROTOCOL_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to unpause"
        );
        _unpause();
    }
}