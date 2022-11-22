// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {PERCENTAGE_FACTOR} from "./helpers/Constants.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IGearToken} from "./interfaces/IGearToken.sol";
import {StepVesting} from "./Vesting.sol";
import {IStepVesting} from "./interfaces/IStepVesting.sol";
import {ITokenDistributorOld, VestingContract, VotingPower} from "./interfaces/ITokenDistributorOld.sol";
import {ITokenDistributor, TokenAllocationOpts} from "./interfaces/ITokenDistributor.sol";

contract TokenDistributor is ITokenDistributor {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Address of the treasury
    address public immutable treasury;

    /// @dev Address responsible for managing vesting contracts
    address public distributionController;

    /// @dev GEAR token
    IGearToken public immutable gearToken;

    /// @dev Address of master contract to clone
    address public immutable masterVestingContract;

    /// @dev Mapping from contributor addresses to their active vesting contracts
    mapping(address => EnumerableSet.AddressSet) internal vestingContracts;

    /// @dev Mapping from vesting contracts to their voting power categories
    mapping(address => string) public vestingContractVotingCategory;

    /// @dev Mapping from voting categories to corresponding voting power multipliers
    mapping(string => uint16) public votingCategoryMultipliers;

    /// @dev Mapping from existing voting categories
    mapping(string => bool) public votingCategoryExists;

    /// @dev Set of all known contributors
    EnumerableSet.AddressSet private contributorsSet;

    /// @param addressProvider address of Address provider
    /// @param tokenDistributorOld Address of the previous token distributor
    constructor(IAddressProvider addressProvider, ITokenDistributorOld tokenDistributorOld) {
        masterVestingContract = tokenDistributorOld.masterVestingContract();
        gearToken = IGearToken(addressProvider.getGearToken()); // T:[TD-1]
        treasury = addressProvider.getTreasuryContract();
        distributionController = addressProvider.getTreasuryContract();

        uint16 weightA = uint16(tokenDistributorOld.weightA());
        uint16 weightB = uint16(tokenDistributorOld.weightB());

        _updateVotingCategoryMultiplier("TYPE_A", weightA);
        _updateVotingCategoryMultiplier("TYPE_B", weightB);
        _updateVotingCategoryMultiplier("TYPE_ZERO", 0);

        address[] memory oldContributors = tokenDistributorOld.contributorsList();

        uint256 numOldContributors = oldContributors.length;

        for (uint256 i = 0; i < numOldContributors; ++i) {
            VestingContract memory vc = tokenDistributorOld.vestingContracts(oldContributors[i]);

            address receiver = StepVesting(vc.contractAddress).receiver();

            _addVestingContractForContributor(vc.contractAddress, receiver);

            string memory votingCategory =
                vc.votingPower == VotingPower.A ? "TYPE_A" : vc.votingPower == VotingPower.B ? "TYPE_B" : "TYPE_ZERO";

            vestingContractVotingCategory[vc.contractAddress] = votingCategory;

            emit VestingContractAdded(
                receiver, vc.contractAddress, gearToken.balanceOf(vc.contractAddress), votingCategory
                );
        }
    }

    modifier distributionControllerOnly() {
        if (msg.sender != distributionController) {
            revert NotDistributionControllerException();
        }
        _;
    }

    modifier treasuryOnly() {
        if (msg.sender != treasury) {
            revert NotTreasuryException();
        }
        _;
    }

    /// @dev Returns the total GEAR balance of holder, including vested balances weighted with their respective
    ///      voting category multipliers. Used in snapshot voting.
    /// @param holder Address to calculate the weighted balance for
    function balanceOf(address holder) external view returns (uint256 vestedBalanceWeighted) {
        uint256 numVestingContracts = vestingContracts[holder].length();

        for (uint256 i = 0; i < numVestingContracts; ++i) {
            address vc = vestingContracts[holder].at(i);
            address receiver = IStepVesting(vc).receiver();

            if (receiver == holder) {
                vestedBalanceWeighted += (
                    gearToken.balanceOf(vc) * votingCategoryMultipliers[vestingContractVotingCategory[vc]]
                ) / PERCENTAGE_FACTOR;
            }
        }

        vestedBalanceWeighted += gearToken.balanceOf(holder);
    }

    //
    // VESTING CONTRACT CONTROLS
    //

    /// @dev Creates a batch of new GEAR vesting contracts with passed parameters
    /// @param recipient Address to set as the vesting contract receiver
    /// @param votingCategory The voting category used to determine the vested GEARs' voting weight
    /// @param cliffDuration Time until first payout
    /// @param cliffAmount Size of first payout
    /// @param vestingDuration Time until all tokens are unlocked, starting from cliff
    /// @param vestingNumSteps Number of ticks at which tokens are unlocked
    /// @param vestingAmount Total number of tokens unlocked during the vesting period (excluding cliff)
    function distributeTokens(
        address recipient,
        string calldata votingCategory,
        uint256 cliffDuration,
        uint256 cliffAmount,
        uint256 vestingDuration,
        uint256 vestingNumSteps,
        uint256 vestingAmount
    ) external distributionControllerOnly {

        TokenAllocationOpts memory opts = TokenAllocationOpts({
            recipient: recipient,
            votingCategory: votingCategory,
            cliffDuration: cliffDuration,
            cliffAmount: cliffAmount,
            vestingDuration: vestingDuration,
            vestingNumSteps: vestingNumSteps,
            vestingAmount: vestingAmount
        });

        _deployVestingContract(opts);
    }

    //
    // CONTRIBUTOR HOUSEKEEPING
    //

    /// @dev Updates the receiver on the passed contributor's VCs, if needed
    function updateContributor(address contributor) external {
        _updateContributor(contributor, false);
    }

    /// @dev Updates the receiver on the passed contributor's VCs and cleans up spent contracts
    function cleanupContributor(address contributor) external distributionControllerOnly {
        _updateContributor(contributor, true);
    }

    function _updateContributor(address contributor, bool removeZeroBalance) internal {
        if (!contributorsSet.contains(contributor)) {
            revert ContributorNotRegisteredException(contributor);
        }
        _cleanupContributor(contributor, removeZeroBalance);
    }

    /// @dev Aligns the receiver between this contract
    ///      and vesting contracts, for all recorded contributors
    function updateContributors() external {
        _updateContributors(false);
    }

    /// @dev Cleans up exhausted vesting contracts and aligns the receiver between this contract
    ///      and vesting contracts, for all recorded contributors
    function cleanupContributors() external distributionControllerOnly {
        _updateContributors(true);
    }

    function _updateContributors(bool removeZeroBalance) internal {
        address[] memory contributorsArray = contributorsSet.values();
        uint256 numContributors = contributorsArray.length;

        for (uint256 i = 0; i < numContributors; i++) {
            _cleanupContributor(contributorsArray[i], removeZeroBalance);
        }
    }

    //
    // CONFIGURATION
    //

    /// @dev Updates the voting weight for a particular voting category
    /// @param category The name of the category to update the multiplier for
    /// @param multiplier The voting power weight for all vested GEAR belonging to the category
    function updateVotingCategoryMultiplier(string calldata category, uint16 multiplier) external treasuryOnly {
        _updateVotingCategoryMultiplier(category, multiplier);
    }

    function _updateVotingCategoryMultiplier(string memory category, uint16 multiplier) internal {
        if (multiplier > PERCENTAGE_FACTOR) {
            revert MultiplierValueIncorrect();
        }

        votingCategoryMultipliers[category] = multiplier;
        votingCategoryExists[category] = true;
        emit NewVotingMultiplier(category, multiplier);
    }

    /// @dev Changes the distribution controller
    /// @param newController Address of the new distribution controller
    function setDistributionController(address newController) external treasuryOnly {
        distributionController = newController;
        emit NewDistrubtionController(newController);
    }

    //
    // GETTERS
    //

    /// @dev Returns the number of recorded contributors
    function countContributors() external view returns (uint256) {
        return contributorsSet.length();
    }

    /// @dev Returns the full list of recorded contributors
    function contributorsList() external view returns (address[] memory) {
        address[] memory result = new address[](contributorsSet.length());

        for (uint256 i = 0; i < contributorsSet.length(); i++) {
            result[i] = contributorsSet.at(i);
        }

        return result;
    }

    /// @dev Returns the active vesting contracts for a particular contributor
    function contributorVestingContracts(address contributor) external view returns (address[] memory) {
        return vestingContracts[contributor].values();
    }

    //
    // INTERNAL FUNCTIONS
    //

    /// @dev Deploys a vesting contract for a new allocation
    function _deployVestingContract(
        TokenAllocationOpts memory opts
    ) internal {
        if (!votingCategoryExists[opts.votingCategory]) {
            revert VotingCategoryDoesntExist();
        }
        address vc = Clones.clone(address(masterVestingContract));

        IStepVesting(vc).initialize(
            gearToken,
            block.timestamp,
            opts.cliffDuration,
            opts.vestingDuration / opts.vestingNumSteps,
            opts.cliffAmount,
            opts.vestingAmount / opts.vestingNumSteps,
            opts.vestingNumSteps,
            opts.recipient
        );

        _addVestingContractForContributor(vc, opts.recipient);

        vestingContractVotingCategory[vc] = opts.votingCategory;

        emit VestingContractAdded(opts.recipient, vc, opts.cliffAmount + opts.vestingAmount, opts.votingCategory);
    }

    /// @dev Cleans up all vesting contracts currently belonging to a contributor
    ///      If there are no more active vesting contracts after cleanup, removes
    ///      the contributor from the list
    function _cleanupContributor(address contributor, bool removeZeroBalance) internal {
        address[] memory vcs = vestingContracts[contributor].values();
        uint256 numVestingContracts = vcs.length;

        for (uint256 i = 0; i < numVestingContracts;) {
            address vc = vcs[i];
            _cleanupVestingContract(contributor, vc, removeZeroBalance);

            unchecked {
                ++i;
            }
        }

        if (vestingContracts[contributor].length() == 0) {
            contributorsSet.remove(contributor);
        }
    }

    /// @dev Removes the contract from the list if it was exhausted, or
    ///      updates the associated contributor if the receiver was changed
    function _cleanupVestingContract(address contributor, address vc, bool removeZeroBalance) internal {
        address receiver = IStepVesting(vc).receiver();

        if (gearToken.balanceOf(vc) == 0 && removeZeroBalance) {
            vestingContracts[contributor].remove(vc);
        } else if (receiver != contributor) {
            vestingContracts[contributor].remove(vc);
            _addVestingContractForContributor(vc, receiver);
            emit VestingContractReceiverUpdated(vc, contributor, receiver);
        }
    }

    /// @dev Associates a vesting contract with a contributor, and adds a contributor
    ///      to the list, if it did not exist before
    function _addVestingContractForContributor(address vc, address receiver) internal {
        if (!contributorsSet.contains(receiver)) {
            contributorsSet.add(receiver);
        }

        vestingContracts[receiver].add(vc);
    }
}