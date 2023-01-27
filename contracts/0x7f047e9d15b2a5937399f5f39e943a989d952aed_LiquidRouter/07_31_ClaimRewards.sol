// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Constants} from "src/libraries/Constants.sol";

import {IFeeDistributor} from "src/interfaces/IFeeDistributor.sol";
import {ILiquidityGauge} from "src/interfaces/ILiquidityGauge.sol";
import {IMultiMerkleStash} from "src/interfaces/IMultiMerkleStash.sol";

/// @title ClaimRewards
/// @notice Enables to claim rewards from various sources.
abstract contract ClaimRewards {
    ///@notice Claims rewards from a MultiMerkleStash contract.
    ///@param multiMerkleStash MultiMerkleStash contract address.
    ///@param token Token address to claim.
    ///@param index Index of the claim.
    ///@param claimer Claimer address.
    ///@param amount Amount of token to claim.
    ///@param merkleProof Merkle proofs to verify the claim.
    function claimBribes(
        address multiMerkleStash,
        address token,
        uint256 index,
        address claimer,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (claimer == Constants.MSG_SENDER) claimer = msg.sender;
        IMultiMerkleStash(multiMerkleStash).claim(token, index, claimer, amount, merkleProof);
    }

    /// @notice Claims multiple rewards from a MultiMerkleStash contract.
    /// @param multiMerkleStash MultiMerkleStash contract address.
    /// @param claimer Claimer address.
    /// @param claims Claims to make.
    function claimBribesMulti(address multiMerkleStash, address claimer, IMultiMerkleStash.claimParam[] calldata claims)
        external
    {
        if (claimer == Constants.MSG_SENDER) claimer = msg.sender;
        IMultiMerkleStash(multiMerkleStash).claimMulti(claimer, claims);
    }

    /// @notice Claims rewards from a FeeDistributor contract.
    /// @param veSDTFeeDistributor FeeDistributor contract address.
    /// @param claimer Claimer address.
    function claimSdFrax3CRV(address veSDTFeeDistributor, address claimer) external {
        if (claimer == Constants.MSG_SENDER) claimer = msg.sender;
        IFeeDistributor(veSDTFeeDistributor).claim(claimer);
    }

    /// @notice Claims rewards from a gauge contract.
    /// @param gauge Gauge contract address.
    /// @param recipient Recipient address.
    function claimGauge(address gauge, address recipient) external {
        _claimGauge(gauge, recipient);
    }

    /// @notice Claims rewards from multiple gauge contracts.
    /// @param gauges Gauge contract addresses.
    /// @param recipient Recipient addresses.
    function claimGaugesMulti(address[] calldata gauges, address recipient) external {
        uint256 length = gauges.length;
        for (uint8 i; i < length;) {
            _claimGauge(gauges[i], recipient);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Implementation of claimGauge.
    function _claimGauge(address gauge, address recipient) internal {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);
        ILiquidityGauge(gauge).claim_rewards_for(msg.sender, recipient);
    }
}