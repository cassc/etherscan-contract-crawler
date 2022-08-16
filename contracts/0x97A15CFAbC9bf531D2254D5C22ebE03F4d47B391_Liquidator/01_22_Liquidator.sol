// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../admin/interfaces/IAdminRegistry.sol";
import "../interfaces/ITokenMarket.sol";
import "../interfaces/ITokenMarketRegistry.sol";
import "../../oracle/IPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "../../admin/interfaces/IProtocolRegistry.sol";
import "../../claimtoken/IClaimToken.sol";
import "./LiquidatorBase.sol";
import "../library/TokenLoanData.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract Liquidator is LiquidatorBase, SuperAdminControl {
    using TokenLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public _tokenMarket;
    address public addressProvider;

    address public govAdminRegistry;
    ITokenMarket public govTokenMarket;
    IPriceConsumer public govPriceConsumer;
    IProtocolRegistry public govProtocolRegistry;
    IClaimToken public govClaimToken;
    ITokenMarketRegistry public marketRegistry;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function initialize(
        address _liquidator1,
        address _liquidator2
    ) external initializer {
        __Ownable_init();
        //owner becomes the default admin.
        _makeDefaultApproved(_liquidator1, true);
        _makeDefaultApproved(_liquidator2, true);
    }

    function updateAddresses() external onlyOwner {
        govPriceConsumer = IPriceConsumer(
            IAddressProvider(addressProvider).getPriceConsumer()
        );
        govClaimToken = IClaimToken(
            IAddressProvider(addressProvider).getClaimTokenContract()
        );
        marketRegistry = ITokenMarketRegistry(
            IAddressProvider(addressProvider).getTokenMarketRegistry()
        );
        govAdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
        govProtocolRegistry = IProtocolRegistry(
            IAddressProvider(addressProvider).getProtocolRegistry()
        );
        govTokenMarket = ITokenMarket(
            IAddressProvider(addressProvider).getTokenMarket()
        );
    }

    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /**
     * @dev This function is used to Set Token Market Address
     *
     * @param _tokenMarketAddress Address of the Media Contract to set
     */
    function configureTokenMarket(address _tokenMarketAddress)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(
            _tokenMarketAddress != address(0),
            "GL: Invalid Media Contract Address!"
        );
        _tokenMarket = _tokenMarketAddress;
        govTokenMarket = ITokenMarket(_tokenMarket);
    }

    //modifier: only liquidators can liquidate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            this.isLiquidateAccess(liquidator),
            "GL: Not a Gov Liquidator."
        );
        _;
    }

    modifier onlyTokenMarket() {
        require(msg.sender == _tokenMarket, "GL: Unauthorized Access!");
        _;
    }

    //mapping of wallet address to track the approved claim token balances when loan is liquidated
    // wallet address lender => sunTokenAddress => balanceofSUNToken
    mapping(address => mapping(address => uint256))
        public liquidatedSUNTokenbalances;

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawStable(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event WithdrawAltcoin(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    /**
     * @dev makes _newLiquidator as a whitelisted liquidator
     * @param _newLiquidators Address of the new liquidators
     * @param _liquidatorRole access variables for _newLiquidator
     */
    function setLiquidator(
        address[] memory _newLiquidators,
        bool[] memory _liquidatorRole
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        for (uint256 i = 0; i < _newLiquidators.length; i++) {
            require(
                whitelistLiquidators[_newLiquidators[i]] != _liquidatorRole[i],
                "GL: cannot assign same"
            );
            _makeDefaultApproved(_newLiquidators[i], _liquidatorRole[i]);
        }
    }

    function _liquidateCollateralAutoSellOn(
        uint256 _loanId,
        bytes[] calldata _swapData
    ) internal {

        govTokenMarket.updateLoanStatus(
            _loanId,
            TokenLoanData.LoanStatus.LIQUIDATED
        );
        
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (, uint256 earnedAPYFee) = this.getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = marketRegistry.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            loanDetails.apyOffer,
            loanDetails.termsLengthInDays
        );
        //as we get the payback amount according to the days passed
        //let say if (days passed earned APY) is greater than the original APY,
        // then we only sent the earned apy fee amount to the lender
        // add unearned apy in stable coin to stableCoinWithdrawable mapping
        if (earnedAPYFee > apyFeeOriginal) {
            earnedAPYFee = apyFeeOriginal;
        }

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;

        //adding the unearned APY in the contract stableCoinWithdrawable mapping
        //only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += unEarnedAPYFee;

        uint256 lengthCollaterals = loanDetails.stakedCollateralTokens.length;
        uint256 callDataLength = _swapData.length;
        address aggregator1Inch = marketRegistry.getOneInchAggregator();
        require(
            callDataLength == lengthCollaterals,
            "swap call data and collateral length mismatch"
        );
        for (uint256 i = 0; i < lengthCollaterals; i++) {
            Market memory market = IProtocolRegistry(govProtocolRegistry)
                .getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            if (loanDetails.isMintSp[i]) {
                IGToken(market.gToken).burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]
                );
            }
            //inch swap
            (bool success, ) = address(aggregator1Inch).call(_swapData[i]);
            require(success, "One 1Inch Swap Failed");
           
    
        }

        uint256 autosellFeeinStable = marketRegistry.getautosellAPYFee(
            loanDetails.loanAmountInBorrowed,
            govProtocolRegistry.getAutosellPercentage(),
            loanDetails.termsLengthInDays
        );
        uint256 finalAmountToLender = (loanDetails.loanAmountInBorrowed +
            earnedAPYFee) - (autosellFeeinStable);

        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += autosellFeeinStable;

        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            finalAmountToLender
        );
        
        emit AutoSellONLiquidated(_loanId, TokenLoanData.LoanStatus.LIQUIDATED);
    }

    function _liquidateCollateralAutSellOff(uint256 _loanId) internal {

         //loan status is now liquidated
        govTokenMarket.updateLoanStatus(
            _loanId,
            TokenLoanData.LoanStatus.LIQUIDATED
        );

        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (, uint256 earnedAPYFee) = this.getTotalPaybackAmount(_loanId);
        // uint256 thresholdFee = govProtocolRegistry.getThresholdPercentage();
        uint256 apyFeeOriginal = marketRegistry.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            loanDetails.apyOffer,
            loanDetails.termsLengthInDays
        );
        //as we get the payback amount according to the days passed
        //let say if (days passed earned APY) is greater than the original APY,
        // then we only sent the earned apy fee amount to the lender
        // add unearned apy in stable coin to stableCoinWithdrawable mapping
        if (earnedAPYFee > apyFeeOriginal) {
            earnedAPYFee = apyFeeOriginal;
        }
        uint256 thresholdFeeinStable = (loanDetails.loanAmountInBorrowed *
            govProtocolRegistry.getThresholdPercentage()) / 10000;

        //threshold Fee will be cover from the platform Fee.
        uint256 lenderAmountinStable = earnedAPYFee + thresholdFeeinStable;

        //removing the thresholdFee from the stableCoinwithdrawable mapping to maintain the balances after deductions on autosell off liquidation
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] -= thresholdFeeinStable;

        //send collateral tokens to the lender
        uint256 collateralAmountinStable;

        for (
            uint256 i = 0;
            i < loanDetails.stakedCollateralTokens.length;
            i++
        ) {
            uint256 priceofCollateral;
            address claimToken = IClaimToken(govClaimToken)
                .getClaimTokenofSUNToken(loanDetails.stakedCollateralTokens[i]);

            if (govClaimToken.isClaimToken(claimToken)) {
                IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                    .safeTransfer(
                        lenderDetails.lender,
                        loanDetails.stakedCollateralAmounts[i]
                    );
                liquidatedSUNTokenbalances[lenderDetails.lender][
                    loanDetails.stakedCollateralTokens[i]
                ] += loanDetails.stakedCollateralAmounts[i];
            } else {
                Market memory market = IProtocolRegistry(govProtocolRegistry)
                    .getSingleApproveToken(
                        loanDetails.stakedCollateralTokens[i]
                    );
                if (loanDetails.isMintSp[i]) {
                    IGToken(market.gToken).burnFrom(
                        loanDetails.borrower,
                        loanDetails.stakedCollateralAmounts[i]
                    );
                }
                priceofCollateral = govPriceConsumer.getAltCoinPriceinStable(
                    loanDetails.borrowStableCoin,
                    loanDetails.stakedCollateralTokens[i],
                    loanDetails.stakedCollateralAmounts[i]
                );
                collateralAmountinStable =
                    collateralAmountinStable +
                    priceofCollateral;

                if (
                    collateralAmountinStable <= loanDetails.loanAmountInBorrowed
                ) {
                    IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                        .safeTransfer(
                            lenderDetails.lender,
                            loanDetails.stakedCollateralAmounts[i]
                        );
                } else if (
                    collateralAmountinStable > loanDetails.loanAmountInBorrowed
                ) {
                    uint256 exceedAltcoinValue = govPriceConsumer
                        .getAltCoinPriceinStable(
                            loanDetails.stakedCollateralTokens[i],
                            loanDetails.borrowStableCoin,
                            collateralAmountinStable -
                                loanDetails.loanAmountInBorrowed
                        );
                    uint256 collateralToLender = loanDetails
                        .stakedCollateralAmounts[i] - exceedAltcoinValue;

                    // adding exceed altcoin to the superadmin withdrawable collateral tokens
                    collateralsWithdrawable[address(this)][
                        loanDetails.stakedCollateralTokens[i]
                    ] += exceedAltcoinValue;

                    IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                        .safeTransfer(lenderDetails.lender, collateralToLender);
                    break;
                }
            }
        }
       
        //lender recieves the stable coins
        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            lenderAmountinStable
        );
        emit AutoSellOFFLiquidated(
            _loanId,
            TokenLoanData.LoanStatus.LIQUIDATED
        );
    }

    /**
    @dev approve collaterals to the one inch aggregator v4
    @param _collateralTokens collateral tokens
    @param _amounts collateral token amont
     */
    function approveCollateralToOneInch(
        address[] memory _collateralTokens,
        uint256[] memory _amounts
    ) external onlyLiquidatorRole(msg.sender) {
        uint256 lengthCollaterals = _collateralTokens.length;
        require(
            lengthCollaterals == _amounts.length,
            "collateral and amount length mismatch"
        );
        address oneInchAggregator = marketRegistry.getOneInchAggregator();
        for (uint256 i = 0; i < lengthCollaterals; i++) {
            IERC20(_collateralTokens[i]).approve(
                oneInchAggregator,
                _amounts[i]
            );
        }
    }
    
    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
    @param _swapData is the data getting from the 1inch swap api after approving token from smart contract
    */
    
    function liquidateLoan(
        uint256 _loanId,
        bytes[] calldata _swapData
    ) external override onlyLiquidatorRole(msg.sender) {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.ACTIVE,
            "GLM, not active"
        );

        require(this.isLiquidationPending(_loanId), "GTM: Liquidation Error");

        if (lenderDetails.autoSell) {
            _liquidateCollateralAutoSellOn(_loanId, _swapData);
        } else {
            _liquidateCollateralAutSellOff(_loanId);
        }
    }

    function addPlatformFee(address _stableCoin, uint256 _platformFee)
        external
        override
        onlyTokenMarket
    {
        stableCoinWithdrawable[address(this)][_stableCoin] += _platformFee;
    }

    function getAllLiquidators() external view returns (address[] memory) {
        return whitelistedLiquidators;
    }

    function getLiquidatorAccess(address _liquidator)
        external
        view
        returns (bool)
    {
        return whitelistLiquidators[_liquidator];
    }

    //only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GTM: Amount Invalid"
        );
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GLC: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /**
    @dev only super admin can withdraw stable coin which includes platform fee and unearned apyFee
    */
    function withdrawStable(
        address _tokenAddress,
        uint256 _amount,
        address _walletAddress
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        uint256 availableAmount = stableCoinWithdrawable[address(this)][
            _tokenAddress
        ];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        stableCoinWithdrawable[address(this)][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit WithdrawStable(_tokenAddress, _walletAddress, _amount);
    }

    /**
    @dev only super admin can withdraw exceed altcoins upon liquidation when autsell was off
    */
    function withdrawExceedAltcoins(
        address _tokenAddress,
        uint256 _amount,
        address _walletAddress
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        uint256 availableAmount = collateralsWithdrawable[address(this)][
            _tokenAddress
        ];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        collateralsWithdrawable[address(this)][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit WithdrawAltcoin(_tokenAddress, _walletAddress, _amount);
    }

    /**
    @dev functino to get the LTV of the loan amount in borrowed of the staked colletral token
    @param _loanId loan ID for which ltv is getting
     */
    function getLtv(uint256 _loanId) external view override returns (uint256) {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        //get individual collateral tokens for the loan id
        uint256[] memory stakedCollateralAmounts = loanDetails
            .stakedCollateralAmounts;
        address[] memory stakedCollateralTokens = loanDetails
            .stakedCollateralTokens;
        address borrowedToken = loanDetails.borrowStableCoin;
        return
            govPriceConsumer.calculateLTV(
                stakedCollateralAmounts,
                stakedCollateralTokens,
                borrowedToken,
                loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount
            );
    }

    /**
    @dev function to check the loan is pending for liqudation or not
    @param _loanId for which loan liquidation checking
     */
    function isLiquidationPending(uint256 _loanId)
        external
        view
        override
        returns (bool)
    {
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);

        uint256 loanTermLengthPassedInDays = (block.timestamp -
            lenderDetails.activationLoanTimeStamp) / 86400;

        // @dev get LTV
        uint256 calulatedLTV = this.getLtv(_loanId);
        //@dev the collateral is less than liquidation threshold percentage/loan term length end ok for liquidation
        // @dev loanDetails.termsLengthInDays + 1 is which we are giving extra time to the borrower to payback the collateral
        if (
            calulatedLTV <= marketRegistry.getLTVPercentage() ||
            (loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1)
        ) return true;
        else return false;
    }

    function getTotalPaybackAmount(uint256 _loanId)
        external
        view
        returns (uint256, uint256)
    {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        uint256 loanTermLengthPassedInDays = (block.timestamp -
            (
                govTokenMarket
                    .getActivatedLoanDetails(_loanId)
                    .activationLoanTimeStamp
            )) / 86400;
        uint256 earnedAPYFee = ((loanDetails.loanAmountInBorrowed *
            loanDetails.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;
        return (loanDetails.loanAmountInBorrowed + earnedAPYFee, earnedAPYFee);
    }

    /**
    @dev payback loan full by the borrower to the lender
     */
    function fullLoanPaybackEarly(uint256 _loanId, uint256 _paybackAmount)
        internal
    {
        govTokenMarket.updateLoanStatus(
            _loanId,
            TokenLoanData.LoanStatus.CLOSED
        );
        
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (uint256 finalPaybackAmounttoLender, uint256 earnedAPYFee) = this
            .getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = marketRegistry.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            loanDetails.apyOffer,
            loanDetails.termsLengthInDays
        );

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;
        //adding the unearned APY in the contract stableCoinWithdrawable mapping
        //only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += unEarnedAPYFee;

        //first transferring the payback amount from borrower to the Gov Token Market
        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransferFrom(
            loanDetails.borrower,
            address(this),
            loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount
        );
        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            finalPaybackAmounttoLender
        );
        uint256 lengthCollateral = loanDetails.stakedCollateralTokens.length;

        //loop through all staked collateral tokens.
        for (uint256 i = 0; i < lengthCollateral; i++) {
            //contract will the repay staked collateral tokens to the borrower
            IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                .safeTransfer(
                    msg.sender,
                    loanDetails.stakedCollateralAmounts[i]
                );
            Market memory market = IProtocolRegistry(govProtocolRegistry)
                .getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            IGToken gtoken = IGToken(market.gToken);
            if (
                market.tokenType == TokenType.ISVIP && loanDetails.isMintSp[i]
            ) {
                gtoken.burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]
                );
            }
        }

        govTokenMarket.updatePaybackAmount(_loanId, _paybackAmount);
        

        emit FullTokensLoanPaybacked(
            _loanId,
            msg.sender,
            lenderDetails.lender,
            loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount,
            earnedAPYFee
        );
    }

    /**
    @dev token loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount) public override {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        require(loanDetails.borrower == msg.sender, "GLM, not borrower");
        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.ACTIVE,
            "GLM, not active"
        );
        require(
            _paybackAmount > 0 &&
                _paybackAmount <= loanDetails.loanAmountInBorrowed,
            "GLM: Invalid Payback Loan Amount"
        );
        require(
            !this.isLiquidationPending(_loanId),
            "GLM: you cannot payback this time"
        );
        
        uint256 totalPayback = _paybackAmount + loanDetails.paybackAmount;
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId, _paybackAmount);
        }
        //partial loan paypack
        else {
            
            govTokenMarket.updatePaybackAmount(_loanId, _paybackAmount);

            uint256 remainingLoanAmount = loanDetails.loanAmountInBorrowed -
                totalPayback;
            uint256 newLtv = IPriceConsumer(govPriceConsumer).calculateLTV(
                loanDetails.stakedCollateralAmounts,
                loanDetails.stakedCollateralTokens,
                loanDetails.borrowStableCoin,
                remainingLoanAmount
            );
            require(
                newLtv > marketRegistry.getLTVPercentage(),
                "GLM: new LTV exceeds threshold."
            );
            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransferFrom(
                loanDetails.borrower,
                address(this),
                _paybackAmount
            );

            emit PartialTokensLoanPaybacked(
                _loanId,
                msg.sender,
                lenderDetails.lender,
                _paybackAmount
            );
        }
    }

    function getLenderSUNTokenBalances(address _lender, address _sunToken)
        public
        view
        returns (uint256)
    {
        return liquidatedSUNTokenbalances[_lender][_sunToken];
    }
}