// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingBox.sol";

interface IStagingBoxLens {
    /**
     * @dev provides the bool for limiting factor for the staging box reinit
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     */

    function viewTransmitReInitBool(IStagingBox _stagingBox)
        external
        view
        returns (bool);

    /**
     * @dev provides amount of stableTokens expected in return for a given collateral amount
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _amountRaw The amount of unwrapped tokens to be used as collateral
     * Requirements:
     */

    function viewSimpleWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of raw collateral tokens expected in return for withdrawing borrowslips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _borrowSlipAmount The amount of borrowSlips to be withdrawn
     * Requirements:
     * - for A-Z convertible only
     */

    function viewSimpleWithdrawBorrowUnwrap(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of stable tokens expected in return for withdrawing lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be withdrawn
     * Requirements:
     */

    function viewWithdrawLendSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256);

    /**
     * @dev provides amount of riskSlips and stableToken loan in return for borrowSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _borrowSlipAmount The amount of borrowSlips to be redeemed
     * Requirements:
     */

    function viewRedeemBorrowSlipForRiskSlip(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of safeSlips expected in return for redeeming lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256);

    /**
     * @dev provides amount of stableTokens expected in return for redeeming lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemLendSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of stableTokens expected in return for redeeming safeSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _safeSlipAmount The amount of safeSlips to be redeemed
     * Requirements:
     */

    function viewRedeemSafeSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of raw collateral tokens expected in return for redeeming lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemLendSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for redeeming safeSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _safeSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemSafeSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for redeeming riskSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _riskSlipAmount The amount of riskSlips to be redeemed
     * Requirements:
     */

    function viewRedeemRiskSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of stables
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _stableAmount The amount of stables being repaid
     * Requirements:
     *      - Only for prior to maturity
     *      - Only for bonds with A/Z tranches
     */

    function viewRepayAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of RiskSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     *      - Only for prior to maturity
     *      - Only for bonds with A/Z tranches
     */

    function viewRepayMaxAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of StableTokens (after maturity)
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _stableAmount The amount of stables being repaid
     * Requirements:
     *      - Only for after maturity
     
     */

    function viewRepayAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of RiskSlips (after maturity)
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _riskSlipAmount The amount of stables being repaid
     * Requirements:
     *      - Only for after maturity
     */

    function viewRepayMaxAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides maximum input param for a user redeeming BorrowSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemBorrowSlip(IStagingBox _stagingBox, address _account)
        external
        view
        returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming LendSlips for SafeSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming LendSlips for StableTokens
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemLendSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming SafeSlips for StableTokens
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemSafeSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user withdrawing LendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxWithdrawLendSlips(IStagingBox _stagingBox, address _account)
        external
        view
        returns (uint256);

    /**
     * @dev provides maximum input param for a user withdrawing BorrowSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxWithdrawBorrowSlips(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming SafeSlips for tranches
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemSafeSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming lend slips for tranches
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemLendSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);
}