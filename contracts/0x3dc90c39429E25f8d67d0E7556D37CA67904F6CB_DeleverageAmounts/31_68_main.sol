//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";

contract CoreHelpers is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Update storage.
     * @notice Internal function to update storage.
     */
    function updateStorage(uint256 exchangePrice_, uint256 newRevenue_)
        internal
    {
        if (exchangePrice_ > _lastRevenueExchangePrice) {
            _lastRevenueExchangePrice = exchangePrice_;
            _revenue += newRevenue_;
        }
    }

    /**
     * @dev Withdraw helper.
     */
    function withdrawHelper(uint256 amount_, uint256 limit_)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 transferAmt_;
        if (limit_ > amount_) {
            transferAmt_ = amount_;
            amount_ = 0;
        } else {
            transferAmt_ = limit_;
            amount_ = amount_ - limit_;
        }
        return (amount_, transferAmt_);
    }

    /**
     * @dev Withdraw final.
     */
    function withdrawFinal(uint256 amount_)
        internal
        view
        returns (uint256[] memory transferAmts_)
    {
        require(amount_ > 0, "amount-invalid");
        (
            uint256 tokenCollateralAmt_,
            ,
            ,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        ) = getVaultBalances();
        require(amount_ <= netTokenBal_, "excess-withdrawal");

        transferAmts_ = new uint256[](3);
        if (tokenVaultBal_ > 10) {
            (amount_, transferAmts_[0]) = withdrawHelper(
                amount_,
                tokenVaultBal_
            );
        }
        if (tokenDSABal_ > 10 && amount_ > 0) {
            (amount_, transferAmts_[1]) = withdrawHelper(amount_, tokenDSABal_);
        }
        if (tokenCollateralAmt_ > 10 && amount_ > 0) {
            (amount_, transferAmts_[2]) = withdrawHelper(
                amount_,
                tokenCollateralAmt_
            );
        }
    }

    /**
     * @dev Withdraw related transfers.
     */
    function withdrawTransfers(uint256 amount_, uint256[] memory transferAmts_)
        internal
    {
        if (transferAmts_[0] == amount_) return;
        uint256 totalTransferAmount_ = transferAmts_[0] +
            transferAmts_[1] +
            transferAmts_[2];
        require(amount_ == totalTransferAmount_, "transfers-not-valid");
        // batching up spells and withdrawing all the required asset from DSA to vault at once
        uint256 i;
        uint256 j;
        uint256 withdrawAmtDSA = transferAmts_[1] + transferAmts_[2];
        if (transferAmts_[2] > 0) j++;
        if (withdrawAmtDSA > 0) j++;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (transferAmts_[2] > 0) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                address(_token),
                transferAmts_[2],
                0,
                0
            );
            i++;
        }
        if (withdrawAmtDSA > 0) {
            targets_[i] = "BASIC-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                address(_token),
                withdrawAmtDSA,
                address(this),
                0,
                0
            );
        }
        _vaultDsa.cast(targets_, calldata_, address(this));
    }

    /**
     * @dev Internal function to handle withdrawals.
     */
    function withdrawInternal(
        uint256 amount_,
        address to_,
        bool afterDeleverage_
    ) internal returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        if (amount_ == type(uint256).max) {
            vtokenAmount_ = balanceOf(msg.sender);
            amount_ = (vtokenAmount_ * exchangePrice_) / 1e18;
        } else {
            vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        }

        _burn(msg.sender, vtokenAmount_);
        uint256 fee_ = (amount_ * _withdrawalFee) / 10000;
        uint256 amountAfterFee_ = amount_ - fee_;
        uint256[] memory transferAmts_ = withdrawFinal(amountAfterFee_);
        withdrawTransfers(amountAfterFee_, transferAmts_);

        (, , , , bool isOk_) = validateFinalPosition();
        require(isOk_, "position-risky");

        _token.safeTransfer(to_, amountAfterFee_);

        if (afterDeleverage_) {
            (, , , bool minGapIsOk_, ) = validateFinalPosition();
            require(minGapIsOk_, "excess-deleverage");
        }
    }

    /**
     * @dev Internal function for deleverage logics.
     */
    function deleverageInternal(uint256 amt_)
        internal
        returns (uint256 transferAmt_)
    {
        require(amt_ > 0, "not-valid-amount");
        wethContract.safeTransferFrom(msg.sender, address(_vaultDsa), amt_);

        bool isDsa_ = instaList.accountID(msg.sender) > 0;

        uint256 i;
        uint256 j = isDsa_ ? 2 : 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        targets_[0] = "AAVE-V2-A";
        calldata_[0] = abi.encodeWithSignature(
            "payback(address,uint256,uint256,uint256,uint256)",
            address(wethContract),
            amt_,
            2,
            0,
            0
        );
        if (!isDsa_) {
            transferAmt_ = amt_ + ((amt_ * _deleverageFee) / 10000);
            targets_[1] = "AAVE-V2-A";
            calldata_[1] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                address(stethContract),
                transferAmt_,
                0,
                0
            );
            i = 2;
        } else {
            transferAmt_ = amt_;
            i = 1;
        }
        targets_[i] = "BASIC-A";
        calldata_[i] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            isDsa_ ? address(astethToken) : address(stethContract),
            transferAmt_,
            msg.sender,
            0,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
    }
}

contract UserModule is CoreHelpers {
    using SafeERC20 for IERC20;

    /**
     * @dev User function to supply.
     * @param token_ address of token.
     * @param amount_ amount to supply.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        require(token_ == address(_token), "wrong token");
        require(amount_ != 0, "amount cannot be zero");
        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);
        _token.safeTransferFrom(msg.sender, address(this), amount_);
        vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);
        emit supplyLog(amount_, msg.sender, to_);
    }

    /**
     * @dev User function to withdraw.
     * @param amount_ amount to withdraw.
     * @param to_ address to send tokens to.
     * @return vtokenAmount_ amount of vTokens burnt from caller
     */
    function withdraw(uint256 amount_, address to_)
        external
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        vtokenAmount_ = withdrawInternal(amount_, to_, false);
        emit withdrawLog(amount_, msg.sender, to_);
    }

    /**
     * @dev If ratio is below then this function will allow anyone to swap from steth -> weth.
     */
    function leverage(uint256 amt_) external nonReentrant {
        require(amt_ > 0, "not-valid-amount");
        stethContract.safeTransferFrom(msg.sender, address(_vaultDsa), amt_);
        uint256 fee_ = (amt_ * _swapFee) / 10000;
        uint256 transferAmt_ = amt_ - fee_;
        _revenueEth += fee_;

        uint256 tokenBal_ = _token.balanceOf(address(this));
        if (tokenBal_ > _tokenMinLimit)
            _token.safeTransfer(address(_vaultDsa), tokenBal_);
        tokenBal_ = _token.balanceOf(address(_vaultDsa));
        uint256 i;
        uint256 j = tokenBal_ > _tokenMinLimit ? 4 : 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (tokenBal_ > _tokenMinLimit) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                address(_token),
                tokenBal_,
                0,
                0
            );
            i++;
        }
        targets_[i] = "AAVE-V2-A";
        calldata_[i] = abi.encodeWithSignature(
            "deposit(address,uint256,uint256,uint256)",
            address(stethContract),
            amt_,
            0,
            0
        );
        targets_[i + 1] = "AAVE-V2-A";
        calldata_[i + 1] = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint256,uint256)",
            address(wethContract),
            amt_,
            2,
            0,
            0
        );
        targets_[i + 2] = "BASIC-A";
        calldata_[i + 2] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            address(wethContract),
            transferAmt_,
            msg.sender,
            0,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
        (, , bool minIsOk_, , ) = validateFinalPosition();
        require(minIsOk_, "excess-leverage");

        emit leverageLog(amt_, transferAmt_);
    }

    /**
     * @dev If ratio is above then this function will allow anyone to payback WETH and withdraw astETH to msg.sender at 1:1 ratio.
     */
    function deleverage(uint256 amt_) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(amt_);
        (, , , bool minGapIsOk_, ) = validateFinalPosition();
        require(minGapIsOk_, "excess-deleverage");
        emit deleverageLog(amt_, transferAmt_);
    }

    /**
     * @dev Function to allow users to max withdraw
     */
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(deleverageAmt_);
        uint256 vtokenAmt_ = withdrawInternal(withdrawAmount_, to_, true);

        emit deleverageAndWithdrawLog(
            deleverageAmt_,
            transferAmt_,
            vtokenAmt_,
            to_
        );
    }
}