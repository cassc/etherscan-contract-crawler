// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../../config/types/OperatorFiltererDataTypes.sol";
import "../../config/IGlobalConfig.sol";

interface IDropFactoryDataTypesV0 {
    struct DropConfig {
        address dropDelegateLogic;
        IGlobalConfigV0 aspenConfig;
        TokenDetails tokenDetails;
        FeeDetails feeDetails;
        IOperatorFiltererDataTypesV0.OperatorFilterer operatorFilterer;
    }

    struct TokenDetails {
        address defaultAdmin;
        string name;
        string symbol;
        string contractURI;
        address[] trustedForwarders;
        string userAgreement;
    }

    struct FeeDetails {
        address saleRecipient;
        address royaltyRecipient;
        uint128 royaltyBps;
    }
}