// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {GenericErrors} from "./GenericErrors.sol";

import "hardhat/console.sol";

library LibFeeCollect {
    /// Types ///
    bytes32 internal constant NAMESPACE =
        keccak256("com.miraidon.library.feecollect");
    uint256 internal constant DENOMINATOR = 1e6;

    struct Storage {
        address recipient;
        uint256 numerator; // base 1e6
    }

    /// View ///

    function fix(uint256 minAmount) internal view returns (uint256 fixAmount) {
        return minAmount - (minAmount * getStorage().numerator) / DENOMINATOR;
    }

    /// Mutation ///

    /// @dev fetch local storage
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}