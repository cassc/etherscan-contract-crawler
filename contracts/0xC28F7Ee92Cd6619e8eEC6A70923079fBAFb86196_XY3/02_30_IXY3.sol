pragma solidity 0.8.4;
import "./DataTypes.sol";

interface IXY3 {
    
    event LoanStarted(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 nonce,
        LoanDetail loanDetail
    );

    
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

    
    event NonceCancelled(address lender, uint256 nonce);

    
    event TimeStampCancelled(address lender, uint256 timestamp);

    
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

    
    function loanDetails(uint32)
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
            address,
            bool
        );

    
    function borrow(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollectionOffer,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature
    ) external;

    
    function cancelByNonce(uint256 _nonce) external;

    
    function cancelByTimestamp(uint256 _timestamp) external;

    
    function getNonceUsed(address _user, uint256 _nonce)
        external
        view
        returns (bool);

    
    function getTimestampCancelled(address _user)
        external
        view
        returns (uint256);

    
    function repay(uint32 _loanId) external;

    
    function liquidate(uint32 _loanId) external;

    
    function getRepayAmount(uint32 _loanId) external returns (uint256);

}