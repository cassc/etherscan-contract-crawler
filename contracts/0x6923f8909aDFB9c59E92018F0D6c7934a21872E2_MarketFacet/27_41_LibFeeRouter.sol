// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, SimplePolicy, PolicyCommissionsBasisPoints, TradingCommissions, TradingCommissionsBasisPoints } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { PolicyCommissionsBasisPointsCannotBeGreaterThan10000 } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibFeeRouter {
    event TradingCommissionsPaid(bytes32 indexed takerId, bytes32 tokenId, uint256 amount);
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount);

    function _payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];
        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;
        for (uint256 i = 0; i < commissionsCount; i++) {
            uint256 commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
        }

        uint256 commissionNaymsLtd = (_premiumPaid * s.premiumCommissionNaymsLtdBP) / LibConstants.BP_FACTOR;
        uint256 commissionNDF = (_premiumPaid * s.premiumCommissionNDFBP) / LibConstants.BP_FACTOR;
        uint256 commissionSTM = (_premiumPaid * s.premiumCommissionSTMBP) / LibConstants.BP_FACTOR;

        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), simplePolicy.asset, commissionNaymsLtd);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), simplePolicy.asset, commissionNDF);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), simplePolicy.asset, commissionSTM);

        uint256 premiumCommissionPaid = commissionNaymsLtd + commissionNDF + commissionSTM;

        emit PremiumCommissionsPaid(_policyId, policyEntityId, premiumCommissionPaid);
    }

    function _payTradingCommissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tradingCommissionTotalBP <= LibConstants.BP_FACTOR, "commission total must be<=10000bp");
        require(
            s.tradingCommissionNaymsLtdBP + s.tradingCommissionNDFBP + s.tradingCommissionSTMBP + s.tradingCommissionMakerBP <= LibConstants.BP_FACTOR,
            "commissions sum over 10000 bp"
        );

        TradingCommissions memory tc = _calculateTradingCommissions(_requestedBuyAmount);
        // The rough commission deducted. The actual total might be different due to integer division

        // Pay Nayms, LTD commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, tc.commissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, tc.commissionNDF);

        // Pay Staking Mechanism commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, tc.commissionSTM);

        // Pay market maker commission
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, tc.commissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = tc.totalCommissions;

        emit TradingCommissionsPaid(_takerId, _tokenId, commissionPaid_);
    }

    function _updateTradingCommissionsBasisPoints(TradingCommissionsBasisPoints calldata bp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            bp.tradingCommissionNaymsLtdBP + bp.tradingCommissionNDFBP + bp.tradingCommissionSTMBP + bp.tradingCommissionMakerBP == LibConstants.BP_FACTOR,
            "trading commission BPs must sum up to 10000"
        );

        s.tradingCommissionTotalBP = bp.tradingCommissionTotalBP;
        s.tradingCommissionNaymsLtdBP = bp.tradingCommissionNaymsLtdBP;
        s.tradingCommissionNDFBP = bp.tradingCommissionNDFBP;
        s.tradingCommissionSTMBP = bp.tradingCommissionSTMBP;
        s.tradingCommissionMakerBP = bp.tradingCommissionMakerBP;
    }

    function _updatePolicyCommissionsBasisPoints(PolicyCommissionsBasisPoints calldata bp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalBp = bp.premiumCommissionNaymsLtdBP + bp.premiumCommissionNDFBP + bp.premiumCommissionSTMBP;
        if (totalBp > LibConstants.BP_FACTOR) {
            revert PolicyCommissionsBasisPointsCannotBeGreaterThan10000(totalBp);
        }
        s.premiumCommissionNaymsLtdBP = bp.premiumCommissionNaymsLtdBP;
        s.premiumCommissionNDFBP = bp.premiumCommissionNDFBP;
        s.premiumCommissionSTMBP = bp.premiumCommissionSTMBP;
    }

    function _calculateTradingCommissions(uint256 buyAmount) internal view returns (TradingCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // The rough commission deducted. The actual total might be different due to integer division
        tc.roughCommissionPaid = (s.tradingCommissionTotalBP * buyAmount) / LibConstants.BP_FACTOR;

        // Pay Nayms, LTD commission
        tc.commissionNaymsLtd = (s.tradingCommissionNaymsLtdBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay Nayms Discretionsry Fund commission
        tc.commissionNDF = (s.tradingCommissionNDFBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay Staking Mechanism commission
        tc.commissionSTM = (s.tradingCommissionSTMBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay market maker commission
        tc.commissionMaker = (s.tradingCommissionMakerBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Work it out again so the math is precise, ignoring remainers
        tc.totalCommissions = tc.commissionNaymsLtd + tc.commissionNDF + tc.commissionSTM + tc.commissionMaker;
    }

    function _getTradingCommissionsBasisPoints() internal view returns (TradingCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.tradingCommissionTotalBP = s.tradingCommissionTotalBP;
        bp.tradingCommissionNaymsLtdBP = s.tradingCommissionNaymsLtdBP;
        bp.tradingCommissionNDFBP = s.tradingCommissionNDFBP;
        bp.tradingCommissionSTMBP = s.tradingCommissionSTMBP;
        bp.tradingCommissionMakerBP = s.tradingCommissionMakerBP;
    }

    function _getPremiumCommissionBasisPoints() internal view returns (PolicyCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.premiumCommissionNaymsLtdBP = s.premiumCommissionNaymsLtdBP;
        bp.premiumCommissionNDFBP = s.premiumCommissionNDFBP;
        bp.premiumCommissionSTMBP = s.premiumCommissionSTMBP;
    }
}