// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {LibFnPtrs} from "../VMStateBuilder.sol";
import "../RainVM.sol";
import "./erc20/OpERC20BalanceOf.sol";
import "./erc20/OpERC20TotalSupply.sol";
import "./erc20/snapshot/OpERC20SnapshotBalanceOfAt.sol";
import "./erc20/snapshot/OpERC20SnapshotTotalSupplyAt.sol";
import "./erc721/OpERC721BalanceOf.sol";
import "./erc721/OpERC721OwnerOf.sol";
import "./erc1155/OpERC1155BalanceOf.sol";
import "./erc1155/OpERC1155BalanceOfBatch.sol";
import "./evm/OpBlockNumber.sol";
import "./evm/OpCaller.sol";
import "./evm/OpThisAddress.sol";
import "./evm/OpTimestamp.sol";
import "./math/fixedPoint/OpFixedPointScale18.sol";
import "./math/fixedPoint/OpFixedPointScale18Div.sol";
import "./math/fixedPoint/OpFixedPointScale18Mul.sol";
import "./math/fixedPoint/OpFixedPointScaleBy.sol";
import "./math/fixedPoint/OpFixedPointScaleN.sol";
import "./math/logic/OpAny.sol";
import "./math/logic/OpEagerIf.sol";
import "./math/logic/OpEqualTo.sol";
import "./math/logic/OpEvery.sol";
import "./math/logic/OpGreaterThan.sol";
import "./math/logic/OpIsZero.sol";
import "./math/logic/OpLessThan.sol";
import "./math/saturating/OpSaturatingAdd.sol";
import "./math/saturating/OpSaturatingMul.sol";
import "./math/saturating/OpSaturatingSub.sol";
import "./math/OpAdd.sol";
import "./math/OpDiv.sol";
import "./math/OpExp.sol";
import "./math/OpMax.sol";
import "./math/OpMin.sol";
import "./math/OpMod.sol";
import "./math/OpMul.sol";
import "./math/OpSub.sol";
import "./tier/OpITierV2Report.sol";
import "./tier/OpITierV2ReportTimeForTier.sol";
import "./tier/OpSaturatingDiff.sol";
import "./tier/OpSelectLte.sol";
import "./tier/OpUpdateTimesForTierRange.sol";

uint256 constant ALL_STANDARD_OPS_COUNT = 40;
uint256 constant ALL_STANDARD_OPS_LENGTH = RAIN_VM_OPS_LENGTH +
    ALL_STANDARD_OPS_COUNT;

/// @title AllStandardOps
/// @notice RainVM opcode pack to expose all other packs.
library AllStandardOps {
    using LibFnPtrs for bytes;

    function zero(uint256) internal pure returns (uint256) {
        return 0;
    }

    function one(uint256) internal pure returns (uint256) {
        return 1;
    }

    function two(uint256) internal pure returns (uint256) {
        return 2;
    }

    function three(uint256) internal pure returns (uint256) {
        return 3;
    }

    function nonzeroOperandN(uint256 operand_) internal pure returns (uint256) {
        require(operand_ > 0, "0_OPERAND");
        return operand_;
    }

    function stackPopsFnPtrs() internal pure returns (bytes memory fnPtrs_) {
        unchecked {
            fnPtrs_ = new bytes(ALL_STANDARD_OPS_LENGTH * 0x20);
            function(uint256) pure returns (uint256)[ALL_STANDARD_OPS_COUNT]
                memory fns_ = [
                    // erc20 balance of
                    two,
                    // erc20 total supply
                    one,
                    // erc20 snapshot balance of at
                    three,
                    // erc20 snapshot total supply at
                    two,
                    // erc721 balance of
                    two,
                    // erc721 owner of
                    two,
                    // erc1155 balance of
                    three,
                    // erc1155 balance of batch
                    OpERC1155BalanceOfBatch.stackPops,
                    // block number
                    zero,
                    // caller
                    zero,
                    // this address
                    zero,
                    // timestamp
                    zero,
                    // scale18
                    one,
                    // scale18 div
                    two,
                    // scale18 mul
                    two,
                    // scaleBy
                    one,
                    // scaleN
                    one,
                    // any
                    nonzeroOperandN,
                    // eager if
                    three,
                    // equal to
                    two,
                    // every
                    nonzeroOperandN,
                    // greater than
                    two,
                    // iszero
                    one,
                    // less than
                    two,
                    // saturating add
                    nonzeroOperandN,
                    // saturating mul
                    nonzeroOperandN,
                    // saturating sub
                    nonzeroOperandN,
                    // add
                    nonzeroOperandN,
                    // div
                    nonzeroOperandN,
                    // exp
                    nonzeroOperandN,
                    // max
                    nonzeroOperandN,
                    // min
                    nonzeroOperandN,
                    // mod
                    nonzeroOperandN,
                    // mul
                    nonzeroOperandN,
                    // sub
                    nonzeroOperandN,
                    // tier report
                    OpITierV2Report.stackPops,
                    // tier report time for tier
                    OpITierV2ReportTimeForTier.stackPops,
                    // tier saturating diff
                    two,
                    // select lte
                    OpSelectLte.stackPops,
                    // update times for tier range
                    two
                ];
            for (uint256 i_ = 0; i_ < ALL_STANDARD_OPS_COUNT; i_++) {
                fnPtrs_.insertStackMovePtr(i_ + RAIN_VM_OPS_LENGTH, fns_[i_]);
            }
        }
    }

    function stackPushesFnPtrs() internal pure returns (bytes memory fnPtrs_) {
        unchecked {
            fnPtrs_ = new bytes(ALL_STANDARD_OPS_LENGTH * 0x20);
            function(uint256) pure returns (uint256)[ALL_STANDARD_OPS_COUNT]
                memory fns_ = [
                    // erc20 balance of
                    one,
                    // erc20 total supply
                    one,
                    // erc20 snapshot balance of at
                    one,
                    // erc20 snapshot total supply at
                    one,
                    // erc721 balance of
                    one,
                    // erc721 owner of
                    one,
                    // erc1155 balance of
                    one,
                    // erc1155 balance of batch
                    nonzeroOperandN,
                    // block number
                    one,
                    // caller
                    one,
                    // this address
                    one,
                    // timestamp
                    one,
                    // scale18
                    one,
                    // scale18 div
                    one,
                    // scale18 mul
                    one,
                    // scaleBy
                    one,
                    // scaleN
                    one,
                    // any
                    one,
                    // eager if
                    one,
                    // equal to
                    one,
                    // every
                    one,
                    // greater than
                    one,
                    // iszero
                    one,
                    // less than
                    one,
                    // saturating add
                    one,
                    // saturating mul
                    one,
                    // saturating sub
                    one,
                    // add
                    one,
                    // div
                    one,
                    // exp
                    one,
                    // max
                    one,
                    // min
                    one,
                    // mod
                    one,
                    // mul
                    one,
                    // sub
                    one,
                    // tier report
                    one,
                    // tier report time for tier
                    one,
                    // tier saturating diff
                    one,
                    // select lte
                    one,
                    // update times for tier range
                    one
                ];
            for (uint256 i_ = 0; i_ < ALL_STANDARD_OPS_COUNT; i_++) {
                fnPtrs_.insertStackMovePtr(i_ + RAIN_VM_OPS_LENGTH, fns_[i_]);
            }
        }
    }

    function fnPtrs() internal pure returns (bytes memory fnPtrs_) {
        unchecked {
            fnPtrs_ = new bytes(ALL_STANDARD_OPS_LENGTH * 0x20);
            function(uint256, uint256)
                view
                returns (uint256)[ALL_STANDARD_OPS_COUNT]
                memory fns_ = [
                    OpERC20BalanceOf.balanceOf,
                    OpERC20TotalSupply.totalSupply,
                    OpERC20SnapshotBalanceOfAt.balanceOfAt,
                    OpERC20SnapshotTotalSupplyAt.totalSupplyAt,
                    OpERC721BalanceOf.balanceOf,
                    OpERC721OwnerOf.ownerOf,
                    OpERC1155BalanceOf.balanceOf,
                    OpERC1155BalanceOfBatch.balanceOfBatch,
                    OpBlockNumber.blockNumber,
                    OpCaller.caller,
                    OpThisAddress.thisAddress,
                    OpTimestamp.timestamp,
                    OpFixedPointScale18.scale18,
                    OpFixedPointScale18Div.scale18Div,
                    OpFixedPointScale18Mul.scale18Mul,
                    OpFixedPointScaleBy.scaleBy,
                    OpFixedPointScaleN.scaleN,
                    OpAny.any,
                    OpEagerIf.eagerIf,
                    OpEqualTo.equalTo,
                    OpEvery.every,
                    OpGreaterThan.greaterThan,
                    OpIsZero.isZero,
                    OpLessThan.lessThan,
                    OpSaturatingAdd.saturatingAdd,
                    OpSaturatingMul.saturatingMul,
                    OpSaturatingSub.saturatingSub,
                    OpAdd.add,
                    OpDiv.div,
                    OpExp.exp,
                    OpMax.max,
                    OpMin.min,
                    OpMod.mod,
                    OpMul.mul,
                    OpSub.sub,
                    OpITierV2Report.report,
                    OpITierV2ReportTimeForTier.reportTimeForTier,
                    OpSaturatingDiff.saturatingDiff,
                    OpSelectLte.selectLte,
                    OpUpdateTimesForTierRange.updateTimesForTierRange
                ];
            for (uint256 i_ = 0; i_ < ALL_STANDARD_OPS_COUNT; i_++) {
                fnPtrs_.insertOpPtr(i_ + RAIN_VM_OPS_LENGTH, fns_[i_]);
            }
        }
    }
}