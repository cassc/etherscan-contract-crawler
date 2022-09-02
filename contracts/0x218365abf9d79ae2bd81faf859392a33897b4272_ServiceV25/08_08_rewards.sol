// SPDX-License-Identifier: MIT
//pragma solidity 0.6.12;
pragma solidity >=0.6.0;

import "./SafeMath.sol";

library rewards {

    using SafeMath for uint256;

    function blocks(uint256 lastClaimedOnBlock, uint256 newRewardBlock, uint256 blockNumber) internal pure returns (uint256[2] memory) {
        if (lastClaimedOnBlock >= blockNumber) return [uint256(0), uint256(0)];

        if (blockNumber <= newRewardBlock || newRewardBlock == 0) {
            return [blockNumber.sub(lastClaimedOnBlock), uint256(0)];
        }
        else if (lastClaimedOnBlock >= newRewardBlock) {
            return [uint256(0), blockNumber.sub(lastClaimedOnBlock)];
        }
        else {
            return [newRewardBlock.sub(lastClaimedOnBlock), blockNumber.sub(newRewardBlock)];
        }
    }

}