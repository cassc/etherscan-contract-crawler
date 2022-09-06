// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IAdventurerHolding is IERC721ReceiverUpgradeable {
    struct StakedToken {
        address user;
        uint64 timeStaked;
        uint64 index;
    }

    enum SummonOption {
        Claimed,
        NFTUnclaimed,
        HoldingUnclaimed
    }

    /// ERRORS

    /// @notice reverts when a user tries to do an operation on a token they didn't stake
    error UserNotStaker();
    /// @notice reverts when an operation is attempted on a token that is not in the smart contract
    error TokenNotStaked();
    /// @notice reverts when a token is attempted to be withdrawn before its lock in period is over
    error TokenLocked();
    /// @notice reverts when a user attempts a summon option that doesn't exist
    error InvalidSummonOption();
    /// @notice reverts when a user attempts an operation which requires more chronos than they possess
    error InsufficientChronos();
    /// @notice reverts when a zero address is passed in as a potential admin or smart contract location
    error CannotBeZeroAddress();
    /// @notice reverts when a token cannot be used to summon, either because it's Gen 2 or not made available
    error TokenCannotBeUsedToSummon();

    /// EVENTS

    /// @notice Emits when a user stakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being staked.
    /// @param token the tokenId of the Adventurer NFT being staked.
    event StartStake(address indexed owner, uint256 token);

    /// @notice Emits when a user unstakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being unstaked.
    /// @param token the tokenId of the Adventurer NFT being unstaked.
    /// @param success whether or not the user staked the NFT for more than 90 days.
    /// @param duration the duration the NFT was staked for.
    event Unstake(
        address indexed owner,
        uint256 token,
        bool success,
        uint256 duration
    );

    /// @notice Emits when a user burns an NFT.
    /// @param owner the wallet address of the owner of the NFT being burned.
    /// @param token the tokenId of the NFT being burned
    event Burn(address indexed owner, uint256 token);

    /// VIEW FUNCTIONS

    /// @notice returns a list of currently staked tokens by a given address
    /// @param _address the address whose tokens are being queried
    /// @return the list of tokenIds as uint256[] memory
    /// @dev because stakes are not stored per user, we are forced to iterate through all possible tokenIds
    function viewStakes(address _address)
        external
        view
        returns (uint256[] memory);

    /// @notice returns a list of currently staked tokens by a given list of active status bits
    /// @param status the list of bits that are being queried for
    /// @return the list of tokenIds as uint256[] memory
    function viewStakesByStatus(uint8[] memory status)
        external
        view
        returns (uint256[] memory);

    /// @notice returns a list of currently available shared summoners
    /// @return the list of tokenIds as uint256[] memory
    /// @dev because someone could hardcode a non-summonable token to be available for summoning, this function filters only by tokenIds that can be used to summon in order to prevent users wasting gas attempting summon with an non-summonable token.
    function viewSharedSummoners() external view returns (uint256[] memory);

    /// @notice calculates the amount of Chronos accrued by a given user through staked NFTs
    /// @param _address the user whose accrued Chronos is being calculated
    /// @return amount of chronos accrued by user
    function getAccruedChronos(address _address)
        external
        view
        returns (uint256);

    /// @notice calculates the cost of summoning depending on whether its a shared summon
    /// @param _shared whether the summon is a shared summon
    /// @return amount of chronos it will cost to summon
    function getSummonCost(bool _shared) external view returns (uint256);

    /// FUNCTIONS

    /// @notice Stakes a user's NFT
    /// @param token the tokenId of the NFT to be staked
    function stake(uint256 token) external;

    /// @notice Stakes serveral of a user's NFTs
    /// @param tokens the tokenId of the NFT to be staked
    function groupStake(uint256[] memory tokens) external;

    /// @notice Retrieves a user's NFT from the staking contract
    /// @param token the tokenId of the staked NFT
    function unstake(uint256 token) external;

    /// @notice Unstakes serveral of a user's NFTs
    /// @param token the tokenId of the NFT to be staked
    function groupUnstake(uint256[] memory token) external;

    /// @notice Sets whether an NFT is available for Summoning
    /// @param token the tokenId that's being set
    /// @param status whether the token is available for summoning
    function setSummoning(uint256 token, bool status) external;

    /// @notice Sets whether several NFTS are available for Summoning
    /// @param tokens a list of tokenId's that are being set
    /// @param status whether the tokens will be availabe for summoning
    function batchSetSummoning(uint256[] memory tokens, bool status) external;

    /// @notice Sets several status bits at once
    /// @param token the tokenId being set
    /// @param bits which bits will be set
    function setStatus(uint256 token, uint8[] memory bits) external;

    /// @notice Sets several status bits of several NFTs at once
    /// @param tokens the tokenIds being set
    /// @param bits which bits will be set
    function batchSetStatus(uint256[] memory tokens, uint8[] memory bits)
        external;

    /// @notice Uses a token available for summoning to summon a new adventurer
    /// @param token the user's token that they want to use for summoning
    /// @param summoner the token they wish to summon with
    /// @param option where to use the chronos from
    /// @param swapped whether the summoner should instead come first in the summon call
    function sharedSummon(
        uint256 token,
        uint256 summoner,
        uint8 option,
        bool swapped
    ) external;

    /// @notice Uses a token available for summoning to summon a new adventurer
    /// @param token1 the user's first token that they want to use for summoning
    /// @param token2 the user's second token that they want to use for summoning
    /// @param option where to use the chronos from
    function summon(
        uint256 token1,
        uint256 token2,
        uint8 option
    ) external;

    /// @notice Prevents a token being unstaked until the period has passed
    /// @param token the tokenId being locked in
    /// @param period the period that the token is locked in
    function lockToken(uint256 token, uint256 period) external;

    /// @notice Sends a staked token to the zero address
    /// @param token the tokenId that's being burned
    function burnToken(uint256 token) external;

    /// @notice Sends several staked tokens to the zero address
    /// @param tokens the tokens that will be sent to the zero address
    function batchBurnTokens(uint256[] memory tokens) external;

    /// @notice Prevents multiple tokens being unstaked until the period has passed
    /// @param tokens the tokenIds being locked in
    /// @param period the period that the tokens are locked in
    function groupLockTokens(uint256[] memory tokens, uint256 period) external;

    /// @notice Updates whether or not Chronos is granted on unstake
    /// @param _grant the new status of Chronos granting
    function setGrantChronos(bool _grant) external;

    /// @notice Sets the Lock-In time for all tokens after stake
    /// @param lockin the
    function setLockIn(uint256 lockin) external;

    /// @notice Claims all chronos due to msg.sender
    function claimChronos() external;

    /// @notice Gives an address the ability to lock in tokens for a set duration
    /// @param user the address that is being given the permission
    function addLockInRole(address user) external;
}