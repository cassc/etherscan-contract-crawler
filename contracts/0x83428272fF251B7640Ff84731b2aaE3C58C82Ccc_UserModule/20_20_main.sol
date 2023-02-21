// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./events.sol";
import "../../common/helpers.sol";

contract UserModule is Helpers, Events {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error UserModule__ImportAaveV3Unsafe();
    error UserModule__PositionUnsafe();
    error UserModule__NotValidDeleverageAmount();
    error UserModule__LessAstethRecieved();
    error UserModule__NotValidCollectReveuneAmount();
    error UserModule__CollectReveuneAmountIsHigh();
    error UserModule__DeleverageAmountTooHigh();

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev collects the withdraw fee on assetsAmount and emits LogWithdrawFeeCollected
    /// @param stETHAmount_ the amount of assets being withdrawn
    /// @param owner_ the owner of the assets
    /// @return the withdraw assetsAmount amount after deducting the fee
    function _collectWithdrawFee(
        uint256 stETHAmount_,
        address owner_
    ) internal returns (uint256) {
        uint256 withdrawFee = getWithdrawFee(stETHAmount_);
        revenue += withdrawFee;
        emit LogWithdrawFeeCollected(owner_, withdrawFee);
        return stETHAmount_ - withdrawFee;
    }

    /***********************************|
    |              VIEW                 |
    |__________________________________*/

    function totalAssets() public view virtual override returns (uint256) {
        return (exchangePrice * totalSupply()) / 1e18;
    }

    /***********************************|
    |              CORE                 |
    |__________________________________*/

    /// @dev See {IERC4626-deposit}.
    function deposit(
        uint256 assets_,
        address receiver_
    ) public override nonReentrant returns (uint256 shares_) {
        if (assets_ == type(uint256).max) {
            assets_ = IERC20Upgradeable(STETH_ADDRESS).balanceOf(msg.sender);
        }

        shares_ = super.deposit(assets_, receiver_);
    }

    /// @dev See {IERC4626-mint}.
    /// Note Overriden the function to have the nonReentrant modifier.
    function mint(
        uint256 shares_,
        address receiver_
    ) public override nonReentrant returns (uint256 assets_) {
        assets_ = super.mint(shares_, receiver_);
    }

    /// @dev See {IERC4626-withdraw}.
    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_
    ) public override nonReentrant returns (uint256 shares_) {
        if (assets_ == type(uint256).max) {
            assets_ = maxWithdraw(owner_);
        } else {
            require(
                assets_ <= maxWithdraw(owner_),
                "ERC4626: withdraw more than max"
            );
        }

        shares_ = previewWithdraw(assets_);

        uint256 assetsRemovingFee_ = _collectWithdrawFee(assets_, owner_);

        _withdraw(msg.sender, receiver_, owner_, assetsRemovingFee_, shares_);
        return shares_;
    }

    /// @dev See {IERC4626-redeem}.
    function redeem(
        uint256 shares_,
        address receiver_,
        address owner_
    ) public override nonReentrant returns (uint256 assetsAfterFee_) {
        if (shares_ == type(uint256).max) {
            shares_ = maxRedeem(owner_);
        } else {
            require(
                shares_ <= maxRedeem(owner_),
                "ERC4626: redeem more than max"
            );
        }

        uint256 assets_ = previewRedeem(shares_);

        // burn full shares but only withdraw assetsAfterFee
        assetsAfterFee_ = _collectWithdrawFee(assets_, owner_);
        _withdraw(msg.sender, receiver_, owner_, assetsAfterFee_, shares_);
    }

    struct ImportBalancesVariables {
        uint256 astETHBal;
        uint256 stETHBal;
        uint256 wstETHBal;
        uint256 wethBal;
        uint256 stETHAaveV3;
        uint256 wethAaveV3;
        uint256 ratioAaveV3;
        uint256 convertedStETH;
        uint256 netAssets;
    }

    struct ImportVariables {
        uint256 iTokenV1Amount;
        uint256 v1ExchangePrice;
        uint256 stEthPerWsteth;
        uint256 netAsteth;
        uint256 userNetDeposit;
        string[] targets;
        bytes[] calldatas;
        string[] flashTargets;
        bytes[] flashCalldatas;
    }

    /// @notice Importing iETH v1 to Aave V3.
    /// @param route_ Flashloan route for weth.
    /// @param deleverageWETHAmount_ The amount of weth debt to payback on Eth Vault V1.
    /// @param withdrawStETHAmount_ The amount of net stETH to withdraw from Eth Vault V1.
    /// @param receiver_ The address who will recieve the shares.
    function importPosition(
        uint256 route_,
        uint256 deleverageWETHAmount_,
        uint256 withdrawStETHAmount_,
        address receiver_
    ) public nonReentrant returns (uint256 shares_) {
        // withdrawStETHAmount_ can be 0 if we just want to deleverage
        if (deleverageWETHAmount_ == 0)
            revert UserModule__NotValidDeleverageAmount();

        ImportBalancesVariables memory before_;
        ImportBalancesVariables memory after_;
        ImportVariables memory import_;

        (import_.v1ExchangePrice, ) = LITE_VAULT_V1.getCurrentExchangePrice();

        if (withdrawStETHAmount_ == type(uint256).max) {
            import_.iTokenV1Amount = IERC20Upgradeable(IETH_TOKEN_V1).balanceOf(
                msg.sender
            );
            withdrawStETHAmount_ =
                ((import_.v1ExchangePrice * import_.iTokenV1Amount) /
                1e18) - 10;
        } else {
            import_.iTokenV1Amount = ((withdrawStETHAmount_ * 1e18) /
                import_.v1ExchangePrice);
        }

        if (deleverageWETHAmount_ > (3 * withdrawStETHAmount_))
            revert UserModule__DeleverageAmountTooHigh();

        // Directly transfering iETH v1 tokens to vault DSA.
        IERC20Upgradeable(IETH_TOKEN_V1).safeTransferFrom(
            msg.sender,
            address(vaultDSA),
            import_.iTokenV1Amount
        );

        import_.stEthPerWsteth = WSTETH_CONTRACT.stEthPerToken();

        // Aave v2 stETH collateral balance
        before_.astETHBal = IERC20Upgradeable(A_STETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );
        // stETH balance
        before_.stETHBal = IERC20Upgradeable(STETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );
        // wstETH balance
        before_.wstETHBal = IERC20Upgradeable(WSTETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );
        // wETH address
        before_.wethBal = IERC20Upgradeable(WETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Aave v3 stETH collateral and wETH debt
        (, before_.stETHAaveV3, before_.wethAaveV3, ) = getRatioAaveV3(
            import_.stEthPerWsteth
        );

        // Converting wstETH balance into stETH
        before_.convertedStETH =
            (before_.wstETHBal * import_.stEthPerWsteth) /
            1e18;

        // Net assets
        before_.netAssets =
            before_.astETHBal + // Aave v2 stETH collateral
            before_.stETHBal + // stETH balance
            before_.convertedStETH + // wstETH balance in stETH
            before_.wethBal + // wETH balance
            before_.stETHAaveV3 - // Aave v3 stETH collateral
            before_.wethAaveV3; // Aave v3 wETH debt. Assuming 1:1 stETH: wETH

        import_.targets = new string[](6);
        import_.calldatas = new bytes[](6);

        // Deleverage will give astETH 1:1 for deleveraged wETH.
        import_.targets[0] = "LITE-A";
        import_.calldatas[0] = abi.encodeWithSignature(
            "deleverageAndWithdraw(address,uint256,uint256,uint256[],uint256[])",
            IETH_TOKEN_V1,
            deleverageWETHAmount_,
            withdrawStETHAmount_,
            new uint256[](1),
            new uint256[](1)
        );

        // Converting astETH to stETH.
        import_.targets[1] = "AAVE-V2-A";
        import_.calldatas[1] = abi.encodeWithSignature(
            "withdraw(address,uint256,uint256,uint256)",
            STETH_ADDRESS,
            (deleverageWETHAmount_ - 10),
            0,
            0
        );

        // Wrapping stETH into wstETH, since Aave v3 supports wstETH collateral.
        import_.targets[2] = "WSTETH-A";
        import_.calldatas[2] = abi.encodeWithSignature(
            "deposit(uint256,uint256,uint256)",
            type(uint256).max,
            0,
            0
        );

        // Depositing wstETH collateral into Aave v3.
        import_.targets[3] = "AAVE-V3-A";
        import_.calldatas[3] = abi.encodeWithSignature(
            "deposit(address,uint256,uint256,uint256)",
            WSTETH_ADDRESS,
            type(uint256).max,
            0,
            0
        );

        // Borrowing wETH from Aave v3
        import_.targets[4] = "AAVE-V3-A";
        import_.calldatas[4] = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint256,uint256)",
            WETH_ADDRESS,
            (deleverageWETHAmount_ + 10), // Borrowing a little extra for proper payback.
            2,
            0,
            0
        );

        // Paying back wETH flashloan.
        import_.targets[5] = "INSTAPOOL-C";
        import_.calldatas[5] = abi.encodeWithSignature(
            "flashPayback(address,uint256,uint256,uint256)",
            WETH_ADDRESS,
            (deleverageWETHAmount_ + 10),
            0,
            0
        );

        {
            bytes memory encodedFlashData_ = abi.encode(
                import_.targets,
                import_.calldatas
            );

            import_.flashTargets = new string[](1);
            import_.flashCalldatas = new bytes[](1);

            import_.flashTargets[0] = "INSTAPOOL-C";
            import_.flashCalldatas[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                WETH_ADDRESS,
                deleverageWETHAmount_,
                route_,
                encodedFlashData_,
                "0x"
            );

            vaultDSA.cast(
                import_.flashTargets,
                import_.flashCalldatas,
                address(this)
            );
        }

        /// @notice If we got ETH from deleverage-and-withdraw, we wrap that to wETH.
        if (address(vaultDSA).balance > 1e15) {
            string[] memory targets_ = new string[](1);
            bytes[] memory calldatas_ = new bytes[](1);

            // Wrapping ETH => wETH;
            targets_[0] = "WETH-A";
            calldatas_[0] = abi.encodeWithSignature(
                "deposit(uint256,uint256,uint256)",
                type(uint256).max,
                0,
                0
            );

            vaultDSA.cast(targets_, calldatas_, address(this));
        }

        {
            (
                ,
                after_.stETHAaveV3,
                after_.wethAaveV3,
                after_.ratioAaveV3
            ) = getRatioAaveV3(import_.stEthPerWsteth);

            // Protocol Id of Aave v3: 2
            uint8 protocolId_ = 2;
            if (
                after_.ratioAaveV3 > maxRiskRatio[protocolId_]
            ) {
                revert UserModule__ImportAaveV3Unsafe();
            }
        }

        {
            // Aave v2 stETH collateral balance
            after_.astETHBal = IERC20Upgradeable(A_STETH_ADDRESS).balanceOf(
                address(vaultDSA)
            );
            // stETH balance
            after_.stETHBal = IERC20Upgradeable(STETH_ADDRESS).balanceOf(
                address(vaultDSA)
            );
            // wstETH balance
            after_.wstETHBal = IERC20Upgradeable(WSTETH_ADDRESS).balanceOf(
                address(vaultDSA)
            );
            // wETH balance
            after_.wethBal = IERC20Upgradeable(WETH_ADDRESS).balanceOf(
                address(vaultDSA)
            );

            // Converting wstETH balance into stETH
            after_.convertedStETH =
                (after_.wstETHBal * import_.stEthPerWsteth) /
                1e18;

            after_.netAssets =
                after_.astETHBal + // Aave v2 stETH balance
                after_.stETHBal + // stETH balance
                after_.convertedStETH + // Converted wstETH balance to stETH
                after_.wethBal + // wETH balance
                after_.stETHAaveV3 - // Aave v3 stETH collateral balance
                after_.wethAaveV3; // Aave v3 wETH debt balance. Assuming stETH: wETH as 1:1

            import_.userNetDeposit = after_.netAssets - before_.netAssets;

            // Taking 2 BPS difference         
            if (
               ((withdrawStETHAmount_ * 9998) / 10000) > import_.userNetDeposit
            ) {
                revert UserModule__LessAstethRecieved();
            }

            shares_ = convertToShares(import_.userNetDeposit);

            _mint(receiver_, shares_);
        }

        emit LogImportV1ETHVault(
            receiver_,
            shares_,
            route_,
            deleverageWETHAmount_,
            withdrawStETHAmount_,
            import_.userNetDeposit
        );
    }
    
}