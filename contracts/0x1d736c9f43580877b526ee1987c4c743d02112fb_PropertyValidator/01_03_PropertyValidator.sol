// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IPropertyValidator} from "./interfaces/zeroex-v4/IPropertyValidator.sol";
import {IHookCallOption} from "./interfaces/IHookCallOption.sol";

library Types {
    enum Operation {
        Ignore,
        LessThanOrEqualTo,
        GreaterThanOrEqualTo,
        Equal
    }
}

contract PropertyValidator is IPropertyValidator {
    function validateProperty(
        address tokenAddress,
        uint256 tokenId,
        bytes calldata propertyData
    ) external view override {
        (
            uint256 strikePrice,
            Types.Operation strikePriceOperation,
            uint256 expiry,
            Types.Operation expiryOperation
        ) = abi.decode(
                propertyData,
                (uint256, Types.Operation, uint256, Types.Operation)
            );

        IHookCallOption optionContract = IHookCallOption(tokenAddress);

        compare(
            optionContract.getStrikePrice(tokenId),
            strikePrice,
            strikePriceOperation
        );

        compare(optionContract.getExpiration(tokenId), expiry, expiryOperation);
    }

    function compare(
        uint256 actual,
        uint256 comparingTo,
        Types.Operation operation
    ) internal pure {
        if (operation == Types.Operation.Equal) {
            require(actual == comparingTo, "values are not equal");
        } else if (operation == Types.Operation.LessThanOrEqualTo) {
            require(
                actual <= comparingTo,
                "actual value is not <= comparison value"
            );
        } else if (operation == Types.Operation.GreaterThanOrEqualTo) {
            require(
                actual >= comparingTo,
                "actual value is not >= comparison value"
            );
        }
    }

    function encode(
        uint256 strikePrice,
        Types.Operation strikePriceOperation,
        uint256 expiry,
        Types.Operation expiryOperation
    ) external pure returns (bytes memory) {
        return
            abi.encode(
                strikePrice,
                strikePriceOperation,
                expiry,
                expiryOperation
            );
    }
}