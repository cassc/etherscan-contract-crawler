// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "test/contract-mocks/publicStaking/BaseMock.sol";
import "contracts/libraries/StakingNFT/StakingNFT.sol";

contract HugeAccumulatorStaking is StakingNFT {
    uint256 public constant OFFSET_TO_OVERFLOW = 1_000000000000000000;

    constructor() StakingNFT() {}

    function initialize() public onlyFactory initializer {
        __stakingNFTInit("HugeAccumulator", "APS");
        _tokenState.accumulator = uint256(type(uint168).max - OFFSET_TO_OVERFLOW);
        _ethState.accumulator = uint256(type(uint168).max - OFFSET_TO_OVERFLOW);
    }

    function getOffsetToOverflow() public pure returns (uint256) {
        return OFFSET_TO_OVERFLOW;
    }
}