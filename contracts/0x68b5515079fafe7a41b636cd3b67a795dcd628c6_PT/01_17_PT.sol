// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/protocol/tokens/MinterPauserClaimableERC20.sol";
import "contracts/interfaces/apwine/IFutureVault.sol";

/**
 * @title APWine interest bearing token
 * @notice Interest bearing token for the futures liquidity provided
 * @dev the value of an APWine IBT is equivalent to a fixed amount of underlying tokens of the futureVault IBT
 */
contract PT is MinterPauserClaimableERC20 {
    using SafeMathUpgradeable for uint256;

    IFutureVault public futureVault;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * futureVault
     *
     * See {ERC20-constructor}.s
     */

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address futureAddress
    ) public initializer {
        super.initialize(name, symbol);
        _setupRole(DEFAULT_ADMIN_ROLE, futureAddress);
        _setupRole(MINTER_ROLE, futureAddress);
        _setupRole(PAUSER_ROLE, futureAddress);
        futureVault = IFutureVault(futureAddress);
        _setupDecimals(decimals);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // sender and receiver state update
        if (from != address(futureVault) && to != address(futureVault) && from != address(0x0) && to != address(0x0)) {
            futureVault.updateUserState(from);
            futureVault.updateUserState(to);
            require(
                balanceOf(from) >= amount.add(futureVault.getTotalDelegated(from)),
                "ERC20: transfer amount exceeds transferrable balance"
            );
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public override {
        if (msg.sender != address(futureVault)) {
            super.burnFrom(account, amount);
        } else {
            _burn(account, amount);
        }
    }

    /**
     * @notice Returns the current balance of one user including the pt that were not claimed yet
     * @param account the address of the account to check the balance of
     * @return the total pt balance of one address
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account).add(futureVault.getClaimablePT(account));
    }

    /**
     * @notice Returns the current balance of one user (without the claimable amount)
     * @param account the address of the account to check the balance of
     * @return the current pt balance of this address
     */
    function recordedBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    uint256[50] private __gap;
}