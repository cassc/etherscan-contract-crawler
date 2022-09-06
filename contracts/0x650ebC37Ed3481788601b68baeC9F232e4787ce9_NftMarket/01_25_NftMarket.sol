// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../pausable/PausableImplementation.sol";
import "../base/NftMarketBase.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";
import "../../admin/tierLevel/interfaces/IUserTier.sol";
import "../interfaces/ITokenMarketRegistry.sol";

interface IGovLiquidator {
    function isLiquidateAccess(address liquidator) external view returns (bool);
}

interface IProtocolRegistry {
    function isStableApproved(address _stable) external view returns (bool);

    function getGovPlatformFee() external view returns (uint256);
}

contract NftMarket is
    NftMarketBase,
    ERC721Holder,
    PausableImplementation,
    SuperAdminControl
{
    //Load library structs into contract
    using NftLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IGovLiquidator public Liquidator;
    IProtocolRegistry public ProtocolRegistry;
    IUserTier public TierLevel;

    address public govAdminRegistry;
    address public addressProvider;
    address public marketRegistry;
    uint256 public loanIdNFT;

    uint256 public loanActivateLimit;
    mapping(address => bool) public whitelistAddress;
    mapping(address => uint256) public loanLendLimit;

    function initialize() external initializer {
        __Ownable_init();
    }

    modifier onlyLiquidator(address _admin) {
        require(
            IGovLiquidator(Liquidator).isLiquidateAccess(_admin),
            "GTM: not liquidator"
        );
        _;
    }

    /// @dev function to receive the native coins
    receive() external payable {}

    /// @dev this function update all the address that are needed to run the token market

    function updateAddresses() external onlyOwner {
        Liquidator = IGovLiquidator(
            IAddressProvider(addressProvider).getLiquidator()
        );
        ProtocolRegistry = IProtocolRegistry(
            IAddressProvider(addressProvider).getProtocolRegistry()
        );
        TierLevel = IUserTier(IAddressProvider(addressProvider).getUserTier());
        govAdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
        marketRegistry = IAddressProvider(addressProvider)
            .getTokenMarketRegistry();
    }

    /// @dev function to set the address provider contract

    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev set the loan activation limit for the nft market loans
    /// @param _loansLimit loan limit set the lenders
    function setloanActivateLimit(uint256 _loansLimit)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
        emit LoanActivateLimitUpdated(_loansLimit);
    }

    /// @dev set the whitelist addresses that can lend unlimited loans
    /// @param _lender address of the lender
    function setWhilelistAddress(address _lender)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        whitelistAddress[_lender] = true;
    }

    /// @dev modifier: only liquidators can liqudate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            Liquidator.isLiquidateAccess(liquidator),
            "GNM: Not a Gov Liquidator."
        );
        _;
    }

    /// @dev function to create Single || Multi NFT Loan Offer by the BORROWER
    /// @param  loanDetailsNFT {see NftLoanData.sol}

    function createLoan(NftLoanData.LoanDetailsNFT memory loanDetailsNFT)
        public
        whenNotPaused
    {
        require(
            ProtocolRegistry.isStableApproved(loanDetailsNFT.borrowStableCoin),
            "GLM: not approved stable coin"
        );

        uint256 newLoanIdNFT = _getNextLoanIdNFT();
        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetailsNFT.borrowStableCoin
        ).decimals();
        require(
            loanDetailsNFT.loanAmountInBorrowed >=
                (ITokenMarketRegistry(marketRegistry)
                    .getMinLoanAmountAllowed() * (10**stableCoinDecimals)),
            "GLM: min loan amount invalid"
        );

        uint256 collateralLength = loanDetailsNFT
            .stakedCollateralNFTsAddress
            .length;
        require(
            (loanDetailsNFT.stakedCollateralNFTsAddress.length ==
                loanDetailsNFT.stakedCollateralNFTId.length) ==
                (loanDetailsNFT.stakedCollateralNFTId.length ==
                    loanDetailsNFT.stakedNFTPrice.length),
            "GLM: Length not equal"
        );

        if (NftLoanData.LoanType.SINGLE_NFT == loanDetailsNFT.loanType) {
            require(collateralLength == 1, "GLM: MULTI-NFTs not allowed");
        }
        uint256 collatetralInBorrowed = 0;
        for (uint256 index = 0; index < collateralLength; index++) {
            collatetralInBorrowed += loanDetailsNFT.stakedNFTPrice[index];
        }
        uint256 response = TierLevel.isCreateLoanNftUnderTier(
            msg.sender,
            loanDetailsNFT.loanAmountInBorrowed,
            collatetralInBorrowed,
            loanDetailsNFT.stakedCollateralNFTsAddress
        );
        require(response == 200, "NMT: Invalid tier loan");
        borrowerloanOffersNFTs[msg.sender].push(newLoanIdNFT);
        loanOfferIdsNFTs.push(newLoanIdNFT);
        //loop through all staked collateral NFTs.
        require(
            checkApprovalNFTs(
                loanDetailsNFT.stakedCollateralNFTsAddress,
                loanDetailsNFT.stakedCollateralNFTId
            ),
            "GLM: one or more nfts not approved"
        );

        loanOffersNFT[newLoanIdNFT] = NftLoanData.LoanDetailsNFT(
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.loanType,
            NftLoanData.LoanStatus.INACTIVE,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.isPrivate,
            loanDetailsNFT.isInsured,
            msg.sender,
            loanDetailsNFT.borrowStableCoin
        );

        emit LoanOfferCreatedNFT(newLoanIdNFT, loanOffersNFT[newLoanIdNFT]);

        _incrementLoanIdNFT();
    }

    /// @dev function to cancel the created laon offer for token type Single || Multi NFT Colletrals
    /// @param _nftloanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping

    function nftloanOfferCancel(uint256 _nftloanId) public whenNotPaused {
       
        require(
            loanOffersNFT[_nftloanId].loanStatus ==
                NftLoanData.LoanStatus.INACTIVE,
            "GLM, cannot be cancel"
        );
        require(
            loanOffersNFT[_nftloanId].borrower == msg.sender,
            "GLM, only borrower can cancel"
        );

        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.CANCELLED;

        emit LoanOfferCancelNFT(
            _nftloanId,
            msg.sender,
            loanOffersNFT[_nftloanId].loanStatus
        );
    }

    // @dev cancel multiple loans by liquidator
    /// @dev function to cancel loans which are invalid,
    /// @dev because of low ltv or max loan amount below the collateral value, or duplicated loans on same collateral amount
    function loanCancelBulk(uint256[] memory _loanIds)
        external
        onlyLiquidator(msg.sender)
    {
        uint256 loanIdsLength = _loanIds.length;
        for (uint256 i = 0; i < loanIdsLength; i++) {
            require(
                loanOffersNFT[_loanIds[i]].loanStatus ==
                    NftLoanData.LoanStatus.INACTIVE,
                "GLM, Loan cannot be cancel"
            );

            loanOffersNFT[_loanIds[i]].loanStatus = NftLoanData
                .LoanStatus
                .CANCELLED;
            emit LoanOfferCancelNFT(
                _loanIds[i],
                loanOffersNFT[_loanIds[i]].borrower,
                loanOffersNFT[_loanIds[i]].loanStatus
            );
        }
    }

    /// @dev function to adjust already created loan offer, while in inactive state
    /// @param  _nftloanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    /// @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    /// @param _newTermsLengthInDays, borrower changing the loan term in days
    /// @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    /// @param _isPrivate, boolena value of true if private otherwise false
    /// @param _isInsured, isinsured true or false

    function nftLoanOfferAdjusted(
        uint256 _nftloanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
    ) public whenNotPaused {
    
        require(
            loanOffersNFT[_nftloanIdAdjusted].loanStatus ==
                NftLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot adjusted"
        );
        require(
            loanOffersNFT[_nftloanIdAdjusted].borrower == msg.sender,
            "GLM, only borrower can adjust own loan"
        );

        uint256 collatetralInBorrowed = 0;
        for (
            uint256 index = 0;
            index < loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice.length;
            index++
        ) {
            collatetralInBorrowed += loanOffersNFT[_nftloanIdAdjusted]
                .stakedNFTPrice[index];
        }

        uint256 response = TierLevel.isCreateLoanNftUnderTier(
            msg.sender,
            _newLoanAmountBorrowed,
            collatetralInBorrowed,
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTsAddress
        );
        require(response == 200, "NMT: Invalid tier loan");
        loanOffersNFT[_nftloanIdAdjusted] = NftLoanData.LoanDetailsNFT(
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTsAddress,
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTId,
            loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice,
            _newLoanAmountBorrowed,
            _newAPYOffer,
            loanOffersNFT[_nftloanIdAdjusted].loanType,
            NftLoanData.LoanStatus.INACTIVE,
            _newTermsLengthInDays,
            _isPrivate,
            _isInsured,
            msg.sender,
            loanOffersNFT[_nftloanIdAdjusted].borrowStableCoin
        );

        emit NFTLoanOfferAdjusted(
            _nftloanIdAdjusted,
            loanOffersNFT[_nftloanIdAdjusted]
        );
    }

    /// @dev function for lender to activate loan offer by the borrower
    /// @param _nftloanId loan id which is going to be activated
    /// @param _stableCoinAmount amount of stable coin requested by the borrower

    function activateNFTLoan(uint256 _nftloanId, uint256 _stableCoinAmount)
        public
        whenNotPaused
    {
        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[
            _nftloanId
        ];

        require(
            loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.INACTIVE,
            "GLM, loan should be InActive"
        );
        require(
            loanDetailsNFT.borrower != msg.sender,
            "GLM, only Lenders can Active"
        );
        require(
            loanDetailsNFT.loanAmountInBorrowed == _stableCoinAmount,
            "GLM, amount not equal to borrow amount"
        );

        if (!whitelistAddress[msg.sender]) {
            require(
                loanLendLimit[msg.sender] + 1 <= loanActivateLimit,
                "GTM: you cannot lend more loans"
            );
            loanLendLimit[msg.sender]++;
        }

        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoansNFTs[msg.sender].push(_nftloanId);

        // checking again the collateral tokens approval from the borrower
        // contract will now hold the staked collateral tokens after safeTransferFrom executes
        require(
            checkAppovedandTransferNFTs(
                loanDetailsNFT.stakedCollateralNFTsAddress,
                loanDetailsNFT.stakedCollateralNFTId,
                loanDetailsNFT.borrower
            ),
            "GTM: Transfer Failed"
        );

        uint256 apyFee = this.getAPYFeeNFT(loanDetailsNFT);
        uint256 platformFee = (loanDetailsNFT.loanAmountInBorrowed *
            (ProtocolRegistry.getGovPlatformFee())) / 10000;
        uint256 loanAmountAfterCut = loanDetailsNFT.loanAmountInBorrowed -
            (apyFee + platformFee);
        stableCoinWithdrawable[address(this)][
            loanDetailsNFT.borrowStableCoin
        ] += platformFee;

        require(
            (apyFee + loanAmountAfterCut + platformFee) ==
                loanDetailsNFT.loanAmountInBorrowed,
            "GLM, invalid amount"
        );

        /// @dev lender transfer the stable coins to the nft market contract
        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransferFrom(
            msg.sender,
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );

        /// @dev loan amount transfer to borrower after the loan amount cut
        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransfer(
            loanDetailsNFT.borrower,
            loanAmountAfterCut
        );

        //activated loan id to the lender details
        activatedNFTLoanOffers[_nftloanId] = NftLoanData.LenderDetailsNFT({
            lender: msg.sender,
            activationLoanTimeStamp: block.timestamp
        });

        emit NFTLoanOfferActivated(
            _nftloanId,
            msg.sender,
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.loanType,
            loanDetailsNFT.isPrivate,
            loanDetailsNFT.borrowStableCoin
        );
    }

    /// @dev payback loan full by the borrower to the lender
    /// @param _nftLoanId nft loan Id of the borrower
    function nftLoanPaybackBeforeTermEnd(uint256 _nftLoanId)
        public
        whenNotPaused
    {
        address borrower = msg.sender;

        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[
            _nftLoanId
        ];

        require(
            loanDetailsNFT.borrower == borrower,
            "GLM, only borrower can payback"
        );
        require(
            loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );

        uint256 loanTermLengthPassed = block.timestamp -
            activatedNFTLoanOffers[_nftLoanId].activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400; //86400 == 1 day
        require(
            loanTermLengthPassedInDays <= loanDetailsNFT.termsLengthInDays,
            "GLM: Loan already paybacked or liquidated"
        );
        uint256 apyFeeOriginal = this.getAPYFeeNFT(loanDetailsNFT);

        uint256 earnedAPY = ((loanDetailsNFT.loanAmountInBorrowed *
            loanDetailsNFT.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;

        if (earnedAPY > apyFeeOriginal) {
            earnedAPY = apyFeeOriginal;
        }

        uint256 finalAmounttoLender = loanDetailsNFT.loanAmountInBorrowed +
            earnedAPY;

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPY;

        stableCoinWithdrawable[address(this)][
            loanDetailsNFT.borrowStableCoin
        ] += unEarnedAPYFee;

        loanOffersNFT[_nftLoanId].loanStatus = NftLoanData.LoanStatus.CLOSED;

        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransferFrom(
            loanDetailsNFT.borrower,
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );

        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransfer(
            activatedNFTLoanOffers[_nftLoanId].lender,
            finalAmounttoLender
        );

        //loop through all staked collateral nft tokens.
        uint256 collateralNFTlength = loanDetailsNFT
            .stakedCollateralNFTsAddress
            .length;
        for (uint256 i = 0; i < collateralNFTlength; i++) {
            /// @dev contract will the repay staked collateral tokens to the borrower
            IERC721Upgradeable(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    borrower,
                    loanDetailsNFT.stakedCollateralNFTId[i]
                );
        }


        emit NFTLoanPaybacked(
            _nftLoanId,
            borrower,
            NftLoanData.LoanStatus.CLOSED
        );
    }

    /// @dev liquidate call by the gov world liqudatior address
    /// @param _loanId loan id to check if its loan term ended

    function liquidateBorrowerNFT(uint256 _loanId)
        public
        onlyLiquidatorRole(msg.sender)
    {
        require(
            loanOffersNFT[_loanId].loanStatus == NftLoanData.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );
        NftLoanData.LoanDetailsNFT memory loanDetails = loanOffersNFT[_loanId];
        NftLoanData.LenderDetailsNFT memory lenderDetails = activatedNFTLoanOffers[_loanId];

        require(lenderDetails.activationLoanTimeStamp != 0, "GLM: loan not activated");

        uint256 loanTermLengthPassed = block.timestamp -
            lenderDetails.activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;
        require(
            loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1,
            "GNM: Loan not ready for liquidation"
        );

        //send collateral nfts to the lender
        uint256 collateralNFTlength = loanDetails
            .stakedCollateralNFTsAddress
            .length;
        for (uint256 i = 0; i < collateralNFTlength; i++) {
            //contract will the repay staked collateral tokens to the borrower
            IERC721Upgradeable(loanDetails.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    lenderDetails.lender,
                    loanDetails.stakedCollateralNFTId[i]
                );
        }

        loanOffersNFT[_loanId].loanStatus = NftLoanData.LoanStatus.LIQUIDATED;

        emit AutoLiquidatedNFT(_loanId, NftLoanData.LoanStatus.LIQUIDATED);
    }

    /// @dev check approval of nfts from the borrower to the nft market
    /// @param nftAddresses ERC721 NFT contract addresses
    /// @param nftIds nft token ids
    /// @return bool returns the true or false for the nft approvals
    function checkApprovalNFTs(
        address[] memory nftAddresses,
        uint256[] memory nftIds
    ) internal view returns (bool) {
        uint256 length = nftAddresses.length;

        for (uint256 i = 0; i < length; i++) {
            //borrower will approved the tokens staking as collateral
            require(
                IERC721Upgradeable(nftAddresses[i]).getApproved(nftIds[i]) ==
                    address(this),
                "GLM: Approval Error"
            );
        }
        return true;
    }

    /// @dev function that receive an array of addresses to check approval of NFTs
    /// @param nftAddresses contract addresses of ERC721
    /// @param nftIds token ids of nft contracts
    /// @param borrower address of the borrower

    function checkAppovedandTransferNFTs(
        address[] memory nftAddresses,
        uint256[] memory nftIds,
        address borrower
    ) internal returns (bool) {
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            require(
                IERC721Upgradeable(nftAddresses[i]).getApproved(nftIds[i]) ==
                    address(this),
                "GLM: Approval Error"
            );
            IERC721Upgradeable(nftAddresses[i]).safeTransferFrom(
                borrower,
                address(this),
                nftIds[i]
            );
        }

        return true;
    }

    /// @dev only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(govAdminRegistry, msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GNM: Amount Invalid"
        );
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GNM: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /// @dev only super admin can withdraw tokens
    /// @param _tokenAddress token Address of the stable coin, superAdmin wants to withdraw
    /// @param _amount desired amount to withdraw
    /// @param _walletAddress wallet address of the admin
    function withdrawToken(
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
        emit WithdrawToken(_tokenAddress, _walletAddress, _amount);
    }

    /**
    @dev function to get the next nft loan Id after creating the loan offer in NFT case
     */
    function _getNextLoanIdNFT() public view returns (uint256) {
        return loanIdNFT + 1;
    }

    /**
    @dev returns the current loan id of the nft loans
     */
    function getCurrentLoanIdNFT() public view returns (uint256) {
        return loanIdNFT;
    }

    /**
    @dev will increment loan id after creating loan offer
     */
    function _incrementLoanIdNFT() private {
        loanIdNFT++;
    }

}