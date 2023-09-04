// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;
import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";
import "@yield-protocol/yieldspace-tv/src/interfaces/IMaturingToken.sol";
import "@yield-protocol/vault-v2/src/interfaces/IFYToken.sol";
import "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import "@yield-protocol/utils-v2/src/token/MinimalTransferHelper.sol";
import "@yield-protocol/utils-v2/src/access/AccessControl.sol";

interface ITrader {
    function authorize(address grantee) external;
    function retrieve(IERC20 token) external returns (uint256 amount);
    function sellFYToken(IPool pool, uint128 fySold, uint128 minBaseOut) external returns (uint256 cost);
    function buyBase(IPool pool, uint128 baseBought, uint128 maxFyIn) external returns (uint256 cost);
}

contract Trader is ITrader, IERC3156FlashBorrower, AccessControl {
    using MinimalTransferHelper for IERC20;

    enum Trade { SELLFYTOKEN, BUYBASE }

    event FYTokenSold(IPool indexed pool, uint256 fySold, uint256 cost);
    event BaseBought(IPool indexed pool, uint256 baseBought, uint256 cost);

    IERC3156FlashLender immutable public lender;
    uint256 private init;

    /// @dev For simplicity, we use a single flash lender. Euler works well.
    constructor (IERC3156FlashLender lender_) {
        lender = lender_;
        authorize(msg.sender);
    }

    /// @dev Give permission to an address to use this contract
    function authorize(address grantee) override public auth {
        _grantRole(this.authorize.selector, grantee);
        _grantRole(this.retrieve.selector, grantee);
        _grantRole(this.sellFYToken.selector, grantee);
        _grantRole(this.buyBase.selector, grantee);
    }

    /// @dev Drain this contract of a given token.
    function retrieve(IERC20 token) override external auth returns (uint256 amount) {
        amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);   
    }

    /// @dev Execute an base flash loan and with it, mint fyToken and sell them to a pool
    function sellFYToken(IPool pool, uint128 fySold, uint128 minBaseOut) override external auth returns (uint256 cost) {
        IERC20 base = pool.base();

        // We will obtain `fySold` by flash borrowing an equal amount of base and using it to mint fyToken at 1:1
        init = base.balanceOf(address(this)); // We use this as a semaphore, and to retrieve return data
        lender.flashLoan(IERC3156FlashBorrower(address(this)), address(base), fySold, abi.encode(Trade.SELLFYTOKEN, pool, 0, minBaseOut));
        cost = init - base.balanceOf(address(this));
        delete init;
        emit FYTokenSold(pool, fySold, cost);
    }

    /// @dev Execute an base flash loan and with it, mint fyToken and buy base from a pool
    function buyBase(IPool pool, uint128 baseBought, uint128 maxFyIn) override external auth returns (uint256 cost) {
        IERC20 base = pool.base();

        // We will flash borrow the base that we need, 
        init = base.balanceOf(address(this)); // We use this as a semaphore, and to retrieve return data
        uint256 fySold = pool.buyBasePreview(baseBought);
        lender.flashLoan(IERC3156FlashBorrower(address(this)), address(base), fySold, abi.encode(Trade.BUYBASE, pool, baseBought, maxFyIn));
        cost = init - base.balanceOf(address(this));
        delete init;
        emit BaseBought(pool, baseBought, cost);
    }

    /**
     * @dev Receive a flash loan and use it to mint fyToken and trade them in a pool.
     * Extra funds to cover loan fees and market losses should be present in this contract before this call
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256,
        bytes memory data
    ) external returns (bytes32) {
        require (init != 0, "Unauthorized");
        (Trade trade, IPool pool, uint128 baseOut, uint128 limit) = abi.decode(data, (Trade, IPool, uint128, uint128));
        IFYToken fyToken = IFYToken(address(pool.fyToken()));
        IERC20 base = pool.base();
        require(address(base) == token, "Mismatched pool");

        // Get join from fyToken
        IJoin join = fyToken.join();

        // Approve the lender to take any funds
        IERC20(token).approve(msg.sender, type(uint256).max);

        // We mint fyToken at 1:1
        base.safeTransfer(address(join), amount);
        fyToken.mintWithUnderlying(address(pool), amount);

        // We sell the fyToken to repay the flash loan
        if (trade == Trade.SELLFYTOKEN) pool.sellFYToken(address(this), limit);
        else pool.buyBase(address(this), baseOut, limit);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}