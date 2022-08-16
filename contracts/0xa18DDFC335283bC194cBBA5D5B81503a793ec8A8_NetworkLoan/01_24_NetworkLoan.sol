// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../admin/tierLevel/interfaces/IUserTier.sol";
import "../base/NetworkLoanBase.sol";
import "../library/NetworkLoanData.sol";
import "../../oracle/IPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "../../market/pausable/PausableImplementation.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";
import "../../market/interfaces/ITokenMarketRegistry.sol";

interface ILiquidator {
    function isLiquidateAccess(address liquidator) external view returns (bool);
}

interface IProtocolRegistry {
    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getGovPlatformFee() external view returns (uint256);

    function isStableApproved(address _stable) external view returns (bool);
}

contract NetworkLoan is
    NetworkLoanBase,
    PausableImplementation,
    SuperAdminControl
{
    //Load library structs into contract
    using NetworkLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ILiquidator public Liquidator;
    IProtocolRegistry public ProtocolRegistry;
    IUserTier public TierLevel;
    IPriceConsumer public PriceConsumer;
    address public AdminRegistry;
    address public addressProvider;
    address public aggregator1Inch;
    address public marketRegistry;

    /// @dev variable which represents the loan Id
    uint256 public loanId;

    uint256 public loanActivateLimit;
    mapping(address => bool) public whitelistAddress;
    mapping(address => uint256) public loanLendLimit;

    uint256 public ltvPercentage;

    function initialize() external initializer {
        __Ownable_init();
        ltvPercentage = 125;
    }

    receive() external payable {}

    /// @dev function to set the loan Activate limit
    function setloanActivateLimit(uint256 _loansLimit)
        external
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
        emit LoanActivateLimitUpdated(_loansLimit);
    }

    function setLTVPercentage(uint256 _ltvPercentage)
        external
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_ltvPercentage > 0, "GTM: ltv percentage error");
        ltvPercentage = _ltvPercentage;
        emit LTVPercentageUpdated(_ltvPercentage);
    }

    function updateAddresses() external onlyOwner {
        Liquidator = ILiquidator(
            IAddressProvider(addressProvider).getLiquidator()
        );
        ProtocolRegistry = IProtocolRegistry(
            IAddressProvider(addressProvider).getProtocolRegistry()
        );
        TierLevel = IUserTier(IAddressProvider(addressProvider).getUserTier());
        PriceConsumer = IPriceConsumer(
            IAddressProvider(addressProvider).getPriceConsumer()
        );
        AdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
        marketRegistry = IAddressProvider(addressProvider)
            .getTokenMarketRegistry();
    }

    /// @dev set address of 1inch aggregator v4
    function set1InchAggregator(address _1inchAggregatorV4)
        external
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_1inchAggregatorV4 != address(0), "aggregator address zero");
        aggregator1Inch = _1inchAggregatorV4;
    }

    /// @dev set address of lender for the unlimited loan activation
    function setWhilelistAddress(address _lender)
        external
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        whitelistAddress[_lender] = true;
    }

    /// @dev set the address provider address
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    //modifier: only liquidators can liqudate pending liquidation calls.
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            Liquidator.isLiquidateAccess(liquidator),
            "GNM: Not a  Liquidator"
        );
        _;
    }

    /**
    /// @dev function to create Single || Multi (ERC20) Loan Offer by the BORROWER
    /// @param loanDetails {see: NetworkLoanData}

    */
    function createLoan(NetworkLoanData.LoanDetails memory loanDetails)
        public
        payable
        whenNotPaused
    {   
        require(
            ProtocolRegistry.isStableApproved(loanDetails.borrowStableCoin),
            "GTM: not approved stable coin"
        );
        
        uint256 newLoanId = _getNextLoanId();
        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetails.borrowStableCoin
        ).decimals();
        require(
            loanDetails.loanAmountInBorrowed >=
                (ITokenMarketRegistry(marketRegistry)
                    .getMinLoanAmountAllowed() * (10**stableCoinDecimals)),
            "GLM: min loan amount invalid"
        );

        require(
            msg.value >= loanDetails.collateralAmount,
            "GNM: Loan Amount Invalid"
        );
        

        uint256 ltv = this.calculateLTV(
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            loanDetails.loanAmountInBorrowed
        );
        uint256 maxLtv = this.getMaxLoanAmount(
            this.getAltCoinPriceinStable(
                loanDetails.borrowStableCoin,
                loanDetails.collateralAmount
            ),
            msg.sender
        );

        require(
            loanDetails.loanAmountInBorrowed <= maxLtv,
            "GNM: LTV not allowed."
        );
        require(
            ltv > ltvPercentage,
            "GNM: Can not create loan at liquidation level."
        );

        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);

        borrowerOffers[newLoanId] = NetworkLoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.isPrivate,
            loanDetails.isInsured,
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            NetworkLoanData.LoanStatus.INACTIVE,
            payable(msg.sender),
            0
        );

        emit LoanOfferCreated(newLoanId, borrowerOffers[newLoanId]);
        loanId++;
    }

    /**
    @dev function to adjust already created loan offer, while in inactive state
    @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    @param _newTermsLengthInDays, borrower changing the loan term in days
    @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    @param _isPrivate, boolena value of true if private otherwise false
    @param _isInsured, isinsured true or false
     */
    function loanAdjusted(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
    ) public whenNotPaused {
        require(
            borrowerOffers[_loanIdAdjusted].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, Loan cannot adjusted"
        );
        require(
            borrowerOffers[_loanIdAdjusted].borrower == msg.sender,
            "GNM, Only Borrow Adjust Loan"
        );

        uint256 ltv = this.calculateLTV(
            borrowerOffers[_loanIdAdjusted].collateralAmount,
            borrowerOffers[_loanIdAdjusted].borrowStableCoin,
            _newLoanAmountBorrowed
        );
        uint256 maxLtv = this.getMaxLoanAmount(
            this.getAltCoinPriceinStable(
                borrowerOffers[_loanIdAdjusted].borrowStableCoin,
                borrowerOffers[_loanIdAdjusted].collateralAmount
            ),
            msg.sender
        );

        require(maxLtv != 0, "GNM: not tier, cannot adjust loan");
        require(_newLoanAmountBorrowed <= maxLtv, "GNM: LTV not allowed.");
        require(
            ltv > ltvPercentage,
            "GNM: can not adjust loan to liquidation level."
        );

        borrowerOffers[_loanIdAdjusted] = NetworkLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            _isPrivate,
            _isInsured,
            borrowerOffers[_loanIdAdjusted].collateralAmount,
            borrowerOffers[_loanIdAdjusted].borrowStableCoin,
            NetworkLoanData.LoanStatus.INACTIVE,
            payable(msg.sender),
            borrowerOffers[_loanIdAdjusted].paybackAmount
        );

        emit LoanOfferAdjusted(
            _loanIdAdjusted,
            borrowerOffers[_loanIdAdjusted]
        );
    }

    /**
    @dev function to cancel the created laon offer for  type Single || Multi  Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function loanOfferCancel(uint256 _loanId) public whenNotPaused {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, Loan cannot be cancel"
        );
        require(
            borrowerOffers[_loanId].borrower == msg.sender,
            "GNM, Only Borrow can cancel"
        );

        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.CANCELLED;

        (bool success, ) = payable(msg.sender).call{
            value: borrowerOffers[_loanId].collateralAmount
        }("");
        require(success, "GNM: ETH transfer failed");

        emit LoanOfferCancel(
            _loanId,
            msg.sender,
            borrowerOffers[_loanId].loanStatus
        );
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param _loanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateLoan(
        uint256 _loanId,
        uint256 _stableCoinAmount,
        bool _autoSell
    ) public whenNotPaused {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, not inactive"
        );
        require(
            borrowerOffers[_loanId].borrower != msg.sender,
            "GNM, self activation not allowed"
        );

        if (!whitelistAddress[msg.sender]) {
            require(
                loanLendLimit[msg.sender] + 1 <= loanActivateLimit,
                "GTM: you cannot lend more loans"
            );
            loanLendLimit[msg.sender]++;
        }

        uint256 calulatedLTV = this.getLtv(_loanId);

        require(
            calulatedLTV > ltvPercentage,
            "Can not activate loan at liquidation level"
        );

        uint256 maxLoanAmount = this.getMaxLoanAmount(
            this.getAltCoinPriceinStable(
                borrowerOffers[_loanId].borrowStableCoin,
                borrowerOffers[_loanId].collateralAmount
            ),
            borrowerOffers[_loanId].borrower
        );
    
        require(maxLoanAmount != 0, "GNM: borrower not eligible, no tierLevel");
        
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[msg.sender].push(_loanId);

        if (maxLoanAmount >= borrowerOffers[_loanId].loanAmountInBorrowed) {
            require(
                borrowerOffers[_loanId].loanAmountInBorrowed ==
                    _stableCoinAmount,
                "GNM, not borrower requrested loan amount"
            );
            borrowerOffers[_loanId].loanAmountInBorrowed = _stableCoinAmount;
        } else if (
            maxLoanAmount < borrowerOffers[_loanId].loanAmountInBorrowed
        ) {
            // maxLoanAmount is now assigning in the loan Details struct
            require(
                _stableCoinAmount == maxLoanAmount,
                "GNM: loan amount not equal maxLoanAmount"
            );
            borrowerOffers[_loanId].loanAmountInBorrowed == maxLoanAmount;
        }

        uint256 apyFee = this.getAPYFee(borrowerOffers[_loanId]);
        uint256 platformFee = (borrowerOffers[loanId].loanAmountInBorrowed *
            (ProtocolRegistry.getGovPlatformFee())) / (10000);
        uint256 loanAmountAfterCut = borrowerOffers[loanId]
            .loanAmountInBorrowed - (apyFee + platformFee);

        /// @dev adding platform fee for the  Network Loan Contract in stableCoinWithdrawable,
        /// which can be withdrawable by the superadmin from the Network Loan Contract
        stableCoinWithdrawable[address(this)][
            borrowerOffers[loanId].borrowStableCoin
        ] += platformFee;

        /// @dev approving the loan amount from the front end
        /// @dev keep the APYFEE  in the contract  before  transfering the stable coins to borrower.
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransferFrom(
                msg.sender,
                address(this),
                borrowerOffers[_loanId].loanAmountInBorrowed
            );
        /// @dev loan amount sending to borrower
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransfer(borrowerOffers[_loanId].borrower, loanAmountAfterCut);

        /// @dev save the activated loan id to the lender details mapping
        activatedLoanByLenders[_loanId] = NetworkLoanData.LenderDetails({
            lender: payable(msg.sender),
            activationLoanTimeStamp: block.timestamp,
            autoSell: _autoSell
        });

        emit LoanOfferActivated(
            _loanId,
            msg.sender,
            _stableCoinAmount,
            _autoSell
        );
    }

    /// @dev function getting the total payback amount and earned apy amount to the lender
    /// @param _loanId loanId of the activated loans
    function getTotalPaybackAmount(uint256 _loanId)
        external
        view
        returns (uint256, uint256)
    {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        uint256 loanTermLengthPassed = block.timestamp -
            (activatedLoanByLenders[_loanId].activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;

        uint256 earnedAPYFee = ((loanDetails.loanAmountInBorrowed *
            loanDetails.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;

        return (loanDetails.loanAmountInBorrowed + earnedAPYFee, earnedAPYFee);
    }

    /**
    @dev payback loan full by the borrower to the lender

     */
    function fullLoanPaybackEarly(uint256 _loanId) internal {
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];

        (uint256 finalPaybackAmounttoLender, uint256 earnedAPYFee) = this
            .getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = this.getAPYFee(borrowerOffers[_loanId]);


        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;
        // adding the unearned APY in the contract stableCoinWithdrawable mapping
        // only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            borrowerOffers[_loanId].borrowStableCoin
        ] += unEarnedAPYFee;

        uint256 paybackAmount = borrowerOffers[_loanId].paybackAmount;
        borrowerOffers[_loanId].paybackAmount = finalPaybackAmounttoLender;
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.CLOSED;

        //we will first transfer the loan payback amount from borrower to the contract address.
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransferFrom(
                borrowerOffers[_loanId].borrower,
                address(this),
                borrowerOffers[_loanId].loanAmountInBorrowed -
                    paybackAmount
            );
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransfer(lenderDetails.lender, finalPaybackAmounttoLender);

        //contract will the repay staked collateral  to the borrower after receiving the loan payback amount
        (bool success, ) = payable(msg.sender).call{
            value: borrowerOffers[_loanId].collateralAmount
        }("");
        require(success, "GNM: ETH transfer failed");

        emit FullLoanPaybacked(
            _loanId,
            msg.sender,
            NetworkLoanData.LoanStatus.CLOSED
        );
    }

    /**
    @dev  loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount)
        public
        whenNotPaused
    {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        require(
            borrowerOffers[_loanId].borrower == payable(msg.sender),
            "GNM, not borrower"
        );
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.ACTIVE,
            "GNM, not active"
        );
        require(
            _paybackAmount > 0 &&
                _paybackAmount <= borrowerOffers[_loanId].loanAmountInBorrowed,
            "GNM: Invalid Loan Amount"
        );

        require(
            !this.isLiquidationPending(_loanId),
            "GNM: Loan Already Payback or Liquidated"
        );

        uint256 totalPayback = _paybackAmount + loanDetails.paybackAmount;
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId);
        } else {
            uint256 remainingLoanAmount = loanDetails.loanAmountInBorrowed -
                totalPayback;
            uint256 newLtv = this.calculateLTV(
                loanDetails.collateralAmount,
                loanDetails.borrowStableCoin,
                remainingLoanAmount
            );
            require(newLtv > ltvPercentage, "GNM: new LTV exceeds threshold.");
            borrowerOffers[_loanId].paybackAmount =
                borrowerOffers[_loanId].paybackAmount +
                _paybackAmount;
            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransferFrom(
                payable(msg.sender),
                address(this),
                _paybackAmount
            );
            
            emit PartialLoanPaybacked(
                loanId,
                _paybackAmount,
                payable(msg.sender)
            );
        }
    }

    /**
    @dev liquidate call from the  world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
    */

    function liquidateLoan(uint256 _loanId, bytes memory _swapData)
        external
        payable
        onlyLiquidatorRole(msg.sender)
    {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.ACTIVE,
            "GNM, not active, not available loan id, payback or liquidated"
        );
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];

        (, uint256 earnedAPYFee) = this.getTotalPaybackAmount(_loanId);
        uint256 apyFeeOriginal = this.getAPYFee(borrowerOffers[_loanId]);
        /// @dev as we get the payback amount according to the days passed...
        // let say if (days passed earned APY) is greater than the original APY,
        // then we only sent the earned apy fee amount to the lender
        if (earnedAPYFee > apyFeeOriginal) {
            earnedAPYFee = apyFeeOriginal;
        }

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;

        /// @dev adding the unearned APY in the contract stableCoinWithdrawable mapping
        // only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += unEarnedAPYFee;

        require(this.isLiquidationPending(_loanId), "GNM: Liquidation Error");

        if (lenderDetails.autoSell) {

            borrowerOffers[_loanId].loanStatus = NetworkLoanData
                .LoanStatus
                .LIQUIDATED;

            (bool success,) = address(aggregator1Inch).call(_swapData);
            require(success, "One 1Inch Swap Failed");

            uint256 autosellFeeinStable = this.getautosellAPYFee(
                loanDetails.loanAmountInBorrowed,
                ProtocolRegistry.getAutosellPercentage(),
                loanDetails.termsLengthInDays
            );
            uint256 finalAmountToLender = (loanDetails.loanAmountInBorrowed +
                earnedAPYFee) - (autosellFeeinStable);

            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                lenderDetails.lender,
                finalAmountToLender
            );

            emit AutoLiquidated(_loanId, NetworkLoanData.LoanStatus.LIQUIDATED);
        } else {
            //send collateral  to the lender
            borrowerOffers[_loanId].loanStatus = NetworkLoanData
                .LoanStatus
                .LIQUIDATED;

            uint256 thresholdFeeinStable = (loanDetails.loanAmountInBorrowed *
                ProtocolRegistry.getThresholdPercentage()) / 10000;
            uint256 lenderAmountinStable = earnedAPYFee + thresholdFeeinStable;
            stableCoinWithdrawable[address(this)][
                loanDetails.borrowStableCoin
            ] -= thresholdFeeinStable;

            //network loan market will the repay staked collateral  to the borrower
            uint256 collateralAmountinStable = this.getAltCoinPriceinStable(
                loanDetails.borrowStableCoin,
                loanDetails.collateralAmount
            );

            if (collateralAmountinStable <= loanDetails.loanAmountInBorrowed) {
                (bool success, ) = payable(msg.sender).call{
                    value: loanDetails.collateralAmount
                }("");
                require(success, "GNM: ETH transfer failed");
            } else if (
                collateralAmountinStable > loanDetails.loanAmountInBorrowed
            ) {
                uint256 exceedAltcoinValue = this.getStablePriceinAltcoin(
                    loanDetails.borrowStableCoin,
                    collateralAmountinStable - loanDetails.loanAmountInBorrowed
                );
                uint256 collateralToLender = loanDetails.collateralAmount -
                    exceedAltcoinValue;
                collateralsWithdrawable[address(this)] += exceedAltcoinValue;

                (bool success, ) = payable(msg.sender).call{
                    value: collateralToLender
                }("");
                require(success, "GNM: ETH transfer failed");
            }

            require(IERC20Upgradeable(loanDetails.borrowStableCoin).transfer(
                lenderDetails.lender,
                lenderAmountinStable
            ), "GNM: Lender Amount Transfer Failed");

            emit LiquidatedCollaterals(
                _loanId,
                NetworkLoanData.LoanStatus.LIQUIDATED
            );
        }
    }

    /// @dev function to get the max loan amount according to the borrower tier level
    /// @param collateralInBorrowed amount of collateral in stable coin DAI, USDT
    /// @param borrower address of the borrower who holds some tier level
    function getMaxLoanAmount(uint256 collateralInBorrowed, address borrower)
        external
        view
        returns (uint256)
    {
        TierData memory tierData = TierLevel.getTierDatabyGovBalance(borrower);
        return (collateralInBorrowed * tierData.loantoValue) / 100;
    }

    /**
    @dev function to get altcoin (native coin collateral)  amount in stable coin.
    @param _stableCoin of the altcoin
    @param _collateralAmount amount of altcoin
     */
    function getAltCoinPriceinStable(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view override returns (uint256) {
        uint256 collateralAmountinStable;

        if (
            PriceConsumer.isChainlinFeedEnabled(PriceConsumer.WETHAddress()) &&
            PriceConsumer.isChainlinFeedEnabled(_stableCoin)
        ) {
            int256 collateralChainlinkUsd = PriceConsumer
                .getNetworkPriceFromChainlinkinUSD();
            uint256 collateralUsd = (uint256(collateralChainlinkUsd) *
                _collateralAmount) / 8;
            (
                int256 priceFromChainLinkinStable,
                uint8 stableDecimals
            ) = PriceConsumer.getLatestUsdPriceFromChainlink(_stableCoin);
            collateralAmountinStable =
                collateralAmountinStable +
                ((collateralUsd / (uint256(priceFromChainLinkinStable))) *
                    (stableDecimals));
            return collateralAmountinStable;
        } else {

            collateralAmountinStable =
                collateralAmountinStable +
                (
                    PriceConsumer.getETHPriceFromDex(
                        _stableCoin,
                        PriceConsumer.WETHAddress(),
                        _collateralAmount
                    )
                );
            return collateralAmountinStable;
        }
    }

    /// @dev function to get stablecoin price in altcoin
    /// using this function is the liqudation autosell off
    function getStablePriceinAltcoin(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view returns (uint256) {
        return
            PriceConsumer.getETHPriceFromDex(
                PriceConsumer.WETHAddress(),
                _stableCoin,
                _collateralAmount
            );
    }

    /**
    @dev returns the LTV percentage of the loan amount in borrowed of the staked colletral 
    @param _loanId loan ID for which ltv we are getting
     */
    function getLtv(uint256 _loanId) external view override returns (uint256) {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];
        return
            this.calculateLTV(
                loanDetails.collateralAmount,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed - (loanDetails.paybackAmount)
            );
    }

    /**
    @dev Calculates LTV based on DEX price
    @param _stakedCollateralAmount amount of staked collateral of Network Coin
    @param _loanAmount total borrower loan amount in borrowed .
     */
    function calculateLTV(
        uint256 _stakedCollateralAmount,
        address _borrowed,
        uint256 _loanAmount
    ) external view returns (uint256) {
        uint256 priceofCollateral = this.getAltCoinPriceinStable(
            _borrowed,
            _stakedCollateralAmount
        );

        return (priceofCollateral * 100) / _loanAmount;
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
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        uint256 loanTermLengthPassedInDays = (block.timestamp -
            lenderDetails.activationLoanTimeStamp) / 86400;

        // @dev get the LTV percentage
        uint256 calulatedLTV = this.getLtv(_loanId);
        /// @dev the collateral is less than liquidation threshold percentage/loan term length end ok for liquidation
        ///  @dev loanDetails.termsLengthInDays + 1 is which we are giving extra time to the borrower to payback the collateral
        if (
            calulatedLTV <= ltvPercentage ||
            (loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1)
        ) return true;
        else return false;
    }

    /**
    @dev function to get the next loan id after creating the loan offer in  case
     */
    function _getNextLoanId() private view returns (uint256) {
        return loanId + 1;
    }

    /**
    @dev get loan details of the single or multi-
     */
    function getborrowerOffers(uint256 _loanId)
        external
        view
        returns (NetworkLoanData.LoanDetails memory)
    {
        return borrowerOffers[_loanId];
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId)
        external
        view
        returns (NetworkLoanData.LenderDetails memory)
    {
        return activatedLoanByLenders[_loanId];
    }

    /// @dev only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) external onlySuperAdmin(AdminRegistry, msg.sender) {
        uint256 availableAmount = collateralsWithdrawable[address(this)];
        require(availableAmount > 0, "GNM: collateral not available");
        require(_withdrawAmount <= availableAmount, "GNL: Amount Invalid");
        collateralsWithdrawable[address(this)] -= _withdrawAmount;
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GNM: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /// @dev only super admin can withdraw tokens
    function withdrawToken(
        address _tokenAddress,
        uint256 _amount,
        address payable _walletAddress
    ) external onlySuperAdmin(AdminRegistry, msg.sender) {
        uint256 availableAmount = stableCoinWithdrawable[address(this)][
            _tokenAddress
        ];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        stableCoinWithdrawable[address(this)][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _amount);
    }
}