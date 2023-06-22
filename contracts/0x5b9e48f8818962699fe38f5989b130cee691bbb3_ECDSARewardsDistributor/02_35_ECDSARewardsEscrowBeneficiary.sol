pragma solidity 0.5.17;

import "@keep-network/keep-core/contracts/PhasedEscrow.sol";

/// @title ECDSARewardsEscrowBeneficiary
/// @notice Transfer the received tokens from PhasedEscrow to a designated
///         ECDSARewards contract.
contract ECDSARewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}

/// @title ECDSABackportRewardsEscrowBeneficiary
/// @notice Trasfer the received tokens from Phased Escrow to a designated
///         ECDSABackportRewards contract.
contract ECDSABackportRewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}