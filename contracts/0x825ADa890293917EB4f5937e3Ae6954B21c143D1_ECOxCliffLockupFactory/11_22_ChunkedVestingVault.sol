// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {VestingVault} from "./VestingVault.sol";
import {ClawbackVestingVault} from "./ClawbackVestingVault.sol";
import {ChunkedVestingVaultArgs} from "./helpers/ChunkedVestingVaultArgs.sol";

/**
 * @notice VestingVault contract for a series of chunked token releases
 * @dev immutable args:
 * - slot 0 - address token (20 bytes) (in VestingVault)
 * - slot 1 - address beneficiary (20 bytes) (in VestingVault)
 * - slot 2 - uint256 vestingPeriods
 * - slot 3-x - uint256[] amounts
 * - slot x-y - uint256[] timestamps
 */
contract ChunkedVestingVault is ClawbackVestingVault, ChunkedVestingVaultArgs {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The number of vesting chunks used up so far
    uint256 public vestedChunks;

    /**
     * @notice Initializes the vesting vault
     * @dev this is separate from initialize() so an inheritor can
     * override the initializer without breaking the reentrancy protection in
     * `initializer`. for more info read
     * https://github.com/OpenZeppelin/openzeppelin-contracts/commit/553c8fdec708ea10dd5f4a2977364af7a562566f
     * @param admin The address which can clawback unvested tokens
     */
    function initialize(address admin) public virtual initializer {
        _initialize(admin);
    }

    /**
     * @notice Initializes the vesting vault
     * @dev this pulls in the required ERC20 tokens from the sender to setup
     * @param admin The address which can clawback unvested tokens
     */
    function _initialize(address admin) internal onlyInitializing {
        // calculate total amount of tokens over the lifetime of the vault
        (uint256 amount, uint256 chunks) =
            getVestedAmountAndChunks(type(uint256).max);
        if (chunks != vestingPeriods()) {
            revert InvalidParams();
        }

        ClawbackVestingVault.initialize(amount, admin);
    }

    /**
     * @inheritdoc VestingVault
     */
    function vestedOn(uint256 timestamp)
        public
        view
        override
        virtual
        returns (uint256 amount)
    {
        (amount,) = getVestedAmountAndChunks(timestamp);
    }

    /**
     * @inheritdoc VestingVault
     */
    function onClaim(uint256 amount) internal virtual override {
        (uint256 total, uint256 chunks) = getNextChunkForAmount(amount);
        if (total != amount) {
            revert InvalidClaim();
        }
        vestedChunks = chunks;
    }

    /**
     * @notice helper function to get the currently vested amount of tokens
     * and the total number of vesting chunks that have been used so far
     * @param timestamp The time for which vested tokens are being calculated
     * @return amount The amount of tokens currently vested
     * @return chunks The total number of chunks used so far
     */
    function getVestedAmountAndChunks(uint256 timestamp)
        internal
        view
        returns (uint256 amount, uint256 chunks)
    {
        uint256 total;
        for (uint256 i = vestedChunks; i < vestingPeriods(); i++) {
            if (timestamp >= timestampAtIndex(i)) {
                // then we have vested this chunk
                total += amountAtIndex(i);
            } else {
                // return early because we haven't gotten this far in the vesting cycle yet
                return (total, i);
            }
        }
        return (total, vestingPeriods());
    }

    /**
     * @notice helper function to get the next chunk index after the given amount
     * @param amount The amount of tokens to get chunk index for
     * @return total The total amount vested from last vest to the given index
     * @return chunks The total number of chunks used so far
     */
    function getNextChunkForAmount(uint256 amount)
        internal
        view
        returns (uint256 total, uint256 chunks)
    {
        for (uint256 i = vestedChunks; i < vestingPeriods(); i++) {
            total += amountAtIndex(i);
            if (total >= amount) {
                return (total, i + 1);
            }
        }
        return (total, vestingPeriods());
    }
}