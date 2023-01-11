// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

// Need to use IERC20Upgradeable because that is what SafeERC20Upgradeable requires
// but the interface is exactly the same as ERC20s so this still works with ERC20s
import { IERC20Upgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

/// @notice Storage for Vault
/// @author Recursive Research Inc
abstract contract VaultStorageUnpadded {
    /// @notice struct for withdraw and deposit requests
    /// @param epoch the epoch when the request was submitted
    /// @param amount size of request, if deposit it's an absolute amount of the underlying.
    ///     If withdraw, specified in "Day 0" amount
    struct Request {
        uint256 epoch;
        uint256 amount;
    }

    /// @notice struct to keep a copy of AssetData in memory during `nextEpoch` call
    struct AssetDataStatics {
        uint256 reserves;
        uint256 active;
        uint256 depositRequestsTotal;
        uint256 withdrawRequestsTotal;
    }

    /// @notice global struct to keep track of all info for an asset
    /// @param reserves total amount not active
    /// @param active total amount paired up in the Dex pool
    /// @param depositRequestsTotal total amount of queued up deposit requests
    /// @param withdrawRequestsTotal total amount of queued up withdraw requests
    /// @param balanceDay0 each user's deposited balance denominated in "day 0 tokens"
    /// @param claimable each user's amount that has been withdrawn from the LP pool and they can claim
    /// @param epochToRate exchange rate of token to day0 tokens by epoch
    /// @param depositRequests each users deposit requests
    /// @param withdrawRequests each users withdraw requests
    struct AssetData {
        uint256 reserves;
        uint256 active;
        uint256 depositRequestsTotal;
        uint256 withdrawRequestsTotal;
        uint256 claimableTotal;
        mapping(address => uint256) balanceDay0;
        mapping(address => uint256) claimable;
        mapping(uint256 => uint256) epochToRate;
        mapping(address => Request) depositRequests;
        mapping(address => Request) withdrawRequests;
    }

    /// @notice true if token0 is wrapped native
    bool public isNativeVault;

    /// @notice token that receives a "floor" return
    IERC20Upgradeable public token0;
    /// @notice token that receives a "ceiling" return
    IERC20Upgradeable public token1;

    /// @notice current epoch, set to 1 on initialization
    uint256 public epoch;
    /// @notice duration of each epoch
    uint256 public epochDuration;
    /// @notice start of last epoch, 0 on initialization
    uint256 public lastEpochStart;

    /// @notice keeps track of relevant data for TOKEN0
    AssetData public token0Data;
    /// @notice keeps track of relevant data for TOKEN1
    AssetData public token1Data;

    /// @notice minimum return for TOKEN0 (out of `vault.DENOM`) as long as TOKEN1 is above its minimum return
    uint256 public token0FloorNum;
    /// @notice minimum return for TOKEN1 (out of `vault.DENOM`)
    uint256 public token1FloorNum;

    /// @notice flag for enabling/disabling deposits
    bool public depositsEnabled;
}

abstract contract VaultStorage is VaultStorageUnpadded {
    // @dev Padding 100 words of storage for upgradeability. Follows OZ's guidance.
    // @dev storage var depositsEnabled has been added, and __gap reduced by 1 word to maintain overall storage size.
    uint256[99] private __gap;
}