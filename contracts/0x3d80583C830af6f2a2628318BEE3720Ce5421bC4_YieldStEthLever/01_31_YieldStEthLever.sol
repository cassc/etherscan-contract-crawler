// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./YieldLeverBase.sol";
import "./interfaces/IStableSwap.sol";
import "@yield-protocol/utils-v2/contracts/interfaces/IWETH9.sol";
import "@yield-protocol/yieldspace-tv/src/interfaces/IMaturingToken.sol";

interface WstEth is IERC20 {
    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}

/// @notice This contracts allows a user to 'lever up' via StEth. The concept
///     is as follows: Using Yield, it is possible to borrow Weth, which in
///     turn can be used as collateral, which in turn can be used to borrow and
///     so on.
///
///     The way to do this in practice is by first borrowing the desired debt
///     through a flash loan and using this in additon to your own collateral.
///     The flash loan is repayed using funds borrowed using your collateral.
contract YieldStEthLever is YieldLeverBase {
    using TransferHelper for IERC20;
    using TransferHelper for IWETH9;
    using TransferHelper for IMaturingToken;
    using TransferHelper for WstEth;
    using CastU128I128 for uint128;
    using CastU256U128 for uint256;
    /// @notice WEth.
    IWETH9 public constant weth =
        IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    /// @notice StEth, represents Ether stakes on Lido.
    IERC20 public constant steth =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    /// @notice WStEth, wrapped StEth, useful because StEth rebalances.
    WstEth public constant wsteth =
        WstEth(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    /// @notice Curve.fi token swapping contract between Ether and StETH.
    IStableSwap public constant stableSwap =
        IStableSwap(0x828b154032950C8ff7CF8085D841723Db2696056);
    /// @notice The ild ID for WStEth.
    bytes6 public constant ilkId = bytes6(0x303400000000);
    /// @notice The Yield Protocol Join containing WstEth.
    FlashJoin public constant wstethJoin =
        FlashJoin(0x5364d336c2d2391717bD366b29B6F351842D7F82);
    /// @notice The Yield Protocol Join containing Weth.
    FlashJoin public constant wethJoin =
        FlashJoin(0x3bDb887Dc46ec0E964Df89fFE2980db0121f0fD0);

    /// @notice Deploy this contract.
    /// @param giver_ The `Giver` contract to use.
    /// @dev The contract should never own anything in between transactions;
    ///     no tokens, no vaults. To save gas we give these tokens full
    ///     approval.
    constructor(Giver giver_) YieldLeverBase(giver_) {
        weth.approve(address(stableSwap), type(uint256).max);
        steth.approve(address(stableSwap), type(uint256).max);
        weth.approve(address(wethJoin), type(uint256).max);
        steth.approve(address(wsteth), type(uint256).max);
    }

    /// @notice Invest by creating a levered vault.
    ///
    ///     We invest `FYToken`. For this the user should have given approval
    ///     first. We borrow `borrowAmount` extra. We use it to buy Weth,
    ///     exchange it to (W)StEth, which we use as collateral. The contract
    ///     tests that at least `minCollateral` is attained in order to prevent
    ///     sandwich attacks.
    /// @param seriesId The series to create the vault for.
    /// @param borrowAmount The amount of additional liquidity to borrow.
    /// @param minCollateral The minimum amount of collateral to end up with in
    ///     the vault. If this requirement is not satisfied, the transaction
    ///     will revert.
    function invest(
        bytes6 seriesId,
        uint256 baseAmount,
        uint256 borrowAmount,
        uint256 minCollateral
    ) external payable returns (bytes12 vaultId) {
        IPool pool = IPool(ladle.pools(seriesId));
        IMaturingToken fyToken = pool.fyToken();
        if (msg.value > 0) {
            // Convert ETH to WETH
            weth.deposit{value: msg.value}();
            // Sell WETH to get fyToken
            weth.safeTransfer(address(pool), msg.value);
        } else {
            weth.safeTransferFrom(msg.sender, address(pool), baseAmount);
        }
        uint128 fyReceived = pool.sellBase(address(this), 0);
        // Build the vault
        (vaultId, ) = ladle.build(seriesId, ilkId, 0);
        // Since we know the sizes exactly, packing values in this way is more
        // efficient than using `abi.encode`.
        //
        // Encode data of
        // OperationType    1 byte      [0:1]
        // seriesId         6 bytes     [1:7]
        // vaultId          12 bytes    [7:19]
        // baseAmount       16 bytes    [19:51]
        // minCollateral    16 bytes    [51:83]
        bytes memory data = bytes.concat(
            bytes1(uint8(uint256(Operation.BORROW))),
            seriesId,
            vaultId,
            bytes16(fyReceived),
            bytes32(minCollateral)
        );
        bool success = IERC3156FlashLender(address(fyToken)).flashLoan(
            this, // Loan Receiver
            address(fyToken), // Loan Token
            borrowAmount, // Loan Amount
            data
        );
        if (!success) revert FlashLoanFailure();
        giver.give(vaultId, msg.sender);
        // We put everything that we borrowed into the vault, so there can't be
        // any FYTokens left. Check:
        require(
            IERC20(address(fyToken)).balanceOf(address(this)) == 0,
            "FYToken remains"
        );

        DataTypes.Balances memory balances = cauldron.balances(vaultId);

        emit Invested(
            vaultId,
            seriesId,
            msg.sender,
            balances.ink,
            balances.art
        );
    }

    /// @notice Divest a position.
    ///
    ///     If pre maturity, borrow liquidity tokens to repay `art` debt and
    ///     take `ink` collateral. Repay the loan and return remaining
    ///     collateral as WEth.
    ///
    ///     If post maturity, borrow WEth to pay off the debt directly. Convert
    ///     the WStEth collateral to WEth and return excess to user.
    ///
    ///     This function will take the vault from you using `Giver`, so make
    ///     sure you have given it permission to do that.
    /// @param vaultId The vault to use.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param ink The amount of collateral to recover.
    /// @param art The debt to repay.
    /// @param minWeth Revert the transaction if we don't obtain at least this
    ///     much WEth at the end of the operation.
    /// @dev It is more gas efficient to let the user supply the `seriesId`,
    ///     but it should match the pool.
    function divest(
        bytes12 vaultId,
        bytes6 seriesId,
        uint256 ink,
        uint256 art,
        uint256 minWeth
    ) external {
        // Test that the caller is the owner of the vault.
        // This is important as we will take the vault from the user.
        require(cauldron.vaults(vaultId).owner == msg.sender);

        // Give the vault to the contract
        giver.seize(vaultId, address(this));

        // Check if we're pre or post maturity.
        if (uint32(block.timestamp) < cauldron.series(seriesId).maturity) {
            IPool pool = IPool(ladle.pools(seriesId));
            IMaturingToken fyToken = pool.fyToken();
            // Repay:
            // Series is not past maturity.
            // Borrow to repay debt, move directly to the pool.
            bytes memory data = bytes.concat(
                bytes1(bytes1(uint8(uint256(Operation.REPAY)))), // [0:1]
                seriesId, // [1:7]
                vaultId, // [7:19]
                bytes32(ink), // [19:51]
                bytes32(art), // [51:83]
                bytes20(msg.sender), // [83:103]
                bytes32(minWeth) // [103:135]
            );

            bool success = IERC3156FlashLender(address(fyToken)).flashLoan(
                this, // Loan Receiver
                address(fyToken), // Loan Token
                art, // Loan Amount: borrow exactly the debt to repay.
                data
            );
            if (!success) revert FlashLoanFailure();

            // We have borrowed exactly enough for the debt and bought back
            // exactly enough for the loan + fee, so there is no balance of
            // FYToken left. Check:
            require(IERC20(address(fyToken)).balanceOf(address(this)) == 0);
            emit Divested(
                Operation.REPAY,
                vaultId,
                seriesId,
                msg.sender,
                ink,
                art
            );
        } else {
            uint256 availableWeth = weth.balanceOf(address(wethJoin)) -
                wethJoin.storedBalance();

            // Close:
            // Series is past maturity, borrow and move directly to collateral pool.
            bytes memory data = bytes.concat(
                bytes1(bytes1(uint8(uint256(Operation.CLOSE)))), // [0:1]
                seriesId, // [1:7]
                vaultId, // [7:19]
                bytes32(ink), // [19:51]
                bytes32(art) // [51:83]
            );
            // We have a debt in terms of fyWEth, but should pay back in WEth.
            // `base` is how much WEth we should pay back.
            uint128 base = cauldron.debtToBase(seriesId, art.u128());
            bool success = wethJoin.flashLoan(
                this, // Loan Receiver
                address(weth), // Loan Token
                base, // Loan Amount
                data
            );
            if (!success) revert FlashLoanFailure();

            // At this point, we have only Weth left. Hopefully: this comes
            // from the collateral in our vault!

            // There is however one caveat. If there was Weth in the join to
            // begin with, this will be billed first. Since we want to return
            // the join to the starting state, we should deposit Weth back.
            uint256 wethToDeposit = availableWeth -
                (weth.balanceOf(address(wethJoin)) - wethJoin.storedBalance());
            weth.safeTransfer(address(wethJoin), wethToDeposit);

            uint256 wethBalance = weth.balanceOf(address(this));
            if (wethBalance < minWeth) revert SlippageFailure();
            // Transferring the leftover to the user
            IERC20(weth).safeTransfer(msg.sender, wethBalance);
            emit Divested(
                Operation.CLOSE,
                vaultId,
                seriesId,
                msg.sender,
                ink,
                art
            );
        }

        // Give the vault back to the sender, just in case there is anything left
        giver.give(vaultId, msg.sender);
    }

    /// @notice Called by a flash lender, which can be `wstethJoin` or
    ///     `wethJoin` (for Weth). The primary purpose is to check conditions
    ///     and route to the correct internal function.
    ///
    ///     This function reverts if not called through a flashloan initiated
    ///     by this contract.
    /// @param initiator The initator of the flash loan, must be `address(this)`.
    /// @param borrowAmount The amount of fyTokens received.
    /// @param fee The fee that is subtracted in addition to the borrowed
    ///     amount when repaying.
    /// @param data The data we encoded for the functions. Here, we only check
    ///     the first byte for the router.
    function onFlashLoan(
        address initiator,
        address, // The token, not checked as we check the lender address.
        uint256 borrowAmount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        Operation status = Operation(uint256(uint8(data[0])));
        bytes6 seriesId = bytes6(data[1:7]);
        bytes12 vaultId = bytes12(data[7:19]);
        IMaturingToken fyToken = IPool(ladle.pools(seriesId)).fyToken();
        // Test that the lender is either a fyToken contract or the Weth Join
        // Join.
        if (msg.sender != address(fyToken) && msg.sender != address(wethJoin))
            revert FlashLoanFailure();
        // We trust the lender, so now we can check that we were the initiator.
        if (initiator != address(this)) revert FlashLoanFailure();
        // Decode the operation to execute and then call that function.
        if (status == Operation.BORROW) {
            uint128 baseAmount = uint128(bytes16(data[19:35]));
            uint256 minCollateral = uint256(bytes32(data[35:67]));
            _borrow(
                seriesId,
                vaultId,
                baseAmount,
                borrowAmount,
                fee,
                minCollateral
            );
        } else if (status == Operation.REPAY) {
            _repay(vaultId, seriesId, uint128(borrowAmount + fee), data);
        } else if (status == Operation.CLOSE) {
            uint256 ink = uint256(bytes32(data[19:51]));
            uint256 art = uint256(bytes32(data[51:83]));
            _close(vaultId, ink, art);
        }
        return FLASH_LOAN_RETURN;
    }

    /// @notice This function is called from within the flash loan. The high
    ///     level functionality is as follows:
    ///         - We have supplied and borrowed FYWeth.
    ///         - We convert it to StEth and put it in the vault.
    ///         - Against it, we borrow enough FYWeth to repay the flash loan.
    /// @param seriesId The pool (and thereby series) to borrow from.
    /// @param vaultId The vault id to put collateral into and borrow from.
    /// @param baseAmount The amount of own collateral to supply.
    /// @param borrowAmount The amount of FYWeth borrowed in the flash loan.
    /// @param fee The fee that will be issued by the flash loan.
    /// @param minCollateral The final amount of collateral to end up with, or
    ///     the function will revert. Used to prevent slippage.
    function _borrow(
        bytes6 seriesId,
        bytes12 vaultId,
        uint128 baseAmount,
        uint256 borrowAmount,
        uint256 fee,
        uint256 minCollateral
    ) internal {
        // The total amount to invest. Equal to the base plus the borrowed
        // minus the flash loan fee. The fee saved here together with the
        // borrowed amount later pays off the flash loan. This makes sure we
        // borrow exactly `borrowAmount`.
        IPool pool;
        {
            uint256 netInvestAmount = uint256(baseAmount) + borrowAmount - fee;

            // Get WEth by selling borrowed FYTokens. We don't need to check for a
            // minimum since we check that we have enough collateral later on.
            pool = IPool(ladle.pools(seriesId));
            IMaturingToken fyToken = pool.fyToken();
            fyToken.safeTransfer(address(pool), netInvestAmount);
        }
        uint256 wethReceived = pool.sellFYToken(address(this), 0);

        // Swap WEth for StEth on Curve.fi. Again, we do not check for a
        // minimum.
        // 0: WEth
        // 1: StEth
        uint256 boughtStEth = stableSwap.exchange(
            0,
            1,
            wethReceived,
            0,
            address(this)
        );

        // Wrap StEth to WStEth.
        uint128 wrappedStEth = uint128(wsteth.wrap(boughtStEth));

        // This is the amount to deposit, so we check for slippage here. As
        // long as we end up with the desired amount, it doesn't matter what
        // slippage occurred where.
        if (wrappedStEth < minCollateral) revert SlippageFailure();

        // Deposit WStEth in the vault & borrow `borrowAmount` fyToken to
        // pay back.
        wsteth.safeTransfer(address(wstethJoin), wrappedStEth);
        ladle.pour(
            vaultId,
            address(this),
            wrappedStEth.i128(),
            borrowAmount.u128().i128()
        );

        // At the end, the flash loan will take exactly `borrowedAmount + fee`,
        // so the final balance should be exactly 0.
    }

    /// @dev    - We have borrowed liquidity tokens, for which we have a debt.
    ///         - Remove `ink` collateral and repay `art` debt.
    ///         - Sell obtained `ink` StEth for WEth.
    ///         - Repay loan by buying liquidity tokens
    ///         - Send remaining WEth to user
    /// @param vaultId The vault to repay.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param borrowAmountPlusFee The amount of fyWeth that we have borrowed,
    ///     plus the fee. This should be our final balance.
    /// @param data Data containing the rest of the information
    function _repay(
        bytes12 vaultId,
        bytes6 seriesId,
        uint256 borrowAmountPlusFee, // Amount of FYToken received
        bytes calldata data
    ) internal {
        uint256 ink = uint256(bytes32(data[19:51]));
        uint256 art = uint256(bytes32(data[51:83]));
        address borrower = address(bytes20(data[83:103]));
        uint256 minWeth = uint256(bytes32(data[103:135]));
        IPool pool = IPool(ladle.pools(seriesId));
        pool.fyToken().approve(address(ladle), art);
        // Repay the vault, get collateral back.
        ladle.pour(
            vaultId,
            address(this),
            -ink.u128().i128(),
            -art.u128().i128()
        );

        // Unwrap WStEth to obtain StEth.
        uint256 stEthUnwrapped = wsteth.unwrap(ink);

        // Exchange StEth for WEth.
        // 0: WETH
        // 1: STETH
        uint256 wethReceived = stableSwap.exchange(
            1,
            0,
            stEthUnwrapped,
            1,
            // We can't send directly to the pool because the remainder is our
            // profit!
            address(this)
        );

        // Convert weth to FY to repay loan. We want `borrowAmountPlusFee`.

        uint128 wethSpent = pool.buyFYTokenPreview(borrowAmountPlusFee.u128()) +
            1; // 1 wei is added to mitigate the euler bug
        weth.safeTransfer(address(pool), wethSpent);
        pool.buyFYToken(address(this), borrowAmountPlusFee.u128(), wethSpent);

        // Send remaining weth to user
        uint256 wethRemaining;
        unchecked {
            // Unchecked: This is equal to our balance, so it must be positive.
            wethRemaining = wethReceived - wethSpent;
        }
        if (wethRemaining < minWeth) revert SlippageFailure();
        weth.safeTransfer(borrower, wethRemaining);

        // We should have exactly `borrowAmountPlusFee` fyWeth as that is what
        // we have bought. This pays back the flash loan exactly.
    }

    /// @notice Close a vault after maturity.
    ///         - We have borrowed WEth
    ///         - Use it to repay the debt and take the collateral.
    ///         - Sell it all for WEth and close position.
    /// @param vaultId The ID of the vault to close.
    /// @param ink The collateral to take from the vault.
    /// @param art The debt to repay. This is denominated in fyTokens, even
    ///     though the payment is done in terms of WEth.
    function _close(
        bytes12 vaultId,
        uint256 ink,
        uint256 art
    ) internal {
        // We have obtained Weth, exactly enough to repay the vault. This will
        // give us our WStEth collateral back.
        // data[1:13]: vaultId
        // data[29:45]: art
        ladle.close(
            vaultId,
            address(this),
            -ink.u128().i128(),
            -art.u128().i128()
        );

        // Convert wsteth to steth
        uint256 stEthUnwrapped = wsteth.unwrap(ink);

        // convert steth - weth
        // 1: STETH
        // 0: WETH
        // No minimal amount is necessary: The flashloan will try to take the
        // borrowed amount and fee, and we will check for slippage afterwards.
        stableSwap.exchange(1, 0, stEthUnwrapped, 0, address(this));

        // At the end of the flash loan, we repay in terms of WEth and have
        // used the inital balance entirely for the vault, so we have better
        // obtained it!
    }
}