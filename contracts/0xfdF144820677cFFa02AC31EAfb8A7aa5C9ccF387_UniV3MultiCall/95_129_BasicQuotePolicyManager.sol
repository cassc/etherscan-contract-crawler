// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {DataTypesPeerToPeer} from "../DataTypesPeerToPeer.sol";
import {DataTypesBasicPolicies} from "./DataTypesBasicPolicies.sol";
import {Constants} from "../../Constants.sol";
import {Errors} from "../../Errors.sol";
import {IAddressRegistry} from "../interfaces/IAddressRegistry.sol";
import {ILenderVaultImpl} from "../interfaces/ILenderVaultImpl.sol";
import {IQuotePolicyManager} from "../interfaces/policyManagers/IQuotePolicyManager.sol";

contract BasicQuotePolicyManager is IQuotePolicyManager {
    mapping(address => DataTypesBasicPolicies.GlobalPolicy)
        internal _globalQuotingPolicies;
    mapping(address => mapping(address => mapping(address => DataTypesBasicPolicies.PairPolicy)))
        internal _pairQuotingPolicies;
    mapping(address => bool) internal _hasGlobalQuotingPolicy;
    mapping(address => mapping(address => mapping(address => bool)))
        internal _hasPairQuotingPolicy;
    address public immutable addressRegistry;

    constructor(address _addressRegistry) {
        addressRegistry = _addressRegistry;
    }

    // @dev: When no global policy is set (default case), all pairs are automatically blocked except
    // for those where a pair policy is explicitly set. In the case where a global policy is set,
    // all pairs are assumed to be allowed (no blocking).
    function setGlobalPolicy(
        address lenderVault,
        bytes calldata globalPolicyData
    ) external {
        // @dev: global policy applies across all pairs;
        // note: pair policies (if defined) take precedence over global policy
        _checkIsVaultAndSenderIsOwner(lenderVault);
        if (globalPolicyData.length > 0) {
            DataTypesBasicPolicies.GlobalPolicy memory globalPolicy = abi
                .decode(
                    globalPolicyData,
                    (DataTypesBasicPolicies.GlobalPolicy)
                );
            DataTypesBasicPolicies.GlobalPolicy
                memory currGlobalPolicy = _globalQuotingPolicies[lenderVault];
            if (
                globalPolicy.requiresOracle ==
                currGlobalPolicy.requiresOracle &&
                _equalQuoteBounds(
                    globalPolicy.quoteBounds,
                    currGlobalPolicy.quoteBounds
                )
            ) {
                revert Errors.PolicyAlreadySet();
            }
            _checkNewQuoteBounds(globalPolicy.quoteBounds);
            if (!_hasGlobalQuotingPolicy[lenderVault]) {
                _hasGlobalQuotingPolicy[lenderVault] = true;
            }
            _globalQuotingPolicies[lenderVault] = globalPolicy;
        } else {
            if (!_hasGlobalQuotingPolicy[lenderVault]) {
                revert Errors.NoPolicyToDelete();
            }
            delete _hasGlobalQuotingPolicy[lenderVault];
            delete _globalQuotingPolicies[lenderVault];
        }
        emit GlobalPolicySet(lenderVault, globalPolicyData);
    }

    // @dev: If no global policy is set, then setting a pair policy allows one to explicitly unblock a specific pair;
    // in the other case where a global policy is set, setting a pair policy allows overwriting global policy
    // parameters as well as overwriting minimum signer threshold requirements.
    function setPairPolicy(
        address lenderVault,
        address collToken,
        address loanToken,
        bytes calldata pairPolicyData
    ) external {
        // @dev: pair policies (if defined) take precedence over global policy
        _checkIsVaultAndSenderIsOwner(lenderVault);
        if (collToken == address(0) || loanToken == address(0)) {
            revert Errors.InvalidAddress();
        }
        mapping(address => bool)
            storage _hasSingleQuotingPolicy = _hasPairQuotingPolicy[
                lenderVault
            ][collToken];
        if (pairPolicyData.length > 0) {
            DataTypesBasicPolicies.PairPolicy memory singlePolicy = abi.decode(
                pairPolicyData,
                (DataTypesBasicPolicies.PairPolicy)
            );
            DataTypesBasicPolicies.PairPolicy
                memory currSinglePolicy = _pairQuotingPolicies[lenderVault][
                    collToken
                ][loanToken];
            if (
                singlePolicy.requiresOracle ==
                currSinglePolicy.requiresOracle &&
                singlePolicy.minNumOfSignersOverwrite ==
                currSinglePolicy.minNumOfSignersOverwrite &&
                singlePolicy.minLoanPerCollUnit ==
                currSinglePolicy.minLoanPerCollUnit &&
                singlePolicy.maxLoanPerCollUnit ==
                currSinglePolicy.maxLoanPerCollUnit &&
                _equalQuoteBounds(
                    singlePolicy.quoteBounds,
                    currSinglePolicy.quoteBounds
                )
            ) {
                revert Errors.PolicyAlreadySet();
            }
            _checkNewQuoteBounds(singlePolicy.quoteBounds);
            if (
                singlePolicy.minLoanPerCollUnit == 0 ||
                singlePolicy.minLoanPerCollUnit >
                singlePolicy.maxLoanPerCollUnit
            ) {
                revert Errors.InvalidLoanPerCollBounds();
            }
            if (!_hasSingleQuotingPolicy[loanToken]) {
                _hasSingleQuotingPolicy[loanToken] = true;
            }
            _pairQuotingPolicies[lenderVault][collToken][
                loanToken
            ] = singlePolicy;
        } else {
            if (!_hasSingleQuotingPolicy[loanToken]) {
                revert Errors.NoPolicyToDelete();
            }
            delete _hasSingleQuotingPolicy[loanToken];
            delete _pairQuotingPolicies[lenderVault][collToken][loanToken];
        }
        emit PairPolicySet(lenderVault, collToken, loanToken, pairPolicyData);
    }

    function isAllowed(
        address /*borrower*/,
        address lenderVault,
        DataTypesPeerToPeer.GeneralQuoteInfo calldata generalQuoteInfo,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple
    )
        external
        view
        returns (bool _isAllowed, uint256 minNumOfSignersOverwrite)
    {
        DataTypesBasicPolicies.GlobalPolicy
            memory globalPolicy = _globalQuotingPolicies[lenderVault];
        bool hasPairPolicy = _hasPairQuotingPolicy[lenderVault][
            generalQuoteInfo.collToken
        ][generalQuoteInfo.loanToken];
        if (!_hasGlobalQuotingPolicy[lenderVault] && !hasPairPolicy) {
            return (false, 0);
        }

        // @dev: pair policy (if defined) takes precedence over global policy
        bool hasOracle = generalQuoteInfo.oracleAddr != address(0);
        bool checkLoanPerColl;
        bool requiresOracle;
        uint256[2] memory minMaxLoanPerCollUnit;
        DataTypesBasicPolicies.QuoteBounds memory quoteBounds;
        if (hasPairPolicy) {
            DataTypesBasicPolicies.PairPolicy
                memory singlePolicy = _pairQuotingPolicies[lenderVault][
                    generalQuoteInfo.collToken
                ][generalQuoteInfo.loanToken];
            quoteBounds = singlePolicy.quoteBounds;
            minMaxLoanPerCollUnit[0] = singlePolicy.minLoanPerCollUnit;
            minMaxLoanPerCollUnit[1] = singlePolicy.maxLoanPerCollUnit;
            requiresOracle = singlePolicy.requiresOracle;
            minNumOfSignersOverwrite = singlePolicy.minNumOfSignersOverwrite;
            checkLoanPerColl = !hasOracle;
        } else {
            quoteBounds = globalPolicy.quoteBounds;
            requiresOracle = globalPolicy.requiresOracle;
        }

        if (requiresOracle && !hasOracle) {
            return (false, 0);
        }

        return (
            _isAllowedWithBounds(
                quoteBounds,
                minMaxLoanPerCollUnit,
                quoteTuple,
                generalQuoteInfo.earliestRepayTenor,
                hasOracle,
                checkLoanPerColl
            ),
            minNumOfSignersOverwrite
        );
    }

    function globalQuotingPolicy(
        address lenderVault
    ) external view returns (DataTypesBasicPolicies.GlobalPolicy memory) {
        if (!_hasGlobalQuotingPolicy[lenderVault]) {
            revert Errors.NoPolicy();
        }
        return _globalQuotingPolicies[lenderVault];
    }

    function pairQuotingPolicy(
        address lenderVault,
        address collToken,
        address loanToken
    ) external view returns (DataTypesBasicPolicies.PairPolicy memory) {
        if (!_hasPairQuotingPolicy[lenderVault][collToken][loanToken]) {
            revert Errors.NoPolicy();
        }
        return _pairQuotingPolicies[lenderVault][collToken][loanToken];
    }

    function hasGlobalQuotingPolicy(
        address lenderVault
    ) external view returns (bool) {
        return _hasGlobalQuotingPolicy[lenderVault];
    }

    function hasPairQuotingPolicy(
        address lenderVault,
        address collToken,
        address loanToken
    ) external view returns (bool) {
        return _hasPairQuotingPolicy[lenderVault][collToken][loanToken];
    }

    function _checkIsVaultAndSenderIsOwner(address lenderVault) internal view {
        if (!IAddressRegistry(addressRegistry).isRegisteredVault(lenderVault)) {
            revert Errors.UnregisteredVault();
        }
        if (ILenderVaultImpl(lenderVault).owner() != msg.sender) {
            revert Errors.InvalidSender();
        }
    }

    function _equalQuoteBounds(
        DataTypesBasicPolicies.QuoteBounds memory quoteBounds1,
        DataTypesBasicPolicies.QuoteBounds memory quoteBounds2
    ) internal pure returns (bool isEqual) {
        if (
            quoteBounds1.minTenor == quoteBounds2.minTenor &&
            quoteBounds1.maxTenor == quoteBounds2.maxTenor &&
            quoteBounds1.minFee == quoteBounds2.minFee &&
            quoteBounds1.minApr == quoteBounds2.minApr &&
            quoteBounds1.minLtv == quoteBounds2.minLtv &&
            quoteBounds1.maxLtv == quoteBounds2.maxLtv
        ) {
            isEqual = true;
        }
    }

    function _checkNewQuoteBounds(
        DataTypesBasicPolicies.QuoteBounds memory quoteBounds
    ) internal pure {
        // @dev: allow minTenor == 0 to enable swaps
        if (quoteBounds.minTenor > quoteBounds.maxTenor) {
            revert Errors.InvalidTenorBounds();
        }
        if (
            quoteBounds.minLtv == 0 || quoteBounds.minLtv > quoteBounds.maxLtv
        ) {
            revert Errors.InvalidLtvBounds();
        }
        if (quoteBounds.minApr + int(Constants.BASE) <= 0) {
            revert Errors.InvalidMinApr();
        }
        // @dev: if minFee = BASE, then only swaps will be allowed
        if (quoteBounds.minFee > Constants.BASE) {
            revert Errors.InvalidMinFee();
        }
    }

    function _isAllowedWithBounds(
        DataTypesBasicPolicies.QuoteBounds memory quoteBounds,
        uint256[2] memory minMaxLoanPerCollUnit,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple,
        uint256 earliestRepayTenor,
        bool checkLtv,
        bool checkLoanPerColl
    ) internal pure returns (bool) {
        if (
            quoteTuple.tenor < quoteBounds.minTenor ||
            quoteTuple.tenor > quoteBounds.maxTenor
        ) {
            return false;
        }

        if (checkLtv) {
            // @dev: check either against LTV bounds
            if (
                quoteTuple.loanPerCollUnitOrLtv < quoteBounds.minLtv ||
                quoteTuple.loanPerCollUnitOrLtv > quoteBounds.maxLtv
            ) {
                return false;
            }
        } else if (
            // @dev: only check against absolute loan-per-coll bounds on pair policy and if no oracle
            checkLoanPerColl &&
            (quoteTuple.loanPerCollUnitOrLtv < minMaxLoanPerCollUnit[0] ||
                quoteTuple.loanPerCollUnitOrLtv > minMaxLoanPerCollUnit[1])
        ) {
            return false;
        }

        // @dev: if tenor is zero then tx is swap and no need to check apr
        if (quoteTuple.tenor > 0) {
            int256 apr = (quoteTuple.interestRatePctInBase *
                SafeCast.toInt256(Constants.YEAR_IN_SECONDS)) /
                SafeCast.toInt256(quoteTuple.tenor);
            if (apr < quoteBounds.minApr) {
                return false;
            }
            // @dev: disallow if negative apr and earliest repay is below bound
            if (
                apr < 0 &&
                earliestRepayTenor < quoteBounds.minEarliestRepayTenor
            ) {
                return false;
            }

            // @dev: only check upfront fee for loans (can skip for swaps where tenor=0)
            if (quoteTuple.upfrontFeePctInBase < quoteBounds.minFee) {
                return false;
            }
        }

        return true;
    }
}