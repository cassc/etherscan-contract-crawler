// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IRoyaltyEngineV1} from "manifoldxyz/IRoyaltyEngineV1.sol";

import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMPairETH} from "../LSSVMPairETH.sol";
import {LSSVMPairERC1155} from "./LSSVMPairERC1155.sol";
import {ILSSVMPairFactoryLike} from "../ILSSVMPairFactoryLike.sol";

/**
 * @title An ERC1155 pair where the token is an ETH
 * @author boredGenius, 0xmons, 0xCygaar
 */
contract LSSVMPairERC1155ETH is LSSVMPairERC1155, LSSVMPairETH {
    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 93;

    constructor(IRoyaltyEngineV1 royaltyEngine) LSSVMPair(royaltyEngine) {}

    /**
     * Public functions
     */

    /**
     * @inheritdoc LSSVMPair
     */
    function pairVariant() public pure virtual override returns (ILSSVMPairFactoryLike.PairVariant) {
        return ILSSVMPairFactoryLike.PairVariant.ERC1155_ETH;
    }

    /**
     * Internal functions
     */

    /**
     * @inheritdoc LSSVMPair
     * @dev see LSSVMPairCloner for params length calculation
     */
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }
}