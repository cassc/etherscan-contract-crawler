pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol)

interface ITrancheRegistry {
    struct ImplementationDetails {
        // The reference tranche implementation which is to be cloned
        address implementation;

        // If true, new/additional locks cannot be added into this tranche type
        bool closedForStaking;

        // If true, no staking allowed and these tranches have no rewards
        // to claim or tokens to withdraw. So fully deprecated.
        bool disabled;
    }

    event TrancheCreated(uint256 indexed implId, address indexed tranche, address stakingAddress, address stakingToken);
    event TrancheImplCreated(uint256 indexed implId, address indexed implementation);
    event ImplementationDisabled(uint256 indexed implId, bool value);
    event ImplementationClosedForStaking(uint256 indexed implId, bool value);
    event AddedExistingTranche(uint256 indexed implId, address indexed tranche);

    error OnlyOwnerOperatorTranche(address caller);
    error InvalidTrancheImpl(uint256 implId);
    error TrancheAlreadyExists(address tranche);
    error UnknownTranche(address tranche);

    function createTranche(uint256 _implId) external returns (address tranche, address underlyingGaugeAddress, address stakingToken);
    function implDetails(uint256 _implId) external view returns (ImplementationDetails memory details);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bytes memory);
}