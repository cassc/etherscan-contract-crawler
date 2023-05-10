// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCB.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableLiquidityProviderStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/interfaces/IDistribution.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/libraries/errors/DistributionErrors.sol";

/// @custom:salt Distribution
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group alcb
/// @custom:deploy-group-index 1
contract Distribution is
    IDistribution,
    MagicEthTransfer,
    EthSafeTransfer,
    ImmutableFactory,
    ImmutableALCB,
    ImmutablePublicStaking,
    ImmutableValidatorStaking,
    ImmutableLiquidityProviderStaking,
    ImmutableFoundation
{
    // Scaling factor to get the staking percentages
    uint256 public constant PERCENTAGE_SCALE = 1000;

    // Value of the percentages that will send to each staking contract. Divide
    // this value by PERCENTAGE_SCALE = 1000 to get the corresponding percentages.
    // These values must sum to 1000.
    uint256 internal immutable _protocolFeeSplit;
    uint256 internal immutable _publicStakingSplit;
    uint256 internal immutable _liquidityProviderStakingSplit;
    uint256 internal immutable _validatorStakingSplit;

    constructor(
        uint256 validatorStakingSplit_,
        uint256 publicStakingSplit_,
        uint256 liquidityProviderStakingSplit_,
        uint256 protocolFeeSplit_
    )
        ImmutableFactory(msg.sender)
        ImmutableALCB()
        ImmutablePublicStaking()
        ImmutableValidatorStaking()
        ImmutableLiquidityProviderStaking()
        ImmutableFoundation()
    {
        if (
            validatorStakingSplit_ +
                publicStakingSplit_ +
                liquidityProviderStakingSplit_ +
                protocolFeeSplit_ !=
            PERCENTAGE_SCALE
        ) {
            revert DistributionErrors.SplitValueSumError();
        }
        _validatorStakingSplit = validatorStakingSplit_;
        _publicStakingSplit = publicStakingSplit_;
        _liquidityProviderStakingSplit = liquidityProviderStakingSplit_;
        _protocolFeeSplit = protocolFeeSplit_;
    }

    function depositEth(uint8 magic_) public payable checkMagic(magic_) onlyALCB {
        _distribute();
    }

    /// Gets the value of the percentages that will send to each staking contract.
    /// Divide this value by PERCENTAGE_SCALE = 1000 to get the corresponding
    /// percentages.
    function getSplits() public view returns (uint256, uint256, uint256, uint256) {
        return (
            _validatorStakingSplit,
            _publicStakingSplit,
            _liquidityProviderStakingSplit,
            _protocolFeeSplit
        );
    }

    /// Distributes the yields from the ALCB minting to all stake holders.
    function _distribute() internal returns (bool) {
        uint256 excess = address(this).balance;
        // take out protocolFeeShare from excess and decrement excess
        uint256 protocolFeeShare = (excess * _protocolFeeSplit) / PERCENTAGE_SCALE;
        // split remaining between validators, stakers and lp stakers
        uint256 publicStakingShare = (excess * _publicStakingSplit) / PERCENTAGE_SCALE;
        uint256 lpStakingShare = (excess * _liquidityProviderStakingSplit) / PERCENTAGE_SCALE;
        // then give validators the rest
        uint256 validatorStakingShare = excess -
            (protocolFeeShare + publicStakingShare + lpStakingShare);

        if (protocolFeeShare != 0) {
            _safeTransferEthWithMagic(IMagicEthTransfer(_foundationAddress()), protocolFeeShare);
        }
        if (publicStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_publicStakingAddress()),
                publicStakingShare
            );
        }
        if (lpStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_liquidityProviderStakingAddress()),
                lpStakingShare
            );
        }
        if (validatorStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_validatorStakingAddress()),
                validatorStakingShare
            );
        }
        // invariants hold
        return true;
    }
}