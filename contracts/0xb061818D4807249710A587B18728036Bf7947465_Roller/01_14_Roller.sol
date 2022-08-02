// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;
import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";
import "@yield-protocol/yieldspace-tv/src/interfaces/IMaturingToken.sol";
import "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
// import "@yield-protocol/vault-interfaces/src/ILadle.sol";
import "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
// import "@yield-protocol/strategy-v2/contracts/IStrategy.sol";
import "@yield-protocol/utils-v2/contracts/token/MinimalTransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";

interface ILadle {
    function joins(bytes6) external view returns (address);
}

interface IStrategy {
    function baseId() external view returns (bytes6);
    function pool() external view returns (IPool);
    function nextPool() external view returns (IPool);
    function startPool(uint256 minRatio, uint256 maxRatio) external;
    function endPool() external;
}

/* @notice This contract solves the problem of Joins being underfunded to support a strategy roll:
 - Take a flash loan from an ERC3156 server
 - Mint fyToken with the loan, funding the Join
 - Divest the strategy
 - Invest the strategy, hopefully at 0%
 - Sell the fyToken in the market, repaying part of the flash loan
 - Repay the rest of the flash loan with own funds.
*/
contract Roller is IERC3156FlashBorrower, AccessControl {
    using MinimalTransferHelper for IERC20;

    ILadle public immutable ladle;

    constructor(ILadle ladle_) {
        ladle = ladle_;
    }

    /// @dev Strategy being rolled, also used to denote that access control was passed.
    IStrategy internal _strategy;

    /**
     * @dev Initiate a strategy roll. If a flash loan is requested, it will be capped at
     * the fyToken balance of the pool that the strategy is divesting from.
     * @param strategy Strategy to roll
     * @param maxLoan Maximum amount that will be flash borrowed
     * @param lender ERC3156 flash lender, if needed
     * @param remainder Receiver of any funds remaining in this contract after the roll
     */
    function roll(IStrategy strategy, uint256 maxLoan, IERC3156FlashLender lender, address remainder) external auth {
        // Get pool from strategy
        IPool pool = strategy.pool();
        require (address(pool) != address(0), "Strategy not active");
        IERC20 base = pool.base();
        IMaturingToken fyToken = pool.fyToken();
        uint256 toRedeem = fyToken.balanceOf(address(pool));
        uint256 loan = maxLoan < toRedeem ? maxLoan : toRedeem;

        // Enter the loan and roll
        _strategy = strategy;
        if (loan > 0) lender.flashLoan(IERC3156FlashBorrower(address(this)), address(base), loan, "");
        else this.onFlashLoan(address(this), address(base), 0, 0, ""); // If we don't need a flash loan, we take the shortcut

        // Whatever is left after repaying the loan, we return it
        base.safeTransfer(remainder, base.balanceOf(address(this)));
        delete _strategy;
    }

    /**
     * @dev Receive a flash loan and use it to fund a join during a strategy roll.
     * Extra funds to cover loan fees and market losses should be present in this contract before this call
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes memory
    ) external returns (bytes32) {
        IStrategy strategy = _strategy;
        require (address(strategy) != address(0), "Unauthorized roll");
        IERC20 token_ = IERC20(token);
        // Get join from strategy and ladle
        address join = ladle.joins(strategy.baseId());
        require (join != address(0), "Join not found");

        // Get pool from strategy
        IPool pool = strategy.nextPool();
        require (pool != IPool(address(0)), "Pool not ready");

        // Get fyToken from pool
        IMaturingToken fyToken = pool.fyToken();                  // The fyToken can't be address(0)

        // If a loan was requested, we fund the join by minting fyToken
        if (amount > 0) {
            token_.safeTransfer(join, amount);
            IFYToken(address(fyToken)).mintWithUnderlying(address(this), amount);
        }
        // Roll the pool
        strategy.endPool();                                 // This drains the join
        strategy.startPool(0, type(uint256).max);           // We skip the slippage check, because we run only on fresh pools


        // If a loan was requested, we sell the fyToken to repay it
        if (amount > 0) {
            fyToken.transfer(address(pool), amount);
            pool.sellFYToken(address(this), 0);
            uint256 repayment = amount + fee;
            token_.approve(msg.sender, repayment);
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}