// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "./PWNVault.sol";
import "./PWNLOAN.sol";
import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PWN is Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    PWNLOAN public LOAN;
    PWNVault public vault;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    // No events nor error defined

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * Constructor
     * @dev Establishes a connection with other pre-deployed components
     * @dev For the set up to work both PWNLOAN & PWNVault contracts have to called via `.setPWN(PWN.address)`
     * @param _PWNL Address of the PWNLOAN contract - defines LOAN tokens
     * @param _PWNV Address of the PWNVault contract - holds assets
     */
    constructor(
        address _PWNL,
        address _PWNV
    ) Ownable() {
        LOAN = PWNLOAN(_PWNL);
        vault = PWNVault(_PWNV);
    }

    /**
     * revokeOffer
     * @notice Lender can use this function to revoke their off-chain offers
     * @dev Can be called only from address that signed the offer
     * @param _offerHash Offer typed struct hash
     * @param _signature Offer typed struct signature
     * @return True if successful
     */
    function revokeOffer(
        bytes32 _offerHash,
        bytes calldata _signature
    ) external returns (bool) {
        LOAN.revokeOffer(_offerHash, _signature, msg.sender);

        return true;
    }

    /**
     * createLoan
     * @notice Borrower can accept existing signed off-chain offer
     * @dev A UI should do an off-chain balance check on the lender side to make sure the call won't throw
     * @dev Loan asset has to be an ERC20 token, otherwise will transaction fail
     * @param _offer Offer struct with plain offer data. See { PWNLOAN.sol }
     * @param _signature Offer typed struct signed by lender
     * @return True if successful
     */
    function createLoan(
        PWNLOAN.Offer memory _offer,
        bytes memory _signature
    ) external returns (bool) {
        LOAN.create(_offer, _signature, msg.sender);

        MultiToken.Asset memory collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralId
        );

        MultiToken.Asset memory LoanAsset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offer.loanAmount,
            0
        );

        vault.pull(collateral, msg.sender);
        vault.pushFrom(LoanAsset, _offer.lender, msg.sender);

        return true;
    }

    /**
     * createFlexibleLoan
     * @notice Borrower can accept existing signed off-chain flexible offer
     * @dev A UI should do an off-chain balance check on the lender side to make sure the call won't throw
     * @dev LOAN asset has to be an ERC20 token, otherwise will transaction fail
     * @param _offer Flexible offer struct with plain flexible offer data. See { PWNLOAN.sol }
     * @param _offerValues Concrete values of a flexible offer set by borrower. See { PWNLOAN.sol }
     * @param _signature Flexible offer typed struct signed by lender
     * @return True if successful
     */
    function createFlexibleLoan(
        PWNLOAN.FlexibleOffer memory _offer,
        PWNLOAN.FlexibleOfferValues memory _offerValues,
        bytes memory _signature
    ) external returns (bool) {
        LOAN.createFlexible(_offer, _offerValues, _signature, msg.sender);

        MultiToken.Asset memory collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offerValues.collateralId
        );

        MultiToken.Asset memory LoanAsset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offerValues.loanAmount,
            0
        );

        vault.pull(collateral, msg.sender);
        vault.pushFrom(LoanAsset, _offer.lender, msg.sender);

        return true;
    }

    /**
     * repayLoan
     * @notice The borrower can pay back the loan through this function
     * @dev The function assumes the asset (and amount to be paid back) to be returned is approved for PWNVault
     * @dev The function assumes the borrower has the full amount to be paid back in their account
     * @param _loanId LOAN ID of the loan being paid back
     * @return True if successful
     */
    function repayLoan(uint256 _loanId) external returns (bool) {
        LOAN.repayLoan(_loanId);

        MultiToken.Asset memory LoanAsset = LOAN.getLoanAsset(_loanId);
        LoanAsset.amount = LOAN.getLoanRepayAmount(_loanId);

        vault.pull(LoanAsset, msg.sender);
        vault.push(LOAN.getCollateral(_loanId), LOAN.getBorrower(_loanId));

        return true;
    }

    /**
     * claimLoan
     * @dev The current LOAN owner can call this function if the loan is expired or paied back
     * @param _loanId LOAN ID of the loan to be claimed
     * @return True if successful
     */
    function claimLoan(uint256 _loanId) external returns (bool) {
        uint8 status = LOAN.getStatus(_loanId);

        LOAN.claim(_loanId, msg.sender);

        if (status == 3) {
            MultiToken.Asset memory LoanAsset = LOAN.getLoanAsset(_loanId);
            LoanAsset.amount = LOAN.getLoanRepayAmount(_loanId);

            vault.push(LoanAsset, msg.sender);
        } else if (status == 4) {
            vault.push(LOAN.getCollateral(_loanId), msg.sender);
        } else {
            revert("Invalid status code");
        }

        LOAN.burn(_loanId, msg.sender);

        return true;
    }

}