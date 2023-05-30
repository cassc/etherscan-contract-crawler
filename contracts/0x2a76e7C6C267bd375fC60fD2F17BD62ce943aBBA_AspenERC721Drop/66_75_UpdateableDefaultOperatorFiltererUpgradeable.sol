// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8;

import "../../../api/config/types/OperatorFiltererDataTypes.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

abstract contract UpdateableDefaultOperatorFiltererUpgradeable is DefaultOperatorFiltererUpgradeable {
    IOperatorFiltererDataTypesV0.OperatorFilterer private __operatorFilterer;

    function __UpdateableDefaultOperatorFiltererUpgradeable_init(
        IOperatorFiltererDataTypesV0.OperatorFilterer memory _operatorFilterer
    ) internal onlyInitializing {
        __operatorFilterer = _operatorFilterer;
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init(
            _operatorFilterer.defaultSubscription,
            _operatorFilterer.operatorFilterRegistry
        );
    }

    function getOperatorFiltererDetails() public view returns (IOperatorFiltererDataTypesV0.OperatorFilterer memory) {
        return __operatorFilterer;
    }

    function _setOperatorFilterer(IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer)
        internal
        virtual
    {
        // Note: No need to check here as the flow for setting an operator filterer is by first retrieving it from Aspen Config
        __operatorFilterer = _newOperatorFilterer;
        __DefaultOperatorFilterer_init_internal(
            _newOperatorFilterer.defaultSubscription,
            _newOperatorFilterer.operatorFilterRegistry
        );
    }
}