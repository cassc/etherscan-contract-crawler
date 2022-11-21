// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibTokenAsset.sol";

library LibReward {
    using LibTokenAsset for LibTokenAsset.TokenAsset;

    struct Reward {
        address recipient;
        LibTokenAsset.TokenAsset asset;
        uint256 commission;
        uint256 salt;
    }

    bytes32 constant REWARD_TYPEHASH =
        keccak256(
            "Reward(address recipient,TokenAsset asset,uint256 commission,uint256 salt)TokenAsset(address token,uint256 amount)"
        );

    function hash(Reward calldata reward) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    REWARD_TYPEHASH,
                    reward.recipient,
                    reward.asset.hash(),
                    reward.commission,
                    reward.salt
                )
            );
    }
}