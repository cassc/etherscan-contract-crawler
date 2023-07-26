// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/IFlashloanExecutor.sol";
import "../library/SafeRatioMath.sol";

import "./TokenERC20.sol";

/**
 * @title dForce's lending Base Contract
 * @author dForce
 */
abstract contract Base is TokenERC20 {
    using SafeRatioMath for uint256;

    /**
     * @notice Expects to call only once to create a new lending market.
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _controller Core controller contract address.
     * @param _interestRateModel Token interest rate model contract address.
     */
    function _initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        IControllerInterface _controller,
        IInterestRateModelInterface _interestRateModel
    ) internal virtual {
        controller = _controller;
        interestRateModel = _interestRateModel;
        accrualBlockNumber = block.number;
        borrowIndex = BASE;
        flashloanFeeRatio = 0.0008e18;
        protocolFeeRatio = 0.25e18;
        __Ownable_init();
        __ERC20_init(_name, _symbol, _decimals);
        __ReentrancyGuard_init();

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                _getChainId(),
                address(this)
            )
        );
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Check whether is a iToken contract, return false for iMSD contract.
     */
    function isiToken() external pure virtual returns (bool) {
        return true;
    }

    //----------------------------------
    //******** Main calculation ********
    //----------------------------------

    struct InterestLocalVars {
        uint256 borrowRate;
        uint256 currentBlockNumber;
        uint256 currentCash;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 borrowIndex;
        uint256 blockDelta;
        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 newTotalBorrows;
        uint256 newTotalReserves;
        uint256 newBorrowIndex;
    }

    /**
     * @notice Calculates interest and update total borrows and reserves.
     * @dev Updates total borrows and reserves with any accumulated interest.
     */
    function _updateInterest() internal virtual override {
        // When more calls in the same block, only the first one takes effect, so for the
        // following calls, nothing updates.
        if (block.number != accrualBlockNumber) {
            InterestLocalVars memory _vars;
            _vars.currentCash = _getCurrentCash();
            _vars.totalBorrows = totalBorrows;
            _vars.totalReserves = totalReserves;

            // Gets the current borrow interest rate.
            _vars.borrowRate = interestRateModel.getBorrowRate(
                _vars.currentCash,
                _vars.totalBorrows,
                _vars.totalReserves
            );
            require(
                _vars.borrowRate <= maxBorrowRate,
                "_updateInterest: Borrow rate is too high!"
            );

            // Records the current block number.
            _vars.currentBlockNumber = block.number;

            // Calculates the number of blocks elapsed since the last accrual.
            _vars.blockDelta = _vars.currentBlockNumber.sub(accrualBlockNumber);

            /**
             * Calculates the interest accumulated into borrows and reserves and the new index:
             *  simpleInterestFactor = borrowRate * blockDelta
             *  interestAccumulated = simpleInterestFactor * totalBorrows
             *  newTotalBorrows = interestAccumulated + totalBorrows
             *  newTotalReserves = interestAccumulated * reserveFactor + totalReserves
             *  newBorrowIndex = simpleInterestFactor * borrowIndex + borrowIndex
             */
            _vars.simpleInterestFactor = _vars.borrowRate.mul(_vars.blockDelta);
            _vars.interestAccumulated = _vars.simpleInterestFactor.rmul(
                _vars.totalBorrows
            );
            _vars.newTotalBorrows = _vars.interestAccumulated.add(
                _vars.totalBorrows
            );
            _vars.newTotalReserves = reserveRatio
                .rmul(_vars.interestAccumulated)
                .add(_vars.totalReserves);

            _vars.borrowIndex = borrowIndex;
            _vars.newBorrowIndex = _vars
                .simpleInterestFactor
                .rmul(_vars.borrowIndex)
                .add(_vars.borrowIndex);

            // Writes the previously calculated values into storage.
            accrualBlockNumber = _vars.currentBlockNumber;
            borrowIndex = _vars.newBorrowIndex;
            totalBorrows = _vars.newTotalBorrows;
            totalReserves = _vars.newTotalReserves;

            // Emits an `UpdateInterest` event.
            emit UpdateInterest(
                _vars.currentBlockNumber,
                _vars.interestAccumulated,
                _vars.newBorrowIndex,
                _vars.currentCash,
                _vars.newTotalBorrows,
                _vars.newTotalReserves
            );
        }
    }

    struct MintLocalVars {
        uint256 exchangeRate;
        uint256 mintTokens;
        uint256 actualMintAmout;
    }

    /**
     * @dev User deposits token into the market and `_recipient` gets iToken.
     * @param _recipient The address of the user to get iToken.
     * @param _mintAmount The amount of the underlying token to deposit.
     */
    function _mintInternal(address _recipient, uint256 _mintAmount)
        internal
        virtual
    {
        controller.beforeMint(address(this), _recipient, _mintAmount);

        MintLocalVars memory _vars;

        /**
         * Gets the current exchange rate and calculate the number of iToken to be minted:
         *  mintTokens = mintAmount / exchangeRate
         */
        _vars.exchangeRate = _exchangeRateInternal();

        // Transfers `_mintAmount` from caller to contract, and returns the actual amount the contract
        // get, cause some tokens may be charged.

        _vars.actualMintAmout = _doTransferIn(msg.sender, _mintAmount);

        // Supports deflationary tokens.
        _vars.mintTokens = _vars.actualMintAmout.rdiv(_vars.exchangeRate);

        // Mints `mintTokens` iToken to `_recipient`.
        _mint(_recipient, _vars.mintTokens);

        controller.afterMint(
            address(this),
            _recipient,
            _mintAmount,
            _vars.mintTokens
        );

        emit Mint(msg.sender, _recipient, _mintAmount, _vars.mintTokens);
    }

    /**
     * @notice This is a common function to redeem, so only one of `_redeemiTokenAmount` or
     *         `_redeemUnderlyingAmount` may be non-zero.
     * @dev Caller redeems undelying token based on the input amount of iToken or underlying token.
     * @param _from The address of the account which will spend underlying token.
     * @param _redeemiTokenAmount The number of iTokens to redeem into underlying.
     * @param _redeemUnderlyingAmount The number of underlying tokens to receive.
     */
    function _redeemInternal(
        address _from,
        uint256 _redeemiTokenAmount,
        uint256 _redeemUnderlyingAmount
    ) internal virtual {
        require(
            _redeemiTokenAmount > 0,
            "_redeemInternal: Redeem iToken amount should be greater than zero!"
        );

        controller.beforeRedeem(address(this), _from, _redeemiTokenAmount);

        _burnFrom(_from, _redeemiTokenAmount);

        /**
         * Transfers `_redeemUnderlyingAmount` underlying token to caller.
         */
        _doTransferOut(msg.sender, _redeemUnderlyingAmount);

        controller.afterRedeem(
            address(this),
            _from,
            _redeemiTokenAmount,
            _redeemUnderlyingAmount
        );

        emit Redeem(
            _from,
            msg.sender,
            _redeemiTokenAmount,
            _redeemUnderlyingAmount
        );
    }

    /**
     * @dev Caller borrows assets from the protocol.
     * @param _borrower The account that will borrow tokens.
     * @param _borrowAmount The amount of the underlying asset to borrow.
     */
    function _borrowInternal(address payable _borrower, uint256 _borrowAmount)
        internal
        virtual
    {
        controller.beforeBorrow(address(this), _borrower, _borrowAmount);

        // Calculates the new borrower and total borrow balances:
        //  newAccountBorrows = accountBorrows + borrowAmount
        //  newTotalBorrows = totalBorrows + borrowAmount
        BorrowSnapshot storage borrowSnapshot = accountBorrows[_borrower];
        borrowSnapshot.principal = _borrowBalanceInternal(_borrower).add(
            _borrowAmount
        );
        borrowSnapshot.interestIndex = borrowIndex;
        totalBorrows = totalBorrows.add(_borrowAmount);

        // Transfers token to borrower.
        _doTransferOut(_borrower, _borrowAmount);

        controller.afterBorrow(address(this), _borrower, _borrowAmount);

        emit Borrow(
            _borrower,
            _borrowAmount,
            borrowSnapshot.principal,
            borrowSnapshot.interestIndex,
            totalBorrows
        );
    }

    /**
     * @notice Please approve enough amount at first!!! If not,
     *         maybe you will get an error: `SafeMath: subtraction overflow`
     * @dev `_payer` repays `_repayAmount` tokens for `_borrower`.
     * @param _payer The account to pay for the borrowed.
     * @param _borrower The account with the debt being payed off.
     * @param _repayAmount The amount to repay (or -1 for max).
     */
    function _repayInternal(
        address _payer,
        address _borrower,
        uint256 _repayAmount
    ) internal virtual returns (uint256) {
        controller.beforeRepayBorrow(
            address(this),
            _payer,
            _borrower,
            _repayAmount
        );

        // Calculates the latest borrowed amount by the new market borrowed index.
        uint256 _accountBorrows = _borrowBalanceInternal(_borrower);

        // Transfers the token into the market to repay.
        uint256 _actualRepayAmount =
            _doTransferIn(
                _payer,
                _repayAmount > _accountBorrows ? _accountBorrows : _repayAmount
            );

        // Calculates the `_borrower` new borrow balance and total borrow balances:
        //  accountBorrows[_borrower].principal = accountBorrows - actualRepayAmount
        //  newTotalBorrows = totalBorrows - actualRepayAmount

        // Saves borrower updates.
        BorrowSnapshot storage borrowSnapshot = accountBorrows[_borrower];
        borrowSnapshot.principal = _accountBorrows.sub(_actualRepayAmount);
        borrowSnapshot.interestIndex = borrowIndex;

        totalBorrows = totalBorrows < _actualRepayAmount
            ? 0
            : totalBorrows.sub(_actualRepayAmount);

        // Defense hook.
        controller.afterRepayBorrow(
            address(this),
            _payer,
            _borrower,
            _actualRepayAmount
        );

        emit RepayBorrow(
            _payer,
            _borrower,
            _actualRepayAmount,
            borrowSnapshot.principal,
            borrowSnapshot.interestIndex,
            totalBorrows
        );

        return _actualRepayAmount;
    }

    /**
     * @dev The caller repays some of borrow and receive collateral.
     * @param _borrower The account whose borrow should be liquidated.
     * @param _repayAmount The amount to repay.
     * @param _assetCollateral The market in which to seize collateral from the borrower.
     */
    function _liquidateBorrowInternal(
        address _borrower,
        uint256 _repayAmount,
        address _assetCollateral
    ) internal virtual {
        require(
            msg.sender != _borrower,
            "_liquidateBorrowInternal: Liquidator can not be borrower!"
        );
        // According to the parameter `_repayAmount` to see what is the exact error.
        require(
            _repayAmount != 0,
            "_liquidateBorrowInternal: Liquidate amount should be greater than 0!"
        );

        // Accrues interest for collateral asset.
        Base _dlCollateral = Base(_assetCollateral);
        _dlCollateral.updateInterest();

        controller.beforeLiquidateBorrow(
            address(this),
            _assetCollateral,
            msg.sender,
            _borrower,
            _repayAmount
        );

        require(
            _dlCollateral.accrualBlockNumber() == block.number,
            "_liquidateBorrowInternal: Failed to update block number in collateral asset!"
        );

        uint256 _actualRepayAmount =
            _repayInternal(msg.sender, _borrower, _repayAmount);

        // Calculates the number of collateral tokens that will be seized
        uint256 _seizeTokens =
            controller.liquidateCalculateSeizeTokens(
                address(this),
                _assetCollateral,
                _actualRepayAmount
            );

        // If this is also the collateral, calls seizeInternal to avoid re-entrancy,
        // otherwise make an external call.
        if (_assetCollateral == address(this)) {
            _seizeInternal(address(this), msg.sender, _borrower, _seizeTokens);
        } else {
            _dlCollateral.seize(msg.sender, _borrower, _seizeTokens);
        }

        controller.afterLiquidateBorrow(
            address(this),
            _assetCollateral,
            msg.sender,
            _borrower,
            _actualRepayAmount,
            _seizeTokens
        );

        emit LiquidateBorrow(
            msg.sender,
            _borrower,
            _actualRepayAmount,
            _assetCollateral,
            _seizeTokens
        );
    }

    /**
     * @dev Transfers this token to the liquidator.
     * @param _seizerToken The contract seizing the collateral.
     * @param _liquidator The account receiving seized collateral.
     * @param _borrower The account having collateral seized.
     * @param _seizeTokens The number of iTokens to seize.
     */
    function _seizeInternal(
        address _seizerToken,
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) internal virtual {
        require(
            _borrower != _liquidator,
            "seize: Liquidator can not be borrower!"
        );

        controller.beforeSeize(
            address(this),
            _seizerToken,
            _liquidator,
            _borrower,
            _seizeTokens
        );

        /**
         * Calculates the new _borrower and _liquidator token balances,
         * that is transfer `_seizeTokens` iToken from `_borrower` to `_liquidator`.
         */
        _transfer(_borrower, _liquidator, _seizeTokens);

        // Hook checks.
        controller.afterSeize(
            address(this),
            _seizerToken,
            _liquidator,
            _borrower,
            _seizeTokens
        );
    }

    /**
     * @param _account The address whose balance should be calculated.
     */
    function _borrowBalanceInternal(address _account)
        internal
        view
        virtual
        returns (uint256)
    {
        // Gets stored borrowed data of the `_account`.
        BorrowSnapshot storage borrowSnapshot = accountBorrows[_account];

        // If borrowBalance = 0, return 0 directly.
        if (borrowSnapshot.principal == 0 || borrowSnapshot.interestIndex == 0)
            return 0;

        // Calculate new borrow balance with market new borrow index:
        //   recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
        return
            borrowSnapshot.principal.mul(borrowIndex).divup(
                borrowSnapshot.interestIndex
            );
    }

    /**
     * @dev Calculates the exchange rate from the underlying token to the iToken.
     */
    function _exchangeRateInternal() internal view virtual returns (uint256) {
        if (totalSupply == 0) {
            // This is the first time to mint, so current exchange rate is equal to initial exchange rate.
            return initialExchangeRate;
        } else {
            // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
            return
                _getCurrentCash().add(totalBorrows).sub(totalReserves).rdiv(
                    totalSupply
                );
        }
    }

    function updateInterest() external virtual returns (bool);

    /**
     * @dev EIP2612 permit function. For more details, please look at here:
     * https://eips.ethereum.org/EIPS/eip-2612
     * @param _owner The owner of the funds.
     * @param _spender The spender.
     * @param _value The amount.
     * @param _deadline The deadline timestamp, type(uint256).max for max deadline.
     * @param _v Signature param.
     * @param _s Signature param.
     * @param _r Signature param.
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_deadline >= block.timestamp, "permit: EXPIRED!");
        uint256 _currentNonce = nonces[_owner];

        bytes32 _digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            _owner,
                            _spender,
                            _getChainId(),
                            _value,
                            _currentNonce,
                            _deadline
                        )
                    )
                )
            );
        address _recoveredAddress = ecrecover(_digest, _v, _r, _s);
        require(
            _recoveredAddress != address(0) && _recoveredAddress == _owner,
            "permit: INVALID_SIGNATURE!"
        );
        nonces[_owner] = _currentNonce.add(1);
        _approve(_owner, _spender, _value);
    }

    function _getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
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
    ) external virtual;

    /**
     * @notice Users are expected to have enough allowance and balance before calling.
     * @dev Transfers asset in.
     */
    function _doTransferIn(address _sender, uint256 _amount)
        internal
        virtual
        returns (uint256);

    function exchangeRateStored() external view virtual returns (uint256);

    function borrowBalanceStored(address _account)
        external
        view
        virtual
        returns (uint256);
}