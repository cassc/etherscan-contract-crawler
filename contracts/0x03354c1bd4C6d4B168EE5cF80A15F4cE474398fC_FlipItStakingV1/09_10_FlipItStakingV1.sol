// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IFlipItMinter } from "./IFlipItMinter.sol";

/**
 *  @title FlipIt ERC20 token
 *
 *  @notice An implementation of the staking (v1.0) in the FlipIt ecosystem.
 */
contract FlipItStakingV1 is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice A struct containing the deposit data.
    /// @param owner Address of the owner.
    /// @param level Number of nfts to be claimed.
    /// @param amount Amount of the transferred tokens.
    /// @param createdAt Timestamp of the creation.
    /// @param unlockedAt Timestamp of the unlock.
    /// @param tokensWeiWorthOneNFT Value specifying how many tokens one nft is worth.
    /// @param claimed Flag indicating whether the deposit has been claimed.
    /// @param withdrawn Flag indicating whether the deposit has been withdrawn.
    struct Deposit {
        address owner;
        uint256 level;
        uint256 amount;
        uint256 createdAt;
        uint256 unlockedAt;
        bool claimed;
        bool withdrawn;
        uint256 tokensWeiWorthOneNFT;
    }

    //-------------------------------------------------------------------------
    // Constants & Immutables

    /// @notice Address to the external smart contract that is ERC20 implementation.
    IERC20 internal immutable token;

    /// @notice Address to the external smart contract that mints nfts.
    IFlipItMinter internal minter;

    //-------------------------------------------------------------------------
    // Storage

    /// @notice Incremental value for indexing deposits and tracking the number of deposits.
    uint256 public depositSerialId;

    /// @notice Value specifying the time after which the deposit will be unlocked.
    uint256 public depositPeriod = 7 days;

    /// @notice Value specifying how many tokens one nft (which is the reward for the staking) is worth.
    uint256 public tokensWeiWorthOneNFT = 1_000_000_000 ether;

    /// @notice Mapping to store all deposits (index => deposit).
    mapping(uint256 => Deposit) public deposits;

    /// @notice Mapping to store all deposit ids of the single address.
    mapping(address => EnumerableSet.UintSet) internal _depositIdsByOwner;

    //-------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when deposit has been created.
    /// @param id Id of the deposit.
    /// @param owner Address of the owner.
    event DepositCreated(uint256 id, address owner);

    /// @notice Event emitted when deposit has been claimed.
    /// @param id Id of the deposit.
    /// @param owner Address of the owner.
    event DepositClaimed(uint256 id, address owner);

    /// @notice Event emitted when deposit has been extended.
    /// @param id Id of the deposit.
    /// @param owner Address of the owner.
    event DepositExtended(uint256 id, address owner);

    /// @notice Event emitted when deposit has been withdrawn.
    /// @param id Id of the deposit.
    /// @param owner Address of the owner.
    event DepositWithdrawn(uint256 id, address owner);

    /// @notice Event emitted when the value of deposit period has been updated.
    /// @param value New value of deposit period.
    event DepositPeriodUpdated(uint256 value);

    /// @notice Event emitted when the amount of tokens worth one nft has been updated.
    /// @param value New amount of tokens worth one nft.
    event TokensWeiWorthOneNFTUpdated(uint256 value);

    /// @notice Event emitted when the minter reference has been updated.
    /// @param minter Address of the minter smart contract.
    event MinterUpdated(address minter);

    //-------------------------------------------------------------------------
    // Errors

    /// @notice The deposit belongs to another account.
    /// @param id Id of the deposit.
    error DepositOwnerMismatch(uint256 id);

    /// @notice The deposit is still locked.
    /// @param id Id of the deposit.
    error DepositStillLocked(uint256 id);

    /// @notice The deposit is already claimed.
    /// @param id Id of the deposit.
    error DepositAlreadyClaimed(uint256 id);

    /// @notice The deposit is already withdrawn.
    /// @param id Id of the deposit.
    error DepositAlreadyWithdrawn(uint256 id);

    /// @notice Insufficient amount of tokens to create a deposit.
    /// @param amount Amount of the tokens.
    error InsufficientAmountOfTokens(uint256 amount);

    /// @notice Given value is out of safe bounds.
    error UnacceptableValue();

    /// @notice Contract reference is `address(0)`.
    error UnacceptableReference();

    //-------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Ensures that the account owns a deposit with the specified `id`.
    /// @param id Id of the deposit.
    modifier onlyDepositOwner(uint256 id) {
        if (deposits[id].owner != _msgSender()) revert DepositOwnerMismatch(id);
        _;
    }

    /// @notice Contract state initialization.
    /// @param token_ Address of the token smart contract.
    /// @param minter_ Address of the minter smart contract.
    constructor(IERC20 token_, IFlipItMinter minter_) {
        if (address(token_) == address(0) || address(minter_) == address(0)) revert UnacceptableReference();

        token = token_;
        minter = minter_;
    }

    /// @notice Updates the minter.
    /// @param minter_ Address of the minter smart contract.
    function updateMinter(IFlipItMinter minter_) external onlyOwner {
        if (address(minter_) == address(0)) revert UnacceptableValue();

        minter = minter_;

        emit MinterUpdated(address(minter_));
    }

    /// @notice Updates the deposit period value.
    /// @param value New value of deposit period.
    function updateDepositPeriod(uint256 value) external onlyOwner {
        if (value == 0 || value >= 365 days) revert UnacceptableValue();

        depositPeriod = value;

        emit DepositPeriodUpdated(value);
    }

    /// @notice Updates the amount of tokens worth one nft.
    /// @param value New amount of tokens worth one nft.
    function updateTokensWeiWorthOneNFT(uint256 value) external onlyOwner {
        if (value == 0) revert UnacceptableValue();

        tokensWeiWorthOneNFT = value;

        emit TokensWeiWorthOneNFTUpdated(value);
    }

    /// @notice Creates new deposit.
    /// @param amount Amount of tokens to create deposit.
    /// @dev Throws error if amount is less than `tokensWeiWorthOneNFT`.
    function deposit(uint256 amount) external {
        uint256 tokensWeiWorthOneNFT_ = tokensWeiWorthOneNFT;

        if (amount < tokensWeiWorthOneNFT_) revert InsufficientAmountOfTokens(amount);

        address sender = _msgSender();

        deposits[++depositSerialId] = Deposit({
            owner: sender,
            amount: amount,
            /// @dev Level can only be an integer, no need to worry about loss of precision.
            level: amount / tokensWeiWorthOneNFT_,
            /// @dev Save as reference be used when extending the deposit
            /// - in case the value of `tokensWeiWorthOneNFT` is changed after the deposit is created.
            tokensWeiWorthOneNFT: tokensWeiWorthOneNFT_,
            createdAt: block.timestamp,
            unlockedAt: block.timestamp + depositPeriod,
            claimed: false,
            withdrawn: false
        });

        _depositIdsByOwner[sender].add(depositSerialId);

        emit DepositCreated(depositSerialId, sender);

        token.safeTransferFrom(sender, address(this), amount);
    }

    /// @notice Extends the deposit.
    /// @param id Id of the deposit.
    function extend(uint256 id) external onlyDepositOwner(id) {
        Deposit storage depositById = deposits[id];

        if (depositById.unlockedAt > block.timestamp) revert DepositStillLocked(id);

        if (depositById.withdrawn) revert DepositAlreadyWithdrawn(id);

        /// Increases the reward if not claimed.
        if (!depositById.claimed) {
            depositById.level += depositById.amount / depositById.tokensWeiWorthOneNFT;
        }

        delete depositById.claimed;

        unchecked {
            depositById.unlockedAt = block.timestamp + depositPeriod;
        }

        emit DepositExtended(id, _msgSender());
    }

    /// @notice Claims the reward.
    /// @param id Id of the deposit.
    function claim(uint256 id) external onlyDepositOwner(id) {
        Deposit storage depositById = deposits[id];

        if (depositById.claimed) revert DepositAlreadyClaimed(id);

        if (depositById.unlockedAt > block.timestamp) revert DepositStillLocked(id);

        deposits[id].claimed = true;

        address sender = _msgSender();

        emit DepositClaimed(id, sender);

        // Mints reward nfts - "level" is equal to the amount of reward
        minter.mintIngredient(sender, deposits[id].level);
    }

    /// @notice Withdraws the reward.
    /// @param id Id of the deposit.
    function withdraw(uint256 id) external onlyDepositOwner(id) {
        Deposit storage depositById = deposits[id];

        if (depositById.withdrawn) revert DepositAlreadyWithdrawn(id);

        if (depositById.unlockedAt > block.timestamp) revert DepositStillLocked(id);

        deposits[id].withdrawn = true;

        address sender = _msgSender();

        emit DepositWithdrawn(id, sender);

        token.safeTransfer(sender, depositById.amount);
    }

    /// @param owner Address of the owner.
    /// @return Returns the deposit ids by the given address.
    function depositIdsByOwner(address owner) external view returns (uint256[] memory) {
        return _depositIdsByOwner[owner].values();
    }
}