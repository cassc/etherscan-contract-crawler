// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IRoyaltyEngineV1} from "manifoldxyz/IRoyaltyEngineV1.sol";

import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMPairETH} from "../LSSVMPairETH.sol";
import {LSSVMPairERC721} from "./LSSVMPairERC721.sol";
import {ILSSVMPairFactoryLike} from "../ILSSVMPairFactoryLike.sol";

/**
 * @title An NFT/Token pair where the token is ETH
 * @author boredGenius, 0xmons, 0xCygaar
 */
contract LSSVMPairERC721ETH is LSSVMPairERC721, LSSVMPairETH {
    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    constructor(IRoyaltyEngineV1 royaltyEngine) LSSVMPair(royaltyEngine) {}

    /**
     * Public functions
     */

    /**
     * @inheritdoc LSSVMPair
     */
    function pairVariant() public pure override returns (ILSSVMPairFactoryLike.PairVariant) {
        return ILSSVMPairFactoryLike.PairVariant.ERC721_ETH;
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