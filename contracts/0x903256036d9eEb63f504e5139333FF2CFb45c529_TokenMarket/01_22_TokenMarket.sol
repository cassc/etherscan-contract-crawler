// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../base/TokenMarketBase.sol";
import "../../oracle/IPriceConsumer.sol";
import "../../claimtoken/IClaimToken.sol";
import "../interfaces/ITokenMarketRegistry.sol";
import "../library/TokenLoanData.sol";
import "../pausable/PausableImplementation.sol";
import "../../addressprovider/IAddressProvider.sol";
import "../../admin/tierLevel/interfaces/IUserTier.sol";

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface ILiquidator {
    function addPlatformFee(address _stableCoin, uint256 _platformFee) external;

    function isLiquidateAccess(address liquidator) external view returns (bool);
}

contract TokenMarket is TokenMarketBase, PausableImplementation {
    //Load library structs into contract
    using TokenLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev state variables for the token market

    address public Liquidator;
    address public TierLevel;
    address public PriceConsumer;
    address public ClaimToken;
    address public marketRegistry;
    address public addressProvider;
    uint256 public loanId;

    mapping(address => uint256) public loanLendLimit;

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @dev this function update all the address that are needed to run the token market
    function updateAddresses() external onlyOwner {
        Liquidator = IAddressProvider(addressProvider).getLiquidator();
        TierLevel = IAddressProvider(addressProvider).getUserTier();
        PriceConsumer = IAddressProvider(addressProvider).getPriceConsumer();
        ClaimToken = IAddressProvider(addressProvider).getClaimTokenContract();
        marketRegistry = IAddressProvider(addressProvider)
            .getTokenMarketRegistry();
    }

    /// @dev function to set the address provider contract
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }
    
    modifier onlySuperAdmin(address _admin) {
        require(
            ITokenMarketRegistry(marketRegistry).isSuperAdminAccess(_admin),
            "GTM: Not a  Super Admin."
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        require(
            ILiquidator(Liquidator).isLiquidateAccess(_admin),
            "GTM: not liquidator"
        );
        _;
    }

    /// @dev receive native token in the contract
    receive() external payable {}

    /// @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER
    /// @param loanDetails loan details borrower is making for the loan
    function createLoan(TokenLoanData.LoanDetails memory loanDetails)
        public
        whenNotPaused
    {
        require(
            ITokenMarketRegistry(marketRegistry).isStableApproved(
                loanDetails.borrowStableCoin
            ),
            "GTM: not approved stable coin"
        );

        uint256 newLoanId = loanId + 1;
        uint256 collateralTokenLength = loanDetails
            .stakedCollateralTokens
            .length;
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
            loanDetails.stakedCollateralTokens.length ==
                loanDetails.stakedCollateralAmounts.length &&
                loanDetails.stakedCollateralTokens.length ==
                loanDetails.isMintSp.length,
            "GLM: Tokens and amounts length must be same"
        );

        if (TokenLoanData.LoanType.SINGLE_TOKEN == loanDetails.loanType) {
            //for single tokens collateral length must be one.
            require(
                collateralTokenLength == 1,
                "GLM: Multi-tokens not allowed in SINGLE TOKEN loan type."
            );
        }

        require(
            checkApprovalCollaterals(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.isMintSp,
                loanDetails.borrower
            ),
            "Collateral Approval Error"
        );

        (
            uint256 collateralLTVPercentage,
            ,
            uint256 collatetralInBorrowed
        ) = this.getltvCalculations(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed,
                loanDetails.borrower
            );
        require(
            collateralLTVPercentage >
                ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
            "GLM: Can not create loan at liquidation level."
        );

        uint256 response = IUserTier(TierLevel).isCreateLoanTokenUnderTier(
            msg.sender,
            loanDetails.loanAmountInBorrowed,
            collatetralInBorrowed,
            loanDetails.stakedCollateralTokens
        );
        require(response == 200, "GLM: Invalid Tier Loan");

        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);
        //loop through all staked collateral tokens.
        loanOffersToken[newLoanId] = TokenLoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.loanType,
            loanDetails.isPrivate,
            loanDetails.isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            0,
            loanDetails.isMintSp
        );

        emit LoanOfferCreatedToken(newLoanId, loanOffersToken[newLoanId]);
        loanId++;
    }

    /// @dev function to adjust already created loan offer, while in inactive state
    /// @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    /// @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    /// @param _newTermsLengthInDays, borrower changing the loan term in days
    /// @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    /// @param _isPrivate, boolena value of true if private otherwise false
    /// @param _isInsured, isinsured true or false

    function loanAdjusted(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
    ) public whenNotPaused {
        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[
            _loanIdAdjusted
        ];

        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot adjusted"
        );
        require(
            loanDetails.borrower == msg.sender,
            "GLM, Only Borrow Adjust Loan"
        );

        (
            uint256 collateralLTVPercentage,
            ,
            uint256 collatetralInBorrowed
        ) = this.getltvCalculations(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed,
                loanDetails.borrower
            );
        
        uint256 response = IUserTier(TierLevel).isCreateLoanTokenUnderTier(
            msg.sender,
            _newLoanAmountBorrowed,
            collatetralInBorrowed,
            loanDetails.stakedCollateralTokens
        );
        require(response == 200, "GLM: Invalid Tier Loan");
        require(
            collateralLTVPercentage >
                ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
            "GLM: can not adjust loan at liquidation level."
        );

        loanDetails = TokenLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            loanDetails.loanType,
            _isPrivate,
            _isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            0,
            loanDetails.isMintSp
        );

        loanOffersToken[_loanIdAdjusted] = loanDetails;

        emit LoanOfferAdjustedToken(_loanIdAdjusted, loanDetails);
    }

    /// @dev function to cancel the created laon offer for token type Single || Multi Token Colletrals
    /// @param _loanId loan Id which is being cancelled/removed, will update the status of the loan details from the mapping

    function loanOfferCancel(uint256 _loanId) public whenNotPaused {
        require(
            loanOffersToken[_loanId].loanStatus ==
                TokenLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot be cancel"
        );
        require(
            loanOffersToken[_loanId].borrower == msg.sender,
            "GLM, Only Borrow can cancel"
        );

        loanOffersToken[_loanId].loanStatus = TokenLoanData
            .LoanStatus
            .CANCELLED;
        emit LoanOfferCancelToken(
            _loanId,
            msg.sender,
            loanOffersToken[_loanId].loanStatus
        );
    }

    /// @dev cancel multiple loans by liquidator
    /// @dev function to cancel loans which are invalid,
    /// @dev because of low ltv or max loan amount below the collateral value, or duplicated loans on same collateral amount

    function loanCancelBulk(uint256[] memory _loanIds)
        external
        onlyLiquidator(msg.sender)
    {
        uint256 loanIdsLength = _loanIds.length;
        for (uint256 i = 0; i < loanIdsLength; i++) {
            require(
                loanOffersToken[_loanIds[i]].loanStatus ==
                    TokenLoanData.LoanStatus.INACTIVE,
                "GLM, Loan cannot be cancel"
            );

            loanOffersToken[_loanIds[i]].loanStatus = TokenLoanData
                .LoanStatus
                .CANCELLED;
            emit LoanOfferCancelToken(
                _loanIds[i],
                loanOffersToken[_loanIds[i]].borrower,
                loanOffersToken[_loanIds[i]].loanStatus
            );
        }
    }

    /// @dev function for lender to activate loan offer by the borrower
    /// @param loanIds array of loan ids which are going to be activated
    /// @param stableCoinAmounts amounts of stable coin requested by the borrower for the specific loan Id
    /// @param _autoSell if autosell, then loan will be autosell at the time of liquidation through the DEX

    function activateLoan(
        uint256[] memory loanIds,
        uint256[] memory stableCoinAmounts,
        bool[] memory _autoSell
    ) public whenNotPaused {
        for (uint256 i = 0; i < loanIds.length; i++) {
            require(
                loanIds.length == stableCoinAmounts.length &&
                    loanIds.length == _autoSell.length,
                "GLM: length not match"
            );

            TokenLoanData.LoanDetails storage loanDetails = loanOffersToken[
                loanIds[i]
            ];

            require(
                loanDetails.loanStatus == TokenLoanData.LoanStatus.INACTIVE,
                "GLM, not inactive"
            );
            require(
                loanDetails.borrower != msg.sender,
                "GLM, self activation forbidden"
            );
            if (
                !ITokenMarketRegistry(marketRegistry)
                    .isWhitelistedForActivation(msg.sender)
            ) {
                require(
                    loanLendLimit[msg.sender] + 1 <=
                        ITokenMarketRegistry(marketRegistry)
                            .getLoanActivateLimit(),
                    "GTM: you cannot lend more loans"
                );
                loanLendLimit[msg.sender]++;
            }

            if (
                IClaimToken(ClaimToken).isClaimToken(
                    IClaimToken(ClaimToken).getClaimTokenofSUNToken(
                        loanDetails.stakedCollateralTokens[i]
                    )
                )
            ) {
                require(
                    !_autoSell[i],
                    "GTM: autosell should be false for SUN Collateral Token"
                );
            }

            (uint256 collateralLTVPercentage, uint256 maxLoanAmount, ) = this
                .getltvCalculations(
                    loanDetails.stakedCollateralTokens,
                    loanDetails.stakedCollateralAmounts,
                    loanDetails.borrowStableCoin,
                    stableCoinAmounts[i],
                    loanDetails.borrower
                );

            require(
                maxLoanAmount != 0,
                "GTM: borrower not eligible, no tierLevel"
            );
            
            require(
                collateralLTVPercentage >
                    ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
                "GLM: Can not activate loan at liquidation level."
            );

            loanDetails.loanStatus = TokenLoanData.LoanStatus.ACTIVE;

                //push active loan ids to the lendersactivatedloanIds mapping
            lenderActivatedLoanIds[msg.sender].push(loanIds[i]);

            /// @dev  if maxLoanAmount is greater then we will keep setting the borrower loan offer amount in the loan Details

            if (maxLoanAmount >= loanDetails.loanAmountInBorrowed) {
                require(
                    loanDetails.loanAmountInBorrowed == stableCoinAmounts[i],
                    "GLM, not borrower requrested loan amount"
                );
                loanDetails.loanAmountInBorrowed = stableCoinAmounts[i];
            } else if (maxLoanAmount < loanDetails.loanAmountInBorrowed) {
                // maxLoanAmount is now assigning in the loan Details struct
                require(
                    stableCoinAmounts[i] == maxLoanAmount,
                    "GLM: loan amount not equal maxLoanAmount"
                );
                loanDetails.loanAmountInBorrowed == maxLoanAmount;
            }


            uint256 apyFee = ITokenMarketRegistry(marketRegistry).getAPYFee(
                loanDetails.loanAmountInBorrowed,
                loanDetails.apyOffer,
                loanDetails.termsLengthInDays
            );
            uint256 platformFee = (loanDetails.loanAmountInBorrowed *
                (ITokenMarketRegistry(marketRegistry).getGovPlatformFee())) /
                (10000);

            //adding platform in the liquidator contract
            ILiquidator(Liquidator).addPlatformFee(
                loanDetails.borrowStableCoin,
                platformFee
            );

            {
                //checking again the collateral tokens approval from the borrower
                //contract will now hold the staked collateral tokens
                require(
                    checkApprovedTransferCollateralsandMintSynthetic(
                        loanIds[i],
                        loanDetails.stakedCollateralTokens,
                        loanDetails.stakedCollateralAmounts,
                        loanDetails.borrower
                    ),
                    "Transfer Collateral Failed"
                );

                /// @dev approving erc20 stable token from the front end
                /// @dev transfer platform fee and apy fee to th liquidator contract, before  transfering the stable coins to borrower.
                IERC20Upgradeable(loanDetails.borrowStableCoin)
                    .safeTransferFrom(
                        msg.sender,
                        address(this),
                        loanDetails.loanAmountInBorrowed
                    );

                /// @dev APY Fee + Platform Fee transfer to the liquidator contract
                IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                    Liquidator,
                    apyFee + platformFee
                );

                /// @dev loan amount transfer after cut to borrower
                IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                    loanDetails.borrower,
                    (loanDetails.loanAmountInBorrowed - (apyFee + platformFee))
                );

                //activated loan id to the lender details
                activatedLoanOffers[loanIds[i]] = TokenLoanData.LenderDetails({
                    lender: msg.sender,
                    activationLoanTimeStamp: block.timestamp,
                    autoSell: _autoSell[i]
                });
            }

            emit TokenLoanOfferActivated(
                loanIds[i],
                msg.sender,
                stableCoinAmounts[i],
                _autoSell[i]
            );
        }
    }

    /// @dev internal function checking ERC20 collateral token approval
    /// @param _collateralTokens array of collateral token addresses
    /// @param _collateralAmounts array of collateral amounts
    /// @param isMintSp will be false for all the collateral tokens, and will be true at the time of activate loan
    /// @param borrower address of the borrower whose collateral approval is checking
    /// @return bool return the bool value true or false

    function checkApprovalCollaterals(
        address[] memory _collateralTokens,
        uint256[] memory _collateralAmounts,
        bool[] memory isMintSp,
        address borrower
    ) internal returns (bool) {
        uint256 length = _collateralTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address claimToken = IClaimToken(ClaimToken)
                .getClaimTokenofSUNToken(_collateralTokens[i]);
            require(
                ITokenMarketRegistry(marketRegistry).isTokenApproved(
                    _collateralTokens[i]
                ) || IClaimToken(ClaimToken).isClaimToken(claimToken),
                "GLM: One or more tokens not approved."
            );
            require(
                ITokenMarketRegistry(marketRegistry)
                    .isTokenEnabledForCreateLoan(_collateralTokens[i]),
                "GTM: token not enabled"
            );
            require(!isMintSp[i], "GLM: mint error");
            uint256 allowance = IERC20Upgradeable(_collateralTokens[i])
                .allowance(borrower, address(this));
            require(
                allowance >= _collateralAmounts[i],
                "GTM: Transfer amount exceeds allowance."
            );
        }

        return true;
    }

    /// @dev check approve of tokens, transfer token to contract and mint synthetic token if mintVip is on for that collateral token
    /// @param _loanId using loanId to make isMintSp flag true in the create loan function
    /// @param collateralAddresses collateral token addresses array
    /// @param collateralAmounts collateral token amounts array
    /// @return bool return true if succesful check all the approval of token and transfer of collateral tokens, else returns false.
    function checkApprovedTransferCollateralsandMintSynthetic(
        uint256 _loanId,
        address[] memory collateralAddresses,
        uint256[] memory collateralAmounts,
        address borrower
    ) internal returns (bool) {
        uint256 length = collateralAddresses.length;
        for (uint256 k = 0; k < length; k++) {
            require(
                IERC20Upgradeable(collateralAddresses[k]).allowance(
                    borrower,
                    address(this)
                ) >= collateralAmounts[k],
                "GLM: Transfer amount exceeds allowance."
            );

            IERC20Upgradeable(collateralAddresses[k]).safeTransferFrom(
                borrower,
                Liquidator,
                collateralAmounts[k]
            );
            {
                (address gToken, , ) = ITokenMarketRegistry(marketRegistry)
                    .getSingleApproveTokenData(collateralAddresses[k]);
                if (
                    ITokenMarketRegistry(marketRegistry).isSyntheticMintOn(
                        collateralAddresses[k]
                    )
                ) {
                    IGToken(gToken).mint(borrower, collateralAmounts[k]);
                    loanOffersToken[_loanId].isMintSp[k] = true;
                }
            }
        }
        return true;
    }

    /// @dev this function returns calulatedLTV Percentage, maxLoanAmountValue, and  collatetral Price In Borrowed Stable
    /// @param _stakedCollateralTokens addresses array of the staked collateral token by the borrower
    /// @param _stakedCollateralAmount collateral tokens amount array
    /// @param _borrowStableCoin stable coin address the borrower want to borrrower
    /// @param _loanAmountinStable loan amount in stable address decimals
    /// @param _borrower address of the borrower
    function getltvCalculations(
        address[] memory _stakedCollateralTokens,
        uint256[] memory _stakedCollateralAmount,
        address _borrowStableCoin,
        uint256 _loanAmountinStable,
        address _borrower
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 collatetralInBorrowed = 0;
        IPriceConsumer _priceConsumer = IPriceConsumer(PriceConsumer);

        for (
            uint256 index = 0;
            index < _stakedCollateralAmount.length;
            index++
        ) {
            address claimToken = IClaimToken(ClaimToken)
                .getClaimTokenofSUNToken(_stakedCollateralTokens[index]);
            if (IClaimToken(ClaimToken).isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        _priceConsumer.getSUNTokenPrice(
                            claimToken,
                            _borrowStableCoin,
                            _stakedCollateralTokens[index],
                            _stakedCollateralAmount[index]
                        )
                    );
            } else {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        _priceConsumer.getAltCoinPriceinStable(
                            _borrowStableCoin,
                            _stakedCollateralTokens[index],
                            _stakedCollateralAmount[index]
                        )
                    );
            }
        }
        uint256 calulatedLTV = _priceConsumer.calculateLTV(
            _stakedCollateralAmount,
            _stakedCollateralTokens,
            _borrowStableCoin,
            _loanAmountinStable
        );
        uint256 maxLoanAmountValue = IUserTier(TierLevel)
            .getMaxLoanAmountToValue(collatetralInBorrowed, _borrower);

        return (calulatedLTV, maxLoanAmountValue, collatetralInBorrowed);
    }

    /// @dev update the payback Amount in the Liquidator contract
    /// @dev caller of this function will be liquidator contract
    /// @param _loanId loan Id of the borrower whose payback amount is updating
    /// @param _paybackAmount payback amount passed in the liquidator contract while payback function execution from the borrower
    function updatePaybackAmount(uint256 _loanId, uint256 _paybackAmount)
        external
        override
    {
        require(msg.sender == Liquidator, "GTM: Caller not liquidator");
        loanOffersToken[_loanId].paybackAmount += _paybackAmount;
    }

    /// @dev update the loan status in the token market by the liqudator contract
    /// @param _loanId loan Id of the borrower
    /// @param _status loan status if the loan offer is being payback or liquidated in the liquidator contract
    function updateLoanStatus(uint256 _loanId, TokenLoanData.LoanStatus _status)
        external
        override
    {
        require(msg.sender == Liquidator, "GTM: Caller not liquidator");

        loanOffersToken[_loanId].loanStatus = _status;
    }

    /// @dev only super admin can withdraw coins
    /// @param _withdrawAmount value input by the super admin whichever amount receive in the token market contract
    /// @param _walletAddress wallet address of the receiver of native coin
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GTM: Amount Invalid"
        );
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GTM: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /// @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
    /// @param _loanId loan Id of the borrower
    /// @return TokenLoanData.LenderDetails returns the activate loan detail
    function getActivatedLoanDetails(uint256 _loanId)
        external
        view
        override
        returns (TokenLoanData.LenderDetails memory)
    {
        return activatedLoanOffers[_loanId];
    }

    /// @dev get loan details of the single or multi-token
    /// @param _loanId loan Id of the borrower
    /// @return TokenLoanData returns the activate loan detail
    function getLoanOffersToken(uint256 _loanId)
        external
        view
        override
        returns (TokenLoanData.LoanDetails memory)
    {
        return loanOffersToken[_loanId];
    }

}