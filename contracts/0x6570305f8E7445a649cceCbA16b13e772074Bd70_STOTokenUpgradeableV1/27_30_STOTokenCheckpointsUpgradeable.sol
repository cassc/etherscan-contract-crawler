// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

/**
 *  @dev Inspired on ERC20Votes by OpenZeppelin with the following changes:
 *   - Changed namings from "votes" to "balances" and from "delegate" to "tracking"
 *   - Removed delegateBySig and ECDSA use and dependency
 *   - Made the `delegate` function restricted in access
 */
/// @title STOTokenCheckpointsUpgradeable
/// @custom:security-contact [email protected]
abstract contract STOTokenCheckpointsUpgradeable is Initializable, ERC20BurnableUpgradeable {

    event TrackingChanged(address indexed from, address indexed oldValue, address indexed newValue);
    event CheckpointBalanceChanged(address indexed from, uint256 oldValue, uint256 newValue);

    function __STOTokenCheckpoints_init(string memory _name, string memory _symbol) internal onlyInitializing {
        __STOTokenCheckpoints_init_unchained(_name, _symbol);
    }

    function __STOTokenCheckpoints_init_unchained(string memory _name, string memory _symbol) internal onlyInitializing {
        __ERC20_init(_name, _symbol);
    }

    struct Checkpoint {
        uint32 fromBlock;
        uint224 balance;
    }

    mapping(address => address) private _trackings;
    mapping(address => Checkpoint[]) private _checkpoints;

    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function trackings(address account) public view virtual returns (address) {
        return _trackings[account];
    }

    /**
     * @dev Gets the current balance for `account`
     */
    function getBalance(address account) public view virtual returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].balance;
    }

    /**
     * @dev Retrieve the balance for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastBalance(address account, uint256 blockNumber) public view virtual returns (uint256) {
        require(blockNumber < block.number, "STOTokenCheckpoints: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual returns (uint256) {
        require(blockNumber < block.number, "STOTokenCheckpoints: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].balance;
    }

    /**
     * @dev Start tracking an account.
     */
    function startTracking(address account) public virtual {
        address currentTracking = trackings(account);
        if(currentTracking != address(0)) return;
        _startTracking(account);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "STOTokenCheckpoints: total supply risks overflowing");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move balances when tokens are transferred.
     *
     * Emits a {TrackingChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        super._afterTokenTransfer(from, to, amount);

        _moveBalances(trackings(from), trackings(to), amount);
    }

    /**
     * @dev Change tracking for `account` to itself.
     *
     * Emits events {TrackingChanged} and {CheckpointBalanceChanged}.
     */
    function _startTracking(address account) internal virtual {
        address currentTracking = trackings(account);
        uint256 currentTrackingBalance = balanceOf(account);
        _trackings[account] = account;

        emit TrackingChanged(account, currentTracking, account);

        _moveBalances(currentTracking, account, currentTrackingBalance);
    }

    function _moveBalances(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit CheckpointBalanceChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit CheckpointBalanceChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].balance;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].balance = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCastUpgradeable.toUint32(block.number), balance: SafeCastUpgradeable.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}