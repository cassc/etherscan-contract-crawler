// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract IUserModule {

    /**
     * @dev Returns total underlying assets of the vault.
    */
    function totalAssets() public view returns (uint256) {}

    /**
     * @dev See {IERC4626-deposit}.
     * @dev User function to deposit.
     * @param assets_ amount to supply.
     * @param receiver_ address to send iTokens to.
     * @return shares_ amount of iTokens sent to the `receiver_` address passed
    */
    function deposit(
        uint256 assets_,
        address receiver_
    ) public returns (uint256 shares_) {}

    /**
     * @dev See {IERC4626-mint}.
     * @dev User function to mint.
     * @param shares_ amount to iToken shares to mint.
     * @param receiver_ address to send iTokens to.
     * @return assets_ amount of underlying assets sent to the `receiver_` address passed
    */
    function mint(
        uint256 shares_,
        address receiver_
    ) public returns (uint256 assets_) {}

    /**
     * @dev See {IERC4626-withdraw}.
     * @dev User function to withdraw.
     * @param assets_ amount to withdraw.
     * @param receiver_ address to send withdrawn amount to.
     * @param owner_ address of owner whose shares will be burned.
     * @return shares_ amount of iTokens burned of owner.
    */
    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_
    ) public returns (uint256 shares_) {}

    /**
     * @dev See {IERC4626-redeem}.
     * @dev User function to redeem.
     * @param shares_ amount of shares to redeem.
     * @param receiver_ address to send underlying withdrawn amount to.
     * @param owner_ address of owner whose shares will be burned.
     * @return assetsAfterFee_ underlying tokens sent to the receiver after withdraw fee.
    */
    function redeem(
        uint256 shares_,
        address receiver_,
        address owner_
    ) public returns (uint256 assetsAfterFee_) {}

    /**
     * @notice Importing iETH v1 to Aave V3.
     * @dev User function to import.
     * @param deleverageWETHAmount_ The amount of weth debt to payback on Eth Vault V1.
     * @param withdrawStETHAmount_ The amount of net stETH to withdraw from Eth Vault V1.
     * @param receiver_ The address who will recieve the shares.
     * @return shares_ amount of new iTokens minted.
    */
    function importPosition(
        uint256 route_,
        uint256 deleverageWETHAmount_,
        uint256 withdrawStETHAmount_,
        address receiver_
    ) public returns (uint256 shares_) {}


    /**
     * @dev Open function to collect revenue to the `treasur` address set.
     * @param amount_ Amount of `STETH` revenue to collect.
    */
    function collectRevenue(uint256 amount_) external {}

    /**
     * @notice Sets the exchange price and revenue based on current net assets(excluding reveune)
     * @dev Open function to update exchange price.
     * @return newExchangePrice_ new exchange price
     * @return newRevenue_ if collected.
    */
    function updateExchangePrice()
        public
        returns (uint256 newExchangePrice_, uint256 newRevenue_) {}

    /// Emitted whenever a user withdraws assets and a fee is collected.
    event LogWithdrawFeeCollected(address indexed payer, uint256 indexed fee);

    /// Emitted whenever a user imports his old Eth vault position.
    event LogImportV1ETHVault(
        address indexed receiver,
        uint256 indexed iTokenAmount,
        uint256 indexed route,
        uint256 deleverageWethAmount,
        uint256 withdrawStETHAmount,
        uint256 userNetDeposit
    );

    /// Emitted whenever rebalancer refinances between 2 protocols.
    event LogCollectRevenue(uint256 amount, address indexed to);

    /// Emitted whenever exchange price is updated.
    event LogUpdateExchangePrice(
        uint256 indexed exchangePriceBefore,
        uint256 indexed exchangePriceAfter
    );

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
}

contract IRefinanceModule {

    /**
     * @notice Core function to perform refinance.
     * @param fromProtocolId_ Id of the protocol to refinance from.
     * @param toProtocolId_ Id of the protocol to refinance to.
     * @param route_ Route for flashloan. Flashloan will always be taken in `WSTETH`.
     * @param wstETHflashAmount_ Amount of flashloan.
     * @param wETHBorrowAmount_ Amount of wETH to be borrowed.
     * @param withdrawAmount_ Amount to be withdrawn. Will always be in stETH.
     * @return ratioFromProtocol_ Ratio of `from` protocol
     * @return ratioToProtocol_ Ratio of `to` protocol
    */
    function refinance(
        uint8 fromProtocolId_,
        uint8 toProtocolId_,
        uint256 route_,
        uint256 wstETHflashAmount_,
        uint256 wETHBorrowAmount_,
        uint256 withdrawAmount_
    )
        external
        returns (uint256 ratioFromProtocol_, uint256 ratioToProtocol_) {}

    /// @notice Emitted whenever rebalancer refinances between 2 protocols.
    event LogRefinance(
        uint8 indexed protocolFrom,
        uint8 indexed protocolTo,
        uint256 indexed route,
        uint256 wstETHflashAmount,
        uint256 wETHBorrowAmount,
        uint256 withdrawAmount
    );
}

contract IRebalancerModule {

    /**
     * @notice Deposits assets from the Vault to Protocol.
     * @dev Moves asset from vault
     * @param protocolId_ Protocol Id in which stETH will be deposited.
     * @param depositAmount_ stETH amount to deposit.
    */
    function vaultToProtocolDeposit(
        uint8 protocolId_,
        uint256 depositAmount_
    ) external {}

    /**
     * @notice Deposits assets from the Protocol to vault.
     * @param protocolId_ Protocol id from which amount will be withdrawn.
     * @param withdrawAmount_ stEth amount to withdraw based on the protocol.
    */
    function fillVaultAvailability(
        uint8 protocolId_,
        uint256 withdrawAmount_
    ) external {}

    /**
     * @notice Open function to sweep ideal `weth` to `stETH` in Dsa.
    */
    function sweepWethToSteth() public {}

    /**
     * @notice Open function to sweep ideal `eth` to `stETH` in Dsa.
    */
    function sweepEthToSteth() public {}

    /// Emitted when stETH is deposited from vault to protocols.
    event LogVaultToProtocolDeposit(
        uint8 indexed protocol,
        uint256 depositAmount
    );

    /// Emitted whenever stETH is deposited from protcol
    /// to vault to craete withdrawal vaialability.
    event LogFillVaultAvailability(
        uint8 indexed protocol,
        uint256 withdrawAmount
    );

    /// Emitted whenever ideal Weth DSA balance is swapped to stETH.
    event LogWethSweep(uint256 wethAmount);

    /// Emitted whenever ideal Eth DSA balance is swapped to stETH.
    event LogEthSweep(uint256 ethAmount);
}

contract ILeverageModule {

    /**
     * @notice Core function to perform leverage.
     * @param protocolId_ Id of the protocol to leverage.
     * @param route_ Route for flashloan
     * @param wstETHflashAmount_ Amount of flashloan.
     * @param wETHBorrowAmount_ Amount of weth to be borrowed.
     * @param vaults_ Addresses of old vaults to deleverage.
     * @param vaultAmounts_ Amount of `WETH` that we will payback in old vaults.
     * @param swapMode_ Mode of swap.(0 = no swap, 1 = 1Inch, 2 = direct Lido route)
     * @param unitAmount_ `WSTETH` per `WETH` conversion ratio with slippage.
     * @param oneInchData_ Bytes calldata required for `WETH` to `WSTETH` swapping.
    */
    function leverage(
        uint8 protocolId_,
        uint256 route_,
        uint256 wstETHflashAmount_,
        uint256 wETHBorrowAmount_,
        address[] memory vaults_,
        uint256[] memory vaultAmounts_,
        uint256 swapMode_,
        uint256 unitAmount_,
        bytes memory oneInchData_
    ) external {}

    /// Emitted whenever a protocol is leveraged.
    event LogLeverage(
        uint8 indexed protocol,
        uint256 indexed route,
        uint256 wstETHflashAmt,
        uint256 ethAmountBorrow,
        address[] vaults,
        uint256[] vaultAmts,
        uint256 indexed swapMode,
        uint256 unitAmt,
        uint256 vaultSwapAmt
    );
}

contract IDSAModule {
    
    /**
     * @dev Admin Spell function
     * @param to_ target address
     * @param calldata_ function calldata
     * @param value_ function msg.value
     * @param operation_ .call or .delegate. (0 => .call, 1 => .delegateCall)
    */
    function spell(
        address to_,
        bytes memory calldata_,
        uint256 value_,
        uint256 operation_
    ) external payable {}

    /**
     * @dev Admin function to add auth on DSA
     * @param auth_ new auth address for DSA
     */
    function addDSAAuth(address auth_) external {}
}

contract IAdminModule {
    
    /**
     * @notice Initializes the vault for asset_ for the ERC4626 vault.
     * @param asset_ The base ERC20 asset address for the ERC4626 vault.
     * @param secondaryAuth_ Secondary auth for vault.
     * @param treasury_ Address that collects vault's revenue.
     * @param rebalancers_ Array of rebalancers to enable.
     * @param maxRiskRatio_ Array of max risk ratio allowed for protocols.
     * @param withdrawalFeePercentage_ Initial withdrawalFeePercentage.
     * @param withdrawFeeAbsoluteMin_ Initial withdrawFeeAbsoluteMin.
     * @param revenueFeePercentage_ Initial revenueFeePercentage_.
     * @param aggrMaxVaultRatio_ Aggregated max ratio of the vault.
     * @param leverageMaxUnitAmountLimit_  Max limit (in wei) allowed for wsteth per eth unit amount.
    */
    function initialize(
        string memory name_,
        string memory symbol_,
        address asset_,
        address secondaryAuth_,
        address treasury_,
        address[] memory rebalancers_,
        uint256[] memory maxRiskRatio_,
        uint256 withdrawalFeePercentage_,
        uint256 withdrawFeeAbsoluteMin_,
        uint256 revenueFeePercentage_,
        uint256 aggrMaxVaultRatio_,
        uint256 leverageMaxUnitAmountLimit_
    ) external {}

    /**
     * @notice Vault owner and secondary wuth can update the secondary auth.
     * @param secondaryAuth_ New secondary auth to set.
    */
    function updateSecondaryAuth(
        address secondaryAuth_
    ) public {}

    /**
     * @notice Auth can add or remove allowed rebalancers
     * @param rebalancer_ the address for the rebalancer to set the flag for
     * @param isRebalancer_ flag for if rebalancer is allowed or not
    */
    function updateRebalancer(
        address rebalancer_,
        bool isRebalancer_
    ) public {}


    /**
     * @notice Auth can update the risk ratio for each protocol.
     * @param protocolId_ The Id of the protocol to update the risk ratio.
     * @param newRiskRatio_ New risk ratio of the protocol in terms of Eth and Steth, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    */
    function updateMaxRiskRatio(
        uint8[] memory protocolId_,
        uint256[] memory newRiskRatio_
    ) public {}

    /**
     * @notice Secondary auth can lower the risk ratio of any protocol.
     * @param protocolId_ The Id of the protocol to reduce the risk ratio.
     * @param newRiskRatio_ New risk ratio of the protocol in terms of Eth and Steth, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    */
    function reduceMaxRiskRatio(
        uint8[] memory protocolId_,
        uint256[] memory newRiskRatio_
    ) public {}

    /**
     * @notice Auth can update the max risk ratio set for the vault.
     * @param newAggrMaxVaultRatio_ New aggregated max ratio of the vault. Scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    */
    function updateAggrMaxVaultRatio(
        uint256 newAggrMaxVaultRatio_
    ) public {}

    /**
     * @notice Secondary auth can reduce the max risk ratio set for the vault.
     * @param newAggrMaxVaultRatio_ New aggregated max ratio of the vault. Scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    */
    function reduceAggrMaxVaultRatio(
        uint256 newAggrMaxVaultRatio_
    ) public {}

    /**
     * @notice Secondary auth can update the max wsteth per weth unit amount deviation limit.
     * @param newLimit_ New limit to set.
     */
    function updateLeverageMaxUnitAmountLimit(
        uint256 newLimit_
    ) public {}

    /**
     * @notice Auth can pause or resume all functionality of the vault.
     * @param status_ New status of the vault.
     * Note status = 1 => Vault functions are enabled; status = 2 => Vault functions are paused.
     */
    function changeVaultStatus(uint8 status_) public {}

    /**
     * @notice Auth can update the revenue and withdrawal fee percentage.
     * @param revenueFeePercent_ New revenue fee percentage, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
     * @param withdrawalFeePercent_ New withdrawal fee percentage, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
     * @param withdrawFeeAbsoluteMin_ New withdraw fee absolute. 1 ETH = 1e18, 0.01 = 1e16
     */
    function updateFees(
        uint256 revenueFeePercent_,
        uint256 withdrawalFeePercent_,
        uint256 withdrawFeeAbsoluteMin_
    ) public {}

    /**
     * @notice Auth can update the address that collected revenue.
     * @param newTreasury_ Address that will collect the revenue.
    */
    function updateTreasury(address newTreasury_) public {}

    /// @notice Emitted when rebalancer is added or removed.
    event LogUpdateRebalancer(
        address indexed rebalancer,
        bool indexed isRebalancer
    );

    /// @notice Emitted when vault's functionality is paused or resumed.
    event LogChangeStatus(uint8 indexed status);

    /// @notice Emitted when the revenue or withdrawal fee is updated.
    event LogUpdateFees(
        uint256 indexed revenueFeePercentage,
        uint256 indexed withdrawalFeePercentage,
        uint256 indexed withdrawFeeAbsoluteMin
    );

    /// @notice Emitted when the protocol's risk ratio is updated.
    event LogUpdateMaxRiskRatio(uint8 indexed protocolId, uint256 newRiskRatio);

    /// @notice Emitted whenever the address collecting the revenue is updated.
    event LogUpdateTreasury(
        address indexed oldTreasury,
        address indexed newTreasury
    );

    /// @notice Emitted when secondary auth is updated.
    event LogUpdateSecondaryAuth(
        address indexed oldSecondaryAuth,
        address indexed secondaryAuth
    );

    /// @notice Emitted when max vault ratio is updated.
    event LogUpdateAggrMaxVaultRatio(
        uint256 indexed oldAggrMaxVaultRatio,
        uint256 indexed aggrMaxVaultRatio
    );

    /// @notice Emitted when max leverage wsteth per weth unit amount is updated.
    event LogUpdateLeverageMaxUnitAmountLimit(
        uint256 indexed oldLimit,
        uint256 indexed newLimit
    );
}

contract IERC4626Functions {
    function decimals() public view returns (uint8) {}

    function asset() public view returns (address) {}

    function convertToShares(uint256 assets) public view returns (uint256 shares) {}

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {}

    function maxDeposit(address) public view returns (uint256) {}

    function maxMint(address) public view returns (uint256) {}

    function maxWithdraw(address owner) public view returns (uint256) {}

    function maxRedeem(address owner) public view returns (uint256) {}

    function previewDeposit(uint256 assets) public view returns (uint256) {}

    function previewMint(uint256 shares) public view  returns (uint256) {}

    function previewWithdraw(uint256 assets) public view returns (uint256) {}

    function previewRedeem(uint256 shares) public view returns (uint256) {}
}

contract IERC20Functions {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() public view returns (string memory) {}

    function symbol() public view returns (string memory) {}


    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {}

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view returns (uint256) {}

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) public returns (bool) {}

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view returns (uint256) {}

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) public returns (bool) {}

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {}

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {}

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {}

    
}

contract IHelpersRead {

    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsInStETH aaveV2;
        ProtocolAssetsInWstETH aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH euler;
        ProtocolAssetsInStETH morphoAaveV2;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    /**
     * @dev Returns ratio of Aave V2 in terms of `WETH` and `STETH`.
    */
    function getRatioAaveV2()
        public
        view
        returns (uint256 stEthAmount_, uint256 ethAmount_, uint256 ratio_) {}


    /**
     * @dev Returns ratio of Aave V3 in terms of `WETH` and `STETH`.
     * @param stEthPerWsteth_ Amount of stETH for one wstETH.
     * Note `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    */
    function getRatioAaveV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {}


    /**
     * @dev Returns ratio of Compound V3 in terms of `WETH` and `STETH`.
     * @param stEthPerWsteth_ Amount of stETH for one wstETH.
     * Note `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    */
    function getRatioCompoundV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {}



    /**
     * @dev Returns ratio of Euler in terms of `WETH` and `STETH`.
     * @param stEthPerWsteth_ Amount of stETH for one wstETH.
     * Note `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    */
    function getRatioEuler(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {}

    /**
     * @dev Returns ratio of Morpho Aave in terms of `WETH` and `STETH`.
    */
    function getRatioMorphoAaveV2()
        public
        view
        returns (
            uint256 stEthAmount_, // Aggreagted value of stETH in Pool and P2P
            uint256 stEthAmountPool_,
            uint256 stEthAmountP2P_,
            uint256 ethAmount_, // Aggreagted value of eth in Pool and P2P
            uint256 ethAmountPool_,
            uint256 ethAmountP2P_,
            uint256 ratio_
        )
    {}
        
    
    /**
     * @dev Returns protocol ratio.
     * @param protocolId_ Id of the protocol to get the ratio.
    */
    function getProtocolRatio(
        uint8 protocolId_
    ) public view returns (uint256 ratio_) {}


    /**
     * @dev Returns the net assets of the vault.
    */
    function getNetAssets()
        public
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - revenue))
            NetAssetsHelper memory assets_
        )
    {}

    /**
     * @notice calculates the withdraw fee: max(percentage amount, absolute amount)
     * @param stETHAmount_ the amount of assets being withdrawn
    */
    function getWithdrawFee(
        uint256 stETHAmount_
    ) public view returns (uint256) {}
}

contract IVariablesRead {

    /**
     * @dev DSA for this particular vault
    */
    function vaultDSA() public view returns (address) {}

    /**
     * @dev Max limit (in wei) allowed for wsteth per eth unit amount.
    */
    function leverageMaxUnitAmountLimit() public view returns(uint256) {}

    /**
     * @dev Secondary auth that only has the power to reduce max risk ratio.
    */
    function secondaryAuth() public view returns(address) {}

    /**
     * @dev Current exchange price.
    */
    function exchangePrice() public view returns(uint256) {}
    
    // Revenue exchange price (helps in calculating revenue).
    // Exchange price when revenue got updated last. It'll only increase overtime.
     function revenueExchangePrice() public view returns(uint256) {}
    
    /// @notice mapping to store allowed rebalancers
    ///         modifiable by auth
    mapping(address => bool) public isRebalancer;
    
    //Mapping of protocol id => max risk ratio, scaled to factor 4,
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    mapping(uint8 => uint256) public maxRiskRatio;
    
    //Max aggregated risk ratio of the vault that can be reached, scaled to factor 4.
    function aggrMaxVaultRatio() public view returns(uint256) {}
    
    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the percentage in 1e6
    /// this number is given in 1e4, i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    /// modifiable by owner
    function withdrawalFeePercentage() public view returns(uint256) {}
    
    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the absolute minimum
    /// this number is given in decimals for the respective asset of the vault.
    /// modifiable by owner
    function withdrawFeeAbsoluteMin() public view returns(uint256) {}
    
    function revenueFeePercentage() public view returns(uint256) {}
    
    /// @notice Stores profit revenue and withdrawal fees collected.
    function revenue() public view returns(uint256) {}
    
    /// @notice Revenue will be transffered to this address upon collection.
    function treasury() public view returns(address) {}



}

contract VaultDummyImplementation is
    IUserModule,
    IRefinanceModule,
    IRebalancerModule,
    ILeverageModule,
    IDSAModule,
    IAdminModule,
    IERC4626Functions,
    IERC20Functions,
    IHelpersRead,
    IVariablesRead
{
    receive() external payable {}
}