pragma solidity 0.7.6;

import "contracts/protocol/tokens/MinterPauserClaimableERC20.sol";
import "contracts/interfaces/apwine/IFuture.sol";

/**
 * @title Future Yield Token erc20
 * @notice ERC20 mintable pausable
 * @dev FYT are minted at the beginning of one period and can be burned against their underlying yield at the expiration of the period
 */
contract FutureYieldToken is MinterPauserClaimableERC20 {
    using SafeMathUpgradeable for uint256;

    IFuture public future;
    uint256 public internalPeriodID;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * future
     *
     * See {ERC20-constructor}.
     */
    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _decimals,
        uint256 _internalPeriodID,
        address _futureAddress
    ) public initializer {
        super.initialize(_tokenName, _tokenSymbol);
        _setupRole(DEFAULT_ADMIN_ROLE, _futureAddress);
        _setupRole(MINTER_ROLE, _futureAddress);
        _setupRole(PAUSER_ROLE, _futureAddress);
        future = IFuture(_futureAddress);
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
        if (from != address(future) && to != address(future) && from != address(0x0) && to != address(0x0)) {
            // update apwIBT and FYT balances before executing the transfer
            if (future.hasClaimableFYT(from)) {
                future.claimFYT(from);
            }
            if (future.hasClaimableFYT(to)) {
                future.claimFYT(to);
            }
        }
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        if (recipient != address(future) && recipient != future.getFutureWalletAddress()) {
            _approve(
                sender,
                _msgSender(),
                allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance")
            );
        }
        return true;
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
        if (msg.sender != future.getFutureWalletAddress() && msg.sender != address(future)) {
            super.burnFrom(account, amount);
        } else {
            _burn(account, amount);
        }
    }

    /**
     * @notice returns the current balance of one user including unclaimed FYT
     * @param account the address of the account to check the balance of
     * @return the total FYT balance of one address
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account).add(future.getClaimableFYTForPeriod(account, internalPeriodID));
    }
}