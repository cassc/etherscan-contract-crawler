// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {ApeCoinStaking} from "../dependencies/yoga-labs/ApeCoinStaking.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPoolPositionMover {
    function movePositionFromBendDAO(uint256[] calldata loanIds) external;

    //# Migration step
    //
    //0. User needs to breakup P2P orders on their own
    //1. Repay Debt
    //   1. if it's cAPE then deposit borrowed APE into old cAPE pool then repay
    //   2. if it's not then just repay with borrowed tokens
    //2. burn old NToken
    //   1. move old NToken to new Pool, if it's staking BAYC/MAYC/BAKC it'll be automatically unstaked
    //   2. withdrawERC721 and specify new NToken as recipient
    //   3. mint new NToken
    //3. burn old PToken
    //   1. move old PToken to new Pool
    //   2. withdraw and specify new PToken as recipient
    //   3. mint new NToken
    //4. Mint new debt
    function movePositionFromParaSpace(
        DataTypes.ParaSpacePositionMoveInfo calldata moveInfo
    ) external;

    function claimUnderlying(
        address[] calldata assets,
        uint256[][] calldata agreementIds
    ) external;
}