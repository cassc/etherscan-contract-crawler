// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./TokenBase/Base.sol";

/**
 * @title dForce's Lending Protocol Contract.
 * @notice iTokens which wrap an EIP-20 underlying.
 * @author dForce Team.
 */
contract iToken is Base {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Expects to call only once to initialize a new market.
     * @param _underlyingToken The underlying token address.
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _controller Core controller contract address.
     * @param _interestRateModel Token interest rate model contract address.
     */
    function initialize(
        address _underlyingToken,
        string memory _name,
        string memory _symbol,
        IControllerInterface _controller,
        IInterestRateModelInterface _interestRateModel
    ) external initializer {
        require(
            address(_underlyingToken) != address(0),
            "initialize: underlying address should not be zero address!"
        );
        require(
            address(_controller) != address(0),
            "initialize: controller address should not be zero address!"
        );
        require(
            address(_interestRateModel) != address(0),
            "initialize: interest model address should not be zero address!"
        );
        _initialize(
            _name,
            _symbol,
            ERC20(_underlyingToken).decimals(),
            _controller,
            _interestRateModel
        );

        underlying = IERC20Upgradeable(_underlyingToken);
    }

    /**
     * @notice In order to support deflationary token, returns the changed amount.
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom`.
     */
    function _doTransferIn(address _sender, uint256 _amount)
        internal
        virtual
        override
        returns (uint256)
    {
        uint256 _balanceBefore = underlying.balanceOf(address(this));
        underlying.safeTransferFrom(_sender, address(this), _amount);
        return underlying.balanceOf(address(this)).sub(_balanceBefore);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transfer`.
     */
    function _doTransferOut(address payable _recipient, uint256 _amount)
        internal
        virtual
        override
    {
        underlying.safeTransfer(_recipient, _amount);
    }

    /**
     * @dev Gets balance of this contract in terms of the underlying
     */
    function _getCurrentCash() internal view virtual override returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * @dev Caller deposits assets into the market and `_recipient` receives iToken in exchange.
     * @param _recipient The account that would receive the iToken.
     * @param _mintAmount The amount of the underlying token to deposit.
     */
    function mint(address _recipient, uint256 _mintAmount)
        external
        nonReentrant
        settleInterest
    {
        _mintInternal(_recipient, _mintAmount);
    }

    /**
     * @dev Caller deposits assets into the market and caller receives iToken in exchange,
     *        and add markets to caller's markets list for liquidity calculations.
     * @param _mintAmount The amount of the underlying token to deposit.
     */
    function mintForSelfAndEnterMarket(uint256 _mintAmount)
        external
        nonReentrant
        settleInterest
    {
        _mintInternal(msg.sender, _mintAmount);
        controller.enterMarketFromiToken(address(this), msg.sender);
    }

    /**
     * @dev Caller redeems specified iToken from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemiToken The number of iToken to redeem.
     */
    function redeem(address _from, uint256 _redeemiToken)
        external
        nonReentrant
        settleInterest
    {
        _redeemInternal(
            _from,
            _redeemiToken,
            _redeemiToken.rmul(_exchangeRateInternal())
        );
    }

    /**
     * @dev Caller redeems specified underlying from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemUnderlying The number of underlying to redeem.
     */
    function redeemUnderlying(address _from, uint256 _redeemUnderlying)
        external
        nonReentrant
        settleInterest
    {
        _redeemInternal(
            _from,
            _redeemUnderlying.rdivup(_exchangeRateInternal()),
            _redeemUnderlying
        );
    }

    /**
     * @dev Caller borrows tokens from the protocol to their own address.
     * @param _borrowAmount The amount of the underlying token to borrow.
     */
    function borrow(uint256 _borrowAmount)
        external
        nonReentrant
        settleInterest
    {
        _borrowInternal(msg.sender, _borrowAmount);
    }

    /**
     * @dev Caller repays their own borrow.
     * @param _repayAmount The amount to repay.
     */
    function repayBorrow(uint256 _repayAmount)
        external
        nonReentrant
        settleInterest
    {
        _repayInternal(msg.sender, msg.sender, _repayAmount);
    }

    /**
     * @dev Caller repays a borrow belonging to borrower.
     * @param _borrower the account with the debt being payed off.
     * @param _repayAmount The amount to repay.
     */
    function repayBorrowBehalf(address _borrower, uint256 _repayAmount)
        external
        nonReentrant
        settleInterest
    {
        _repayInternal(msg.sender, _borrower, _repayAmount);
    }

    /**
     * @dev The caller liquidates the borrowers collateral.
     * @param _borrower The account whose borrow should be liquidated.
     * @param _assetCollateral The market in which to seize collateral from the borrower.
     * @param _repayAmount The amount to repay.
     */
    function liquidateBorrow(
        address _borrower,
        uint256 _repayAmount,
        address _assetCollateral
    ) external nonReentrant settleInterest {
        _liquidateBorrowInternal(_borrower, _repayAmount, _assetCollateral);
    }

    /**
     * @dev Transfers this tokens to the liquidator.
     * @param _liquidator The account receiving seized collateral.
     * @param _borrower The account having collateral seized.
     * @param _seizeTokens The number of iTokens to seize.
     */
    function seize(
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) external override nonReentrant {
        _seizeInternal(msg.sender, _liquidator, _borrower, _seizeTokens);
    }

    /**
     * @notice Calculates interest and update total borrows and reserves.
     * @dev Updates total borrows and reserves with any accumulated interest.
     */
    function updateInterest() external override returns (bool) {
        _updateInterest();
        return true;
    }

    /**
     * @dev Gets the newest exchange rate by accruing interest.
     */
    function exchangeRateCurrent() external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return _exchangeRateInternal();
    }

    /**
     * @dev Calculates the exchange rate without accruing interest.
     */
    function exchangeRateStored() external view override returns (uint256) {
        return _exchangeRateInternal();
    }

    /**
     * @dev Gets the underlying balance of the `_account`.
     * @param _account The address of the account to query.
     */
    function balanceOfUnderlying(address _account) external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return _exchangeRateInternal().rmul(balanceOf[_account]);
    }

    /**
     * @dev Gets the user's borrow balance with the latest `borrowIndex`.
     */
    function borrowBalanceCurrent(address _account)
        external
        nonReentrant
        returns (uint256)
    {
        // Accrues interest.
        _updateInterest();

        return _borrowBalanceInternal(_account);
    }

    /**
     * @dev Gets the borrow balance of user without accruing interest.
     */
    function borrowBalanceStored(address _account)
        external
        view
        override
        returns (uint256)
    {
        return _borrowBalanceInternal(_account);
    }

    /**
     * @dev Gets user borrowing information.
     */
    function borrowSnapshot(address _account)
        external
        view
        returns (uint256, uint256)
    {
        return (
            accountBorrows[_account].principal,
            accountBorrows[_account].interestIndex
        );
    }

    /**
     * @dev Gets the current total borrows by accruing interest.
     */
    function totalBorrowsCurrent() external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return totalBorrows;
    }

    /**
     * @dev Returns the current per-block borrow interest rate.
     */
    function borrowRatePerBlock() public view returns (uint256) {
        return
            interestRateModel.getBorrowRate(
                _getCurrentCash(),
                totalBorrows,
                totalReserves
            );
    }

    /**
     * @dev Returns the current per-block supply interest rate.
     *  Calculates the supply rate:
     *  underlying = totalSupply × exchangeRate
     *  borrowsPer = totalBorrows ÷ underlying
     *  supplyRate = borrowRate × (1-reserveFactor) × borrowsPer
     */
    function supplyRatePerBlock() external virtual view returns (uint256) {
        // `_underlyingScaled` is scaled by 1e36.
        uint256 _underlyingScaled = totalSupply.mul(_exchangeRateInternal());
        if (_underlyingScaled == 0) return 0;
        uint256 _totalBorrowsScaled = totalBorrows.mul(BASE);

        return
            borrowRatePerBlock().tmul(
                BASE.sub(reserveRatio),
                _totalBorrowsScaled.rdiv(_underlyingScaled)
            );
    }

    /**
     * @dev Get cash balance of this iToken in the underlying token.
     */
    function getCash() external view returns (uint256) {
        return _getCurrentCash();
    }
}