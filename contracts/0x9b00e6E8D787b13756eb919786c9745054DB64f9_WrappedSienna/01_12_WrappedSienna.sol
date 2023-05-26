// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

contract WrappedSienna is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract. Grants `MINTER_ROLE` to the bridge.
     *
     * See {ERC20-constructor}.
     */
    constructor(address bridge) public ERC20("Sienna (ERC20)", "wSIENNA") {
        _setupDecimals(18);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, bridge);
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
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "WrappedSIENNA: must have pauser role to pause"
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
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "WrappedSIENNA: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev Overrides the `_transfer` function, so if  the
     * minter is either the sender or recipient the tokens
     * will be minted or burned respectively.
     *
     * In all other cases the `_transfer()` will invoke the
     * `_transfer()` of the inherited ERC20 contract using
     * `super._transfer()`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (hasRole(MINTER_ROLE, sender)) {
            _mint(recipient, amount);
        } else if (hasRole(MINTER_ROLE, recipient)) {
            _burn(sender, amount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /**
     * @dev Overrides `transferFrom`, to prevent possible
     * side effect from `_transfer()` in case the `minter`
     * has given an allowance to an account.
     *
     * See ERC20's `transferFrom` - it uses `_transfer()`
     * internally.
     *
     * Requirements:
     *
     * - the caller must have allowance >= than the amount
     * requested to be transferred.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        super._transfer(sender, recipient, amount);

        uint256 allowed = super.allowance(sender, _msgSender());
        require(allowed >= amount, "ERC20: Check the token allowance");
        super._approve(
            sender,
            _msgSender(),
            allowed.sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}