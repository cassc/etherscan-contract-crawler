// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import "../DataTypes.sol";

interface XY3Events {
    /**
     * @dev This event is emitted when  calling acceptOffer(), need both the lender and borrower to approve their ERC721 and ERC20 contracts to XY3.
     *
     * @param  loanId - A unique identifier for the loan.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender.
     * @param  amount - used amount of the lender's offer signature
     */
    event LoanStarted(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        address borrowAsset,
        address nftAsset,
        uint8 offerType,
        bytes32 offerHash,
        uint16 amount,
        LoanDetail loanDetail,
        CallData extraData
    );

    /**
     * @dev This event is emitted when a borrower successfully repaid the loan.
     *
     * @param  loanId - A unique identifier for the loan.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender.
     * @param  borrowAmount - The original amount of money transferred from lender to borrower.
     * @param  nftTokenId - The ID of the borrowd.
     * @param  repayAmount The amount of ERC20 that the borrower paid back.
     * @param  adminFee The amount of interest paid to the contract admins.
     * @param  nftAsset - The ERC721 contract of the NFT collateral
     * @param  borrowAsset - The ERC20 currency token.
     */
    event LoanRepaid(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 borrowAmount,
        uint256 nftTokenId,
        uint256 repayAmount,
        uint256 adminFee,
        address nftAsset,
        address borrowAsset
    );

    /**
     * @dev This event is emitted when cancelByNonce called.
     * @param  lender - The address of the lender.
     * @param  offerHash - nonce of the lender's offer signature
     */
    event OfferCancelled(address lender, bytes32 offerHash, uint256 counter);

    /**
     * @dev This event is emitted when liquidates happened
     * @param  loanId - A unique identifier for this particular loan.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender.
     * @param  borrowAmount - The original amount of money transferred from lender to borrower.
     * @param  nftTokenId - The ID of the borrowd.
     * @param  loanMaturityDate - The unix time (measured in seconds) that the loan became due and was eligible for liquidation.
     * @param  loanLiquidationDate - The unix time (measured in seconds) that liquidation occurred.
     * @param  nftAsset - The ERC721 contract of the NFT collateral
     */
    event LoanLiquidated(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 borrowAmount,
        uint256 nftTokenId,
        uint256 loanMaturityDate,
        uint256 loanLiquidationDate,
        address nftAsset
    );

    event BorrowReferral(
        uint32 indexed loanId,
        uint16 borrowType,
        uint256 referral
    );

    event FlashExecute(
        uint32 indexed loanId,
        address nft,
        uint256 nftTokenId,
        address flashTarget
    );

    event ServiceFee(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed target,
        uint16 serviceFeeRate,
        uint256 feeAmount
    );

    event UpdateStatus(uint32 indexed loanId, StatusType newStatus);
}

struct LoanInfo {
    uint32 loanId;
    address nftAsset;
    address borrowAsset;
    uint nftId;
    uint256 adminFee;
    uint payoffAmount;
    uint borrowAmount;
    uint maturityDate;
}

interface IXY3 {
    /**
     * @dev Get the loan info by loadId
     */
    function loanDetails(uint32) external view returns (LoanDetail memory);

    /**
     * @dev The borrower accept a lender's offer to create a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _nftId - The ID
     * @param _brokerSignature - The broker's signature.
     * @param _extraData - Create a new loan by getting a NFT colleteral from external contract call.
     * The external contract can be lending market or deal market, specially included the restricted repay of myself.
     * But should not be the Xy3Nft.mint, though this contract maybe have the permission.
     */
    function borrow(
        Offer memory _offer,
        uint256 _nftId,
        BrokerSignature memory _brokerSignature,
        CallData memory _extraData
    ) external returns (uint32);

    function borrowerRefinance(
        uint32 _loanId,
        Offer calldata _offer,
        BrokerSignature calldata _brokerSignature,
        CallData calldata _extraData
    ) external returns (uint32);

    function lenderRefinance(
        uint32 _loanId,
        Offer calldata _offer,
        BrokerSignature calldata _brokerSignature,
        CallData calldata _extraData
    ) external returns (uint32);

    /**
     * @dev Public function for anyone to repay a loan, and return the NFT token to origin borrower.
     * @param _loanId  The loan Id.
     */
    function repay(uint32 _loanId) external;

    /**
     * @dev Lender ended the load which not paid by borrow and expired.
     * @param _loanId The loan Id.
     */
    function liquidate(uint32 _loanId) external;

    /**
     * @dev The amount of ERC20 currency for the loan.
     * @param _loanId  A unique identifier for this particular loan.
     * @return The amount of ERC20 currency.
     */
    function getRepayAmount(uint32 _loanId) external returns (uint256);

    /**
     * @dev The amount of ERC20 currency for the loan.
     * @param _offer  A unique identifier for this particular loan.
     */
    function cancelOffer(Offer calldata _offer) external;

    /**
     * @dev The amount of ERC20 currency for the loan.
     */
    function increaseCounter() external;

    /**
     * @dev The amount of ERC20 currency for the loan.
     * @param user  A unique identifier for this particular loan.
     */
    function getUserCounter(address user) external view returns (uint);

    function loanState(uint32 _loanId) external returns (StatusType);

    function getLoanInfo(
        uint32 _loanId
    ) external view returns (LoanInfo memory);

    function getMinimalRefinanceAmounts(uint32 _loanId)
        external
        view
    returns (uint256 payoffAmount, uint256 adminFee, uint256 minServiceFee, uint16 feeRate);

    function getRefinanceCompensatedAmount(uint32 _loanId, uint256 newBorrowAmount)
        external
        view
    returns (uint256 compensatedAmount);

    function lenderRefinanceCheck(uint32 _loanId, Offer memory _offer) view external;
}

interface IDelegation {
    function userSetDelegation(
        uint32 loanId,
        bool value
    ) external;

    function userSetBatchDelegation(
        uint32[] calldata loanIds,
        bool[] calldata values
    ) external;

    function setDelegation(
        address user,
        address nftAsset,
        uint256 nftId,
        bool value
    ) external;
}