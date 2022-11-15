// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Core contract for liqd lending and borrowing
contract LendingCore is Ownable {
    enum Status {
        CREATED,
        REPAID,
        LIQUIDATED
    }

    struct Loan {
        address nftAddress; // address of nft
        address borrower; // address of borrower
        address lender; // address of lender
        address currency; // address of loans' currency
        Status status; // loan status
        uint256 nftTokenId; // unique identifier of NFT that the borrower uses as collateral
        uint256 startTime; // loan start date
        uint256 endTime; // loan end date
        uint256 loanAmount; // amount lender gives borrower
        uint256 amountDue; // loanAmount + interest that needs to be paid back by borrower
        uint8 nftTokenType; // token type ERC721: 0, ERC1155: 1, Other like CryptoPunk: 2
    }

    struct LoanPayload {
        address lender;
        address borrower;
        address nftAddress;
        address currency;
        uint256 nftTokenId;
        uint256 duration;
        uint256 expiration;
        uint256 loanAmount;
        uint256 apr; // 100 = 1%
        uint8 nftTokenType;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => bool) public availableCurrencies;
    mapping(address => uint256) public platformFees; // 100 = 1%
    uint256 internal constant secondsForYear = 31540000;

    ///
    /// events
    ///

    event LoanCreated(
        address indexed lender,
        address indexed borrower,
        address indexed nftAddress,
        uint256 nftTokenId,
        uint256 loanId,
        address currency,
        uint256 loanAmount,
        uint256 fee
    );

    event LoanLiquidated(
        address indexed lender,
        address indexed borrower,
        address indexed nftAddress,
        uint256 nftTokenId,
        uint256 loanId
    );

    event LoanTerminated(
        address indexed lender,
        address indexed borrower,
        address indexed nftAddress,
        uint256 nftTokenId,
        uint256 loanId
    );

    event PlatformFeeUpdated(address indexed currency, uint256 platformFee);

    ///
    /// management
    ///

    /// @notice Set platform fee by owner
    /// @param _currency the currency of loan
    /// @param _platformFee platform fee for each currency
    function setPlatformFee(address _currency, uint256 _platformFee)
        external
        onlyOwner
    {
        require(_platformFee < 1000, "TOO_HIGH_PLATFORM_FEE");
        availableCurrencies[_currency] = true;
        platformFees[_currency] = _platformFee;

        emit PlatformFeeUpdated(_currency, _platformFee);
    }

    /// @notice Remove currency
    /// @param _currency the currency of loan
    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency] == true, "CURRENCY_NOT_EXIST");
        availableCurrencies[_currency] = false;
        platformFees[_currency] = 0;

        emit PlatformFeeUpdated(_currency, 0);
    }

    ///
    /// business logic
    ///

    /// @notice Split signature
    function splitSignature(bytes memory _sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(_sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }
        return (v, r, s);
    }

    /// @notice Recover signer
    function recoverSigner(bytes32 _message, bytes memory _sig)
        internal
        pure
        returns (address)
    {
        if (_sig.length != 65) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(_sig);

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        }

        return ecrecover(_message, v, r, s);
    }

    /// @notice Calculate dueAmount
    /// @param _loanAmount amount of loan
    /// @param _apr apr of loan
    /// @param _duration duration of loan
    function calculateDueAmount(
        uint256 _loanAmount,
        uint256 _apr,
        uint256 _duration
    ) internal pure returns (uint256) {
        return
            _loanAmount +
            ((_loanAmount * _apr * _duration * 86400) / secondsForYear / 10000);
    }

    /// @notice Calculate platform fee
    /// @param _loanAmount amount of loan
    /// @param _platformFee platform fee for each currency
    function calculatePlatformFee(uint256 _loanAmount, uint256 _platformFee)
        internal
        pure
        returns (uint256)
    {
        return (_loanAmount * _platformFee) / 10000;
    }
}