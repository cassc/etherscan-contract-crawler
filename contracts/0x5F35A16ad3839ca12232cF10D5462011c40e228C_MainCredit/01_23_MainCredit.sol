// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interface/ICollateralWhitelist.sol";
import "../interface/ILoanCurrencyWhitelist.sol";
import "../wrapper/CollateralWrapper.sol";
import "../wrapper/LoanCurrencyWrapper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "hardhat/console.sol";

/**
 * @title MainCredit
 * @author
 * @notice
 */
contract MainCredit is
    Ownable,
    ERC721Holder,
    ERC1155Holder,
    CollateralWrapper,
    LoanCurrencyWrapper
{
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    bool private INITIALIZED = false;

    uint16 private HUNDRED_PERCENT = 10000;

    uint16 private USER_INTEREST_PERCENTAGE = 9600;

    uint16 private MAX_DURATION = 366;

    uint16 private ONE_YEAR = 365;

    ICollateralWhitelist private collateralWhitelist;

    ILoanCurrencyWhitelist private loanCurrencyWhitelist;

    mapping(address => mapping(uint256 => LoanTerm)) public collateralLoans;

    address adminPlatform;

    /* *********** */
    /* EVENTS */
    /* *********** */

    event LoanStarted(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerm loan
    );

    event LoanRepaid(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerm loan,
        uint256 loanRepaidTime
    );

    event LoanBreached(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerm loan,
        uint256 loanBreachedTime
    );

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function initialize(
        address _collateralWhitelistAddress,
        address _loanCurrencyWhitelistAddress,
        address _adminPlatformAddress
    ) external {
        require(!INITIALIZED, "Contract is already initialized");
        _transferOwnership(msg.sender);
        INITIALIZED = true;

        collateralWhitelist = ICollateralWhitelist(_collateralWhitelistAddress);
        loanCurrencyWhitelist = ILoanCurrencyWhitelist(
            _loanCurrencyWhitelistAddress
        );
        if (_adminPlatformAddress == address(0)) {
            adminPlatform = address(this);
        } else {
            adminPlatform = _adminPlatformAddress;
        }

        HUNDRED_PERCENT = 10000;

        USER_INTEREST_PERCENTAGE = 9600;

        MAX_DURATION = 366;

        ONE_YEAR = 365;
    }

    function setAdminPlatform(address _address) external {
        _setAdminPlatform(_address);
    }

    function createLoan(OfferTerm calldata _offer, address _lender) external {
        _createLoan(_offer, _lender);
    }

    function repayLoan(address _collateralAddress, uint256 _collateralId)
        external
    {
        _repayLoan(_collateralAddress, _collateralId);
    }

    function breachLoan(address _collateralAddress, uint256 _collateralId)
        external
    {
        _breachLoan(_collateralAddress, _collateralId);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    function _checkNonZeroAddress(address _address) internal pure {
        require(_address != address(0), "Address can not be zero");
    }

    function _checkLoanDuration(uint16 _duration) internal view {
        // require(_duration <= MAX_DURATION, "Duration is in range of 1 to 366");
    }

    function _checkCollateralIsWhitelisted(address _address) internal view {
        require(
            collateralWhitelist.isCollateralWhitelisted(_address),
            "Collateral is not whitelisted"
        );
    }

    function _checkLoanCurrencyIsWhitelisted(address _address) internal view {
        require(
            loanCurrencyWhitelist.isLoanCurrencyWhitelisted(_address),
            "LoanCurrency is not whitelisted"
        );
    }

    function _checkCollateralIsNotLoaned(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view {
        require(
            collateralLoans[_collateralAddress][_collateralId].borrower ==
                address(0),
            "Collateral is already liquified"
        );
    }

    function _checkCollateralIsLoaned(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view {
        require(
            collateralLoans[_collateralAddress][_collateralId].borrower !=
                address(0),
            "Collateral is not liquified yet"
        );
    }

    function _checkCollateralOwner(
        address _owner,
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType
    ) internal view {
        require(
            _haveNFTOwnership(
                _owner,
                _collateralAddress,
                _collateralId,
                _collateralType
            ),
            "Caller is not collateral owner"
        );
    }

    function _checkLoanIsOverdue(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view {
        require(
            block.timestamp >=
                collateralLoans[_collateralAddress][_collateralId].startTime +
                    collateralLoans[_collateralAddress][_collateralId]
                        .offer
                        .duration *
                    1 minutes,
            "Loan is not overdue"
        );
    }

    function _checkLoanIsNotOverdue(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view {
        require(
            block.timestamp <
                collateralLoans[_collateralAddress][_collateralId].startTime +
                    collateralLoans[_collateralAddress][_collateralId]
                        .offer
                        .duration *
                    1 minutes,
            "Loan is overdue"
        );
    }

    function _checkLoanCurrencyApproved(
        address _loanCurrencyAddress,
        address _lender,
        uint256 _principalAmount
    ) internal view {
        require(
            _getFTApproved(_loanCurrencyAddress, _lender, _principalAmount),
            "LoanCurrency is not approved"
        );
    }

    function _checkLoanCurrencyAmount(
        address _owner,
        address _loanCurrencyAddress,
        uint256 _amount
    ) internal view {
        require(
            _getFTBalance(_owner, _loanCurrencyAddress) >= _amount,
            "Don't have enough fund"
        );
    }

    function _checkBorrowerAddress(
        address _collateralAddress,
        uint256 _collateralId,
        address _borrower
    ) internal view {
        require(
            collateralLoans[_collateralAddress][_collateralId].borrower ==
                _borrower,
            "Borrower is not correct"
        );
    }

    function _checkLenderAddress(
        address _collateralAddress,
        uint256 _collateralId,
        address _lender
    ) internal view {
        require(
            collateralLoans[_collateralAddress][_collateralId].lender ==
                _lender,
            "Lender is not correct"
        );
    }

    function _setAdminPlatform(address _address) internal onlyOwner {
        _checkNonZeroAddress(_address);
        adminPlatform = _address;
    }

    function _createLoan(OfferTerm calldata _offer, address _lender) internal {
        // check conditions
        _checkNonZeroAddress(_lender);
        _checkNonZeroAddress(_offer.collateralAddress);
        _checkLoanDuration(_offer.duration);
        _checkCollateralIsWhitelisted(_offer.collateralAddress);
        _checkLoanCurrencyIsWhitelisted(_offer.loanCurrencyAddress);
        _checkCollateralIsNotLoaned(
            _offer.collateralAddress,
            _offer.collateralId
        );
        _checkCollateralOwner(
            msg.sender,
            _offer.collateralAddress,
            _offer.collateralId,
            _offer.collateralType
        );
        // _checkLoanCurrencyAmount(
        //     _lender,
        //     _offer.loanCurrencyAddress,
        //     _offer.principalAmount
        // );

        // do the operations
        _safeNFTTransferFrom(
            _offer.collateralAddress,
            _offer.collateralId,
            _offer.collateralType,
            msg.sender,
            address(this)
        );
        _safeFTTransferFrom(
            _offer.loanCurrencyAddress,
            _lender,
            msg.sender,
            _offer.principalAmount
        );
        collateralLoans[_offer.collateralAddress][
            _offer.collateralId
        ] = LoanTerm(_offer, msg.sender, _lender, block.timestamp);
    }

    function _repayLoan(address _collateralAddress, uint256 _collateralId)
        internal
    {
        _checkNonZeroAddress(_collateralAddress);
        _checkBorrowerAddress(_collateralAddress, _collateralId, msg.sender);
        _checkCollateralIsLoaned(_collateralAddress, _collateralId);
        _checkLoanIsNotOverdue(_collateralAddress, _collateralId);
        // _checkLoanCurrencyApproved(
        //     msg.sender,
        //     collateralLoans[_collateralAddress][_collateralId]
        //         .offer
        //         .loanCurrencyAddress,
        //     loanCalculator.getTotalRepayAmount(
        //         collateralLoans[_collateralAddress][_collateralId].offer
        //     )
        // );
        // _checkLoanCurrencyAmount(
        //     msg.sender,
        //     collateralLoans[_collateralAddress][_collateralId]
        //         .offer
        //         .loanCurrencyAddress,
        //     loanCalculator.getTotalRepayAmount(
        //         collateralLoans[_collateralAddress][_collateralId].offer
        //     )
        // );

        _safeNFTTransferFrom(
            _collateralAddress,
            _collateralId,
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .collateralType,
            address(this),
            msg.sender
        );
        _safeFTTransferFrom(
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .loanCurrencyAddress,
            msg.sender,
            collateralLoans[_collateralAddress][_collateralId].lender,
            _getUserInterest(_collateralAddress, _collateralId)
        );
        _safeFTTransferFrom(
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .loanCurrencyAddress,
            msg.sender,
            adminPlatform,
            _getAdminFee(_collateralAddress, _collateralId)
        );
        delete collateralLoans[_collateralAddress][_collateralId];
    }

    function _breachLoan(address _collateralAddress, uint256 _collateralId)
        internal
    {
        _checkNonZeroAddress(_collateralAddress);
        _checkLenderAddress(_collateralAddress, _collateralId, msg.sender);
        _checkCollateralIsLoaned(_collateralAddress, _collateralId);
        _checkLoanIsOverdue(_collateralAddress, _collateralId);

        _safeNFTTransferFrom(
            _collateralAddress,
            _collateralId,
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .collateralType,
            address(this),
            msg.sender
        );
        delete collateralLoans[_collateralAddress][_collateralId];
    }

    function _getUserInterest(address _collateralAddress, uint256 _collateralId)
        internal
        view
        returns (uint256)
    {
        OfferTerm memory offer = collateralLoans[_collateralAddress][
            _collateralId
        ].offer;
        if (offer.offerType == OfferType.FIXED) {
            return
                offer.principalAmount +
                (offer.principalAmount *
                    offer.annualPercentageRate *
                    offer.duration *
                    USER_INTEREST_PERCENTAGE) /
                HUNDRED_PERCENT /
                HUNDRED_PERCENT /
                ONE_YEAR;
        }
        return offer.principalAmount;
    }

    function _getAdminFee(address _collateralAddress, uint256 _collateralId)
        internal
        view
        returns (uint256)
    {
        OfferTerm memory offer = collateralLoans[_collateralAddress][
            _collateralId
        ].offer;
        if (offer.offerType == OfferType.FIXED) {
            uint256 result = (offer.principalAmount *
                offer.annualPercentageRate *
                offer.duration *
                (HUNDRED_PERCENT - USER_INTEREST_PERCENTAGE)) /
                HUNDRED_PERCENT /
                HUNDRED_PERCENT /
                ONE_YEAR;
            return result;
        }
        return 0;
    }

    function _getTotalRepayAmount(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view returns (uint256) {
        return
            _getUserInterest(_collateralAddress, _collateralId) +
            _getAdminFee(_collateralAddress, _collateralId);
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}