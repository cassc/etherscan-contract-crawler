// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract HyperCycleToken is AccessControl, ERC20Burnable, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant MAX_SUPPLY = 2147483648 * 10**uint256(6);

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
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
    function mint(address to, uint256 amount) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()), 
            "ERC20PresetMinterPauser: must have minter role to mint"
        );
        require(
            (totalSupply() + amount) <= MAX_SUPPLY, 
            "Mint: Cannot mint more than initial supply"
        );
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()), 
            "ERC20PresetMinterPauser: must have pauser role to pause"
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
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()), 
            "ERC20PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev Set the decimals to 6 decimals.
     *
     * See {ERC20-decimals}.
     *
     * Requirements:
     *
     * - The HyperCycle token should be 6 decimals instead of default decimals. 
     * This is only for display purpose.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 amount
    ) 
        internal 
        override 
        whenNotPaused 
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}