//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @notice Interface containing OS operator filterer inputs shared throughout Dynamic Blueprint system
 * @author Ohimire Labs
 */
interface IOperatorFilterer {
    /**
     * @notice Shared operator filterer inputs
     * @param operatorFilterRegistryAddress Address of OpenSea's operator filter registry contract
     * @param coriCuratedSubscriptionAddress Address of CORI canonical filtered-list
     *                                       (Async's filtered list will update in accordance with this parameter)
     */
    struct OperatorFiltererInputs {
        address operatorFilterRegistryAddress;
        address coriCuratedSubscriptionAddress;
    }
}