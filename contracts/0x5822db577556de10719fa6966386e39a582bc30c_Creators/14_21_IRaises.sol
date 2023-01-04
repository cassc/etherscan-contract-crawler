// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IControllable} from "./IControllable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {IPausable} from "./IPausable.sol";
import {Raise, RaiseParams, RaiseState, Phase, FeeSchedule} from "../structs/Raise.sol";
import {Tier, TierParams} from "../structs/Tier.sol";

interface IRaises is IPausable, IControllable, IAnnotated {
    /// @notice Minting token would exceed the raise's configured maximum amount.
    error ExceedsRaiseMaximum();
    /// @notice The raise's goal has not been met.
    error RaiseGoalNotMet();
    /// @notice The given currency address is unknown, invalid, or denied.
    error InvalidCurrency();
    /// @notice The provided payment amount is incorrect.
    error InvalidPaymentAmount();
    /// @notice The provided Merkle proof is invalid.
    error InvalidProof();
    /// @notice This caller address has minted the maximum number of tokens allowed per address.
    error AddressMintedMaximum();
    /// @notice The raise is not in Cancelled state.
    error RaiseNotCancelled();
    /// @notice The raise is not in Funded state.
    error RaiseNotFunded();
    /// @notice The raise has ended.
    error RaiseEnded();
    /// @notice The raise is no longer in Active state.
    error RaiseInactive();
    /// @notice The raise has not yet ended.
    error RaiseNotEnded();
    /// @notice The raise has started and can no longer be updated.
    error RaiseHasStarted();
    /// @notice The raise has not yet started and is in the Scheduled phase.
    error RaiseNotStarted();
    /// @notice This token tier is sold out, or an attempt to mint would exceed the maximum supply.
    error RaiseSoldOut();
    /// @notice The caller's token balance is zero.
    error ZeroBalance();
    /// @notice One or both fees in the provided fee schedule equal or exceed 100%.
    error InvalidFeeSchedule();

    event CreateRaise(
        uint32 indexed projectId,
        uint32 raiseId,
        RaiseParams params,
        TierParams[] tiers,
        address fanToken,
        address brandToken
    );
    event UpdateRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseParams params, TierParams[] tiers);
    event Mint(
        uint32 indexed projectId,
        uint32 indexed raiseID,
        uint32 indexed tierId,
        address minter,
        uint256 amount,
        bytes32[] proof
    );
    event SettleRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event CancelRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event CloseRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event WithdrawRaiseFunds(
        uint32 indexed projectId, uint32 indexed raiseId, address indexed receiver, address currency, uint256 amount
    );
    event Redeem(
        uint32 indexed projectId,
        uint32 indexed raiseID,
        uint32 indexed tierId,
        address receiver,
        uint256 tokenAmount,
        address owner,
        uint256 refundAmount
    );
    event WithdrawFees(address indexed receiver, address currency, uint256 amount);

    event SetFeeSchedule(FeeSchedule oldFeeSchedule, FeeSchedule newFeeSchedule);
    event SetCreators(address oldCreators, address newCreators);
    event SetProjects(address oldProjects, address newProjects);
    event SetMinter(address oldMinter, address newMinter);
    event SetDeployer(address oldDeployer, address newDeployer);
    event SetTokens(address oldTokens, address newTokens);
    event SetTokenAuth(address oldTokenAuth, address newTokenAuth);

    /// @notice Create a new raise by project ID. May only be called by
    /// approved creators.
    /// @param projectId uint32 project ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param _tiers TierParams[] array of tier configuration parameters structs.
    /// @return raiseId Created raise ID.
    function create(uint32 projectId, RaiseParams memory params, TierParams[] memory _tiers)
        external
        returns (uint32 raiseId);

    /// @notice Update a Scheduled raise by project ID and raise ID. May only be
    /// called while the raise's state is Active and phase is Scheduled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param _tiers TierParams[] array of tier configuration parameters structs.
    function update(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory _tiers) external;

    /// @notice Mint `amount` of tokens to caller for the given `projectId`,
    /// `raiseId`, and `tierId`. Caller must provide ETH or approve ERC20 amount
    /// equal to total cost.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @return tokenId uint256 Minted token ID.
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        payable
        returns (uint256 tokenId);

    /// @notice Mint `amount` of tokens to caller for the given `projectId`,
    /// `raiseId`, and `tierId`. Caller must provide a Merkle proof. Caller must
    /// provide ETH or approve ERC20 amount equal to total cost.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param proof bytes32[] Merkle proof of inclusion on tier allowlist.
    /// @return tokenId uint256 Minted token ID.
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount, bytes32[] memory proof)
        external
        payable
        returns (uint256 tokenId);

    /// @notice Settle a raise in the Active state and Ended phase. Sets raise
    /// state to Funded if the goal has been met. Sets raise state to Cancelled
    /// if the goal has not been met.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function settle(uint32 projectId, uint32 raiseId) external;

    /// @notice Cancel a raise, setting its state to Cancelled. May only be
    /// called by `creators` contract. May only be called while raise state is Active.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function cancel(uint32 projectId, uint32 raiseId) external;

    /// @notice Close a raise. May only be called by `creators` contract. May
    /// only be called if raise state is Active and raise goal is met. Sets
    /// state to Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function close(uint32 projectId, uint32 raiseId) external;

    /// @notice Withdraw raise funds to given `receiver` address. May only be
    /// called by `creators` contract. May only be called if raise state is Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param receiver address send funds to this address.
    function withdraw(uint32 projectId, uint32 raiseId, address receiver) external;

    /// @notice Redeem `amount` of tokens from caller for the given `projectId`,
    /// `raiseId`, and `tierId` and return ETH or ERC20 tokens to caller. May
    /// only be called when raise state is Cancelled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to redeem.
    function redeem(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount) external;

    /// @notice Set a new fee schedule. May only be called by `controller` contract.
    /// @param _feeSchedule FeeSchedule new fee schedule.
    function setFeeSchedule(FeeSchedule calldata _feeSchedule) external;

    /// @notice Withdraw accrued protocol fees for given `currency` to given
    /// `receiver` address. May only be called by `controller` contract.
    /// @param currency address ERC20 token address or special sentinel value for ETH.
    /// @param receiver address send funds to this address.
    function withdrawFees(address currency, address receiver) external;

    /// @notice Get a raise by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Raise struct.
    function getRaise(uint32 projectId, uint32 raiseId) external view returns (Raise memory);

    /// @notice Get a raise's current Phase by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Phase enum member.
    function getPhase(uint32 projectId, uint32 raiseId) external view returns (Phase);

    /// @notice Get all tiers for a given raise by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Array of Tier structs.
    function getTiers(uint32 projectId, uint32 raiseId) external view returns (Tier[] memory);
}