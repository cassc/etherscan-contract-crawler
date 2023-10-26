// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/protocol/tokens/MinterPauserClaimableERC20.sol";
import "contracts/interfaces/apwine/IFutureVault.sol";

/**
 * @title Future Yield Token erc20
 * @notice ERC20 mintable pausable
 * @dev FYT are minted at the beginning of one period and can be burned against their underlying yield at the expiration of the period
 */
contract FutureYieldToken is MinterPauserClaimableERC20 {
    using SafeMathUpgradeable for uint256;

    IFutureVault public futureVault;
    uint256 public internalPeriodID;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * futureVault
     *
     * See {ERC20-constructor}.
     */
    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _decimals,
        uint256 _internalPeriodID,
        address _futureVault
    ) public initializer {
        super.initialize(_tokenName, _tokenSymbol);
        _setupRole(DEFAULT_ADMIN_ROLE, _futureVault);
        _setupRole(MINTER_ROLE, _futureVault);
        _setupRole(PAUSER_ROLE, _futureVault);
        futureVault = IFutureVault(_futureVault);
        internalPeriodID = _internalPeriodID;
        _setupDecimals(_decimals);
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
            if (super.balanceOf(from) < amount) futureVault.claimFYT(from, amount.sub(super.balanceOf(from)));
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
        if (msg.sender != futureVault.getFutureWalletAddress() && msg.sender != address(futureVault)) {
            super.burnFrom(account, amount);
        } else {
            _burn(account, amount);
        }
    }

    /**
     * @notice Returns the current balance of one user including unclaimed FYT
     * @param account the address of the account to check the balance of
     * @return the total FYT balance of one address
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account).add(futureVault.getClaimableFYTForPeriod(account, internalPeriodID));
    }

    /**
     * @notice Returns the current balance of one user (without the claimable amount)
     * @param account the address of the account to check the balance of
     * @return the current FYT balance of this address
     */
    function recordedBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }
}