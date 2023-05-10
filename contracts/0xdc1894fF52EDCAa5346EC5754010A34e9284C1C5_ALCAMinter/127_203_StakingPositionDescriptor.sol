// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import "contracts/libraries/metadata/StakingDescriptor.sol";
import "contracts/interfaces/IStakingNFTDescriptor.sol";

/// @custom:salt StakingPositionDescriptor
/// @custom:deploy-type deployUpgradeable
contract StakingPositionDescriptor is IStakingNFTDescriptor {
    function tokenURI(
        IStakingNFT _stakingNFT,
        uint256 tokenId
    ) external view override returns (string memory) {
        (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        ) = _stakingNFT.getPosition(tokenId);

        return
            StakingDescriptor.constructTokenURI(
                StakingDescriptor.ConstructTokenURIParams({
                    tokenId: tokenId,
                    shares: shares,
                    freeAfter: freeAfter,
                    withdrawFreeAfter: withdrawFreeAfter,
                    accumulatorEth: accumulatorEth,
                    accumulatorToken: accumulatorToken
                })
            );
    }
}