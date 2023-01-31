// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "../DataTypes.sol";

interface IXY3 {
    /**
     * @dev This event is emitted when  calling acceptOffer(), need both the lender and borrower to approve their ERC721 and ERC20 contracts to XY3.
     *
     * @param  loanId - A unique identifier for the loan.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender.
     * @param  nonce - nonce of the lender's offer signature
     */
    event LoanStarted(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 nonce,
        LoanDetail loanDetail,
        address target,
        bytes4 selector
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
     * @param  nonce - nonce of the lender's offer signature
     */
    event NonceCancelled(address lender, uint256 nonce);

    /**
     * @dev This event is emitted when cancelByTimestamp called
     * @param  lender - The address of the lender.
     * @param timestamp - cancelled timestamp
     */
    event TimeStampCancelled(address lender, uint256 timestamp);

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

    event BorrowRefferal(
        uint32 indexed loanId,
        address indexed borrower,
        uint256 referral
    );

    event FlashExecute(
        uint32 indexed loanId,
        address nft,
        uint256 nftTokenId,
        address flashTarget
    );

    event ServiceFee(uint32 indexed loanId, address indexed target, uint16 serviceFeeRate, uint256 feeAmount);

    /**
     * @dev Get the load info by loadId
     */
    function loanDetails(
        uint32
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint32,
            uint16,
            uint64,
            address,
            bool
        );

    function loanIds(
        address collection,
        uint256 tokenId
    ) external view returns (uint32);

    /**
     * @dev The borrower accept a lender's offer to create a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _nftId - The ID
     * @param _isCollectionOffer - Wether the offer is a collection offer.
     * @param _lenderSignature - The lender's signature.
     * @param _brokerSignature - The broker's signature.
     * @param _extraDeal - Create a new loan by getting a NFT colleteral from external contract call.
     * The external contract can be lending market or deal market, specially included the restricted repay of myself.
     * But should not be the Xy3Nft.mint, though this contract maybe have the permission.
     */
    function borrow(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollectionOffer,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature,
        CallData memory _extraDeal
    ) external returns (uint32);

    /**
     * @dev A lender or a borrower to cancel all off-chain orders signed that contain this nonce.
     * @param  _nonce - User nonce
     */
    function cancelByNonce(uint256 _nonce) external;

    /**
     * @dev A borrower cancel all offers with timestamp before the _timestamp parameter.
     * @param _timestamp - cancelled timestamp
     */
    function cancelByTimestamp(uint256 _timestamp) external;

    /**
     * @notice Check a nonce has been used or not
     * @param _user - The user address.
     * @param _nonce - The order Id
     *
     * @return A bool for used or not.
     */
    function getNonceUsed(
        address _user,
        uint256 _nonce
    ) external view returns (bool);

    /**
     * @dev This function can be used to view the last cancel timestamp a borrower has set.
     * @param _user User address
     * @return The cancel timestamp
     */
    function getTimestampCancelled(
        address _user
    ) external view returns (uint256);

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
     * @dev Allow admin to claim airdroped erc20 tokens
     */
    function adminClaimErc20(
        address _to,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @dev Allow admin to claim airdroped erc721 tokens
     */

    function adminClaimErc721(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds
    ) external;

    /**
     * @dev Allow admin to claim airdroped erc1155 tokens
     */

    function adminClaimErc1155(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    /**
     * @dev The amount of ERC20 currency for the loan.
     * @param _loanId  A unique identifier for this particular loan.
     * @return The amount of ERC20 currency.
     */
    function getRepayAmount(uint32 _loanId) external returns (uint256);
}