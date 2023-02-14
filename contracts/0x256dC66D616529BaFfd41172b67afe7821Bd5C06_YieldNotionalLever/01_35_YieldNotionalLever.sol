// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastI128U128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256I256.sol";
import "@yield-protocol/vault-v2/contracts/other/notional/ERC1155.sol";
import "@yield-protocol/vault-v2/contracts/other/notional/interfaces/INotionalJoin.sol";
import "@yield-protocol/utils-v2/contracts/interfaces/IWETH9.sol";
import "./YieldLeverBase.sol";
import "./NotionalTypes.sol";

/// @title A contract to help users build levered position on notional
/// @author iamsahu
/// @notice Each external function has the details on how this works
contract YieldNotionalLever is YieldLeverBase, ERC1155TokenReceiver {
    using TransferHelper for IERC20;
    using TransferHelper for IFYToken;
    using CastU128I128 for uint128;
    using CastI128U128 for int128;
    using CastU256U128 for uint256;
    using CastU256I256 for uint256;
    Notional constant notional =
        Notional(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

    /// @notice Struct to store fcash related information for an ilk
    /// @param join The join of the underlying asset
    /// @param maturity The maturity date of fCash
    /// @param currencyId The id used for the fCash in notional
    /// @dev We choose to store join redundantly as it is cheaper to load
    ///     than to use an if statement to choose based on the currency id
    struct IlkInfo {
        FlashJoin join;
        uint40 maturity;
        uint16 currencyId;
    }

    /// @notice stores the information of the enabled ilks on the lever
    mapping(bytes6 => IlkInfo) public ilkInfo;

    constructor(Giver giver_) YieldLeverBase(giver_) {
        notional.setApprovalForAll(address(ladle), true);
        //USDC
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(
            address(notional),
            type(uint256).max
        );
        //DAI
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(
            address(notional),
            type(uint256).max
        );
        // WETH
        weth.approve(address(notional), type(uint256).max);
    }

    /// @notice Invest by creating a levered vault.
    ///         Here are the steps for USDC/DAI:
    ///         1. Transfer `baseAmount` of USDC/DAI from the user
    ///         2. Flashloan `borrowAmount` of USDC/DAI from the join
    ///         3. Deposit USDC/DAI into notional market to get relevant fCash
    ///         4. Pour the received fCash to borrow fyToken
    ///         5. Buy base using the borrowed fyToken to pay back the flash loan
    ///         Here are the steps for ETH:
    ///         1. Flashloan `borrowAmount` of WETH from the join
    ///         2. Withdraw WETH to get ETH
    ///         3. Deposit ETH into notional market to get relevant fCash
    ///         4. Pour the received fCash to borrow fyToken
    ///         5. Buy base using the borrowed fyToken to pay back the flash loan
    /// @param baseAmount The amount of own liquidity to supply.
    /// @param borrowAmount The amount of additional liquidity to borrow.
    /// @param seriesId The series to create the vault for.
    function invest(
        bytes6 seriesId,
        bytes6 ilkId,
        uint256 baseAmount,
        uint256 borrowAmount
    ) external payable returns (bytes12 vaultId) {
        (vaultId, ) = ladle.build(seriesId, ilkId, 0);

        if (ilkInfo[ilkId].currencyId == 0) {
            INotionalJoin notionalJoin = INotionalJoin(
                address(ladle.joins(ilkId))
            );
            notional.setApprovalForAll(address(notionalJoin), true);
            IlkInfo storage ilkInfoTemp = ilkInfo[ilkId];
            ilkInfoTemp.join = FlashJoin(notionalJoin.underlyingJoin());
            ilkInfoTemp.maturity = notionalJoin.maturity();
            ilkInfoTemp.currencyId = notionalJoin.currencyId();
        }
        // Since we know the sizes exactly, packing values in this way is more
        // efficient than using `abi.encode`.
        //
        // Encode data of
        // OperationType    1 byte      [0:1]
        // seriesId         6 bytes     [1:7]
        // vaultId          12 bytes    [7:19]
        // ilkId            6 bytes     [19:25]
        // baseAmount       32 bytes    [25:57]
        bytes memory data = bytes.concat(
            bytes1(uint8(uint256(Operation.BORROW))),
            seriesId,
            ilkId,
            vaultId,
            bytes32(baseAmount)
        );
        bool success;
        IlkInfo memory info = ilkInfo[ilkId];
        IERC20 token = IERC20(info.join.asset());

        if (ilkInfo[ilkId].currencyId != 1) {
            // Since notional accepts only ETH we don't have to do any transfer from the user
            // Transfer the underlying USDC/DAI already approved by the user
            token.safeTransferFrom(msg.sender, address(this), baseAmount);
        } else {
            if (msg.value == 0) {
                // Transfer weth from user
                token.safeTransferFrom(msg.sender, address(this), baseAmount);
                // Convert weth to eth
                weth.withdraw(baseAmount);
            }
        }

        // Flash loan the underlying USDC/DAI/WETH
        success = info.join.flashLoan(this, address(token), borrowAmount, data);
        if (!success) revert FlashLoanFailure();
        giver.give(vaultId, msg.sender);
        // The leftover assets originated in the join, so just deposit them back
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) token.safeTransfer(address(info.join), balance);
        DataTypes.Balances memory balances = cauldron.balances(vaultId);

        emit Invested(
            vaultId,
            seriesId,
            msg.sender,
            balances.ink,
            balances.art
        );
    }

    /// @notice Unwind a position.
    ///
    ///     If pre maturity, borrow liquidity tokens to repay `art` debt and
    ///     take `ink` collateral. Here are the steps:
    ///     1. Flash loan debt amount of fyToken
    ///     2. Repay the debt to get collateral (fCash)
    ///     3. Use fCash to get the underlying(USDC/DAI/ETH) in return from Notional
    ///         3.1 In case of ETH convert it into WETH
    ///     4. Use the received underlying to buyFYToken equivalent to the amount which was flash loaned
    ///
    ///     If post maturity, borrow USDC/DAI/WETH to pay off the debt directly. Here are the steps
    ///     1. Flash loan amount of USDC/DAI/WETH equivalent to the debt
    ///     2. Pay the debt to get collateral in return which is used to payback the flash loan
    ///
    ///     This function will take the vault from you using `Giver`, so make
    ///     sure you have given it permission to do that.
    /// @param vaultId The vault to use.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param ilkId Id of the Ilk
    /// @param ink The amount of collateral to recover.
    /// @param art The debt to repay.
    /// @param minOut The minimum amount of token to get out of the contract.
    /// @dev It is more gas efficient to let the user supply the `seriesId`,
    ///     but it should match the pool.
    function divest(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId,
        uint256 ink,
        uint256 art,
        uint256 minOut
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
                ilkId, // [7:13]
                vaultId, // [13:25]
                bytes32(ink), // [25:57]
                bytes32(art), // [57:89]
                bytes32(minOut), // [89:121]
                bytes20(msg.sender) // [121:141]
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
            require(fyToken.balanceOf(address(this)) == 0);

            emit Divested(
                Operation.REPAY,
                vaultId,
                seriesId,
                msg.sender,
                ink,
                art
            );
        } else {
            // Close:
            // Series is not past maturity.
            // Borrow to repay debt, move directly to the pool.
            bytes memory data = bytes.concat(
                bytes1(bytes1(uint8(uint256(Operation.CLOSE)))), // [0:1]
                seriesId, // [1:7]
                ilkId, // [7:13]
                vaultId, // [13:25]
                bytes32(ink), // [25:57]
                bytes32(art) // [57:89]
            );
            bool success;
            IlkInfo memory info = ilkInfo[ilkId];
            IERC20 token = IERC20(info.join.asset());
            success = info.join.flashLoan(
                this, // Loan Receiver
                address(token), // Loan Token
                art, // Loan Amount: borrow exactly the debt to repay.
                data
            );

            if (!success) revert FlashLoanFailure();

            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(msg.sender, balance);

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

    /// @notice Called by a flash lender, which can be `usdcJoin` or
    ///     `daiJoin` or 'fyToken`. The primary purpose is to check conditions
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
        address token, // The token, not checked as we check the lender address.
        uint256 borrowAmount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        Operation status = Operation(uint256(uint8(data[0])));
        bytes6 seriesId = bytes6(data[1:7]);
        bytes6 ilkId = bytes6(data[7:13]);
        bytes12 vaultId = bytes12(data[13:25]);

        // Test that the lender is either a fyToken contract or the join.
        if (
            msg.sender != address(IPool(ladle.pools(seriesId)).fyToken()) &&
            msg.sender != address(ladle.joins(cauldron.series(seriesId).baseId))
        ) revert FlashLoanFailure();
        // We trust the lender, so now we can check that we were the initiator.
        if (initiator != address(this)) revert FlashLoanFailure();
        // Decode the operation to execute and then call that function.
        if (status == Operation.BORROW) {
            uint256 baseAmount = uint256(bytes32(data[25:57]));
            IERC20(token).approve(msg.sender, borrowAmount + fee);
            _borrow(vaultId, seriesId, ilkId, borrowAmount, fee, baseAmount);
        } else if (status == Operation.REPAY) {
            IERC20(token).approve(msg.sender, borrowAmount + fee);
            _repay(vaultId, seriesId, ilkId, borrowAmount + fee, data);
        } else if (status == Operation.CLOSE) {
            uint256 ink = uint256(bytes32(data[25:57]));
            uint256 art = uint256(bytes32(data[57:89]));
            // borrowAmount is twice as we need approval for closing the debt position & closing the flash loan
            IERC20(token).approve(
                msg.sender,
                borrowAmount + borrowAmount + fee
            );
            _close(vaultId, ink, art);
        }
        return FLASH_LOAN_RETURN;
    }

    /// @notice This function is called from within the flash loan. The high
    ///     level functionality is as follows:
    ///         1. We have supplied dai/usdc/eth & flash loaned dai/usdc/weth
    ///         2. We deposit it into Notional to get fCash and put it in the vault.
    ///             2.1 In case of WETH we first convert it to ETH before depositing it into Notional
    ///         3. Against it, we borrow enough fyDai or fyUSDC to repay the flash loan.
    /// @param vaultId The vault id to put collateral into and borrow from.
    /// @param seriesId The pool (and thereby series) to borrow from.
    /// @param ilkId Id of the Ilk
    /// @param borrowAmount The amount of DAI/USDC borrowed in the flash loan.
    /// @param fee The fee that will be issued by the flash loan.
    /// @param baseAmount The amount of own collateral to supply.
    function _borrow(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId,
        uint256 borrowAmount,
        uint256 fee,
        uint256 baseAmount
    ) internal {
        uint88 fCashAmount;
        // Reuse variable to denote how much to invest. Done to prevent stack
        // too deep error while being gas efficient.
        unchecked {
            baseAmount += (borrowAmount - fee);

            bytes32 encodedTrade;

            IlkInfo memory ilkIdInfo = ilkInfo[ilkId];
            // Deposit into notional to get the fCash

            BalanceActionWithTrades[]
                memory actions = new BalanceActionWithTrades[](1);
            actions[0] = BalanceActionWithTrades({
                actionType: DepositActionType.DepositUnderlying, // Deposit underlying, not cToken
                currencyId: ilkIdInfo.currencyId,
                depositActionAmount: baseAmount, // total to invest
                withdrawAmountInternalPrecision: 0,
                withdrawEntireCashBalance: false, // Return all residual cash to lender
                redeemToUnderlying: false, // Convert cToken to token
                trades: new bytes32[](1)
            });

            (fCashAmount, , encodedTrade) = notional.getfCashLendFromDeposit(
                ilkIdInfo.currencyId,
                baseAmount, // total to invest
                ilkIdInfo.maturity,
                0,
                block.timestamp,
                true
            );

            actions[0].trades[0] = encodedTrade;
            if (ilkIdInfo.currencyId == 1) {
                // Converting WETH to ETH since notional accepts ETH
                weth.withdraw(borrowAmount);

                notional.batchBalanceAndTradeAction{value: baseAmount}(
                    address(this),
                    actions
                );
            } else {
                notional.batchBalanceAndTradeAction(address(this), actions);
            }
        }
        IPool pool = IPool(ladle.pools(seriesId));

        uint128 maxFyOut = pool.buyBasePreview(borrowAmount.u128() + 5);

        ladle.pour(
            vaultId,
            address(pool),
            (uint128(fCashAmount)).i128(),
            (maxFyOut).i128()
        );

        pool.buyBase(address(this), borrowAmount.u128() + 5, maxFyOut);
    }

    /// @param vaultId The vault to repay.
    /// @notice Here are the steps:
    ///         1. Use the flash loaned fyToken to repay the debt & withdraw collateral (fCash)
    ///         2. Trade the collateral(fCash) on Notional to get the underlying(USDC/DAI/ETH) in return
    ///            2.1 In case of ETH we convert it to WETH before buying fyToken
    ///         3. Buy fyToken using the received underlying to repay the flash loan
    ///         4. Transfer remaining underlying to the user
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param ilkId Id of the Ilk
    /// @param borrowPlusFee The amount of fyDai/fyUsdc/fyETH that we have borrowed,
    ///     plus the fee. This should be our final balance.
    function _repay(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId,
        uint256 borrowPlusFee, // Amount of FYToken received
        bytes calldata data
    ) internal {
        // Repay the vault, get collateral back.
        IlkInfo memory ilkIdInfo = ilkInfo[ilkId];

        uint256 ink = uint256(bytes32(data[25:57]));
        uint256 art = uint256(bytes32(data[57:89]));
        cauldron.series(seriesId).fyToken.approve(address(ladle), art);

        ladle.pour(
            vaultId,
            address(this),
            -ink.u128().i128(),
            -art.u128().i128()
        );

        // Trade fCash to receive USDC/DAI
        BalanceActionWithTrades[]
            memory actions = new BalanceActionWithTrades[](1);
        actions[0] = BalanceActionWithTrades({
            actionType: DepositActionType.None,
            currencyId: ilkIdInfo.currencyId,
            depositActionAmount: 0,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true,
            trades: new bytes32[](1)
        });

        (, , , bytes32 encodedTrade) = notional.getPrincipalFromfCashBorrow(
            ilkIdInfo.currencyId,
            ink,
            ilkIdInfo.maturity,
            0,
            block.timestamp
        );

        actions[0].trades[0] = encodedTrade;

        notional.batchBalanceAndTradeAction(address(this), actions);

        // buyFyToken
        IPool pool = IPool(ladle.pools(seriesId));

        uint128 baseToSell = pool.buyFYTokenPreview(borrowPlusFee.u128()) + 1;
        IERC20 token = IERC20(ilkIdInfo.join.asset());
        // Since our pools accept only WETH
        if (ilkIdInfo.currencyId == 1) weth.deposit{value: baseToSell}();
        token.safeTransfer(address(pool), baseToSell);

        pool.buyFYToken(address(this), borrowPlusFee.u128(), baseToSell);

        uint256 minOut = uint256(bytes32(data[89:121]));
        address borrower = address(bytes20(data[121:141]));
        uint256 balance = token.balanceOf(address(this));
        require(balance >= minOut, "too few tokens obtained");
        token.safeTransfer(borrower, balance);
    }

    /// @notice Close a vault after maturity.
    ///         Use the flashloaned USDC/DAI/WETH to close the position and payback the flash loan
    /// @param vaultId The ID of the vault to close.
    /// @param ink The collateral to take from the vault.
    /// @param art The debt to repay. This is denominated in fyTokens, even
    ///     though the payment is done in terms of USDC/DAI,WETH
    function _close(
        bytes12 vaultId,
        uint256 ink,
        uint256 art
    ) internal {
        ladle.close(
            vaultId,
            address(this),
            -ink.u128().i128(),
            -art.u128().i128()
        );
    }

    /// @dev Called by the sender after a transfer to verify it was received. Ensures only `id` tokens are received.
    function onERC1155Received(
        address,
        address,
        uint256, // _id,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @dev Called by the sender after a batch transfer to verify it was received. Ensures only `id` tokens are received.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata, // _ids,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
}