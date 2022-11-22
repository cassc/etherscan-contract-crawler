// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Struct containing parameters to initialize a new vesting contract
struct TokenAllocationOpts {
    address recipient;
    string votingCategory;
    uint256 cliffDuration;
    uint256 cliffAmount;
    uint256 vestingDuration;
    uint256 vestingNumSteps;
    uint256 vestingAmount;
}

interface ITokenDistributorExceptions {
    /// @dev Thrown if there is leftover GEAR in the contract after distribution
    error NonZeroBalanceAfterDistributionException(uint256 amount);

    /// @dev Thrown if attempting to do an action for an address that is not a contributor
    error ContributorNotRegisteredException(address user);

    /// @dev Thrown if an access-restricted function is called by other than the treasury multisig
    error NotTreasuryException();

    /// @dev Thrown if an access-restricted function is called by other than the distribution controller
    error NotDistributionControllerException();

    /// @dev Thrown if a voting multiplier value does not pass sanity checks
    error MultiplierValueIncorrect();

    /// @dev Thrown if voting category doesn't exist
    error VotingCategoryDoesntExist();
}

interface ITokenDistributorEvents {
    /// @dev Emits when a multiplier for a voting category is updated
    event NewVotingMultiplier(string indexed category, uint16 multiplier);

    /// @dev Emits when a new distribution controller is set
    event NewDistrubtionController(address newController);

    /// @dev Emits when a new vesting contract is added
    event VestingContractAdded(
        address indexed holder, address indexed vestingContract, uint256 amount, string votingPowerCategory
    );

    /// @dev Emits when the contributor associated with a vesting contract is changed
    event VestingContractReceiverUpdated(
        address indexed vestingContract, address indexed prevReceiver, address indexed newReceiver
    );
}

interface ITokenDistributor is ITokenDistributorExceptions, ITokenDistributorEvents {
    function distributeTokens(TokenAllocationOpts calldata opts) external;

    function updateContributor(address contributor) external;

    function updateContributors() external;

    function updateVotingCategoryMultiplier(string calldata category, uint16 multiplier) external;

    function balanceOf(address holder) external view returns (uint256 vestedBalanceWeighted);

    function countContributors() external view returns (uint256);

    function contributorsList() external view returns (address[] memory);

    function contributorVestingContracts(address contributor) external view returns (address[] memory);
}