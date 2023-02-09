// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/utils/math/Math.sol";
import "openzeppelin-contracts/utils/math/SafeCast.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/INetworkV2.sol";
import {IAmplifierV2} from "./interfaces/IAmplifierV2.sol";
import "./Types.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract FusePoolV2 is INetworkV2, Ownable {
    uint256 immutable duration;

    IAmplifierV2 public amplifierContract;

    mapping(uint256 => mapping(uint256 => bool)) public hasClaimedPeriod;
    mapping(uint256 => Types.Pot) public potPerPeriod;
    mapping(uint256 => uint256) public fuseUnlocks;
    uint256 public totalSupply;

    mapping(uint256 => Types.Checkpoint[]) private _checkpoints;
    Types.Checkpoint[] private _totalSupplyCheckpoints;

    event PotAccrued(uint256 potAmount);
    event Claimed(uint256 indexed id, uint256 indexed potBlock, uint256 amount);

    modifier onlyAmplifier() {
        require(msg.sender == address(amplifierContract), "Only Amplifier");
        _;
    }

    constructor(address _owner, IAmplifierV2 _amplifierContract, uint256 _duration) {
        _transferOwnership(_owner);

        amplifierContract = _amplifierContract;
        duration = _duration;
    }

    function enter(uint256 _id) external onlyAmplifier returns (uint48) {
        require(fuseUnlocks[_id] == 0, "Share already exists");

        _checkpoints[_id].push(Types.Checkpoint({fromBlock: uint32(block.number), shares: 1}));
        _writeCheckpoint(_totalSupplyCheckpoints, _add, 1);
        totalSupply++;

        uint256 unlocks = duration + block.timestamp;
        fuseUnlocks[_id] = unlocks;

        return uint48(unlocks);
    }

    function exit(uint256 _id) external onlyAmplifier {
        require(fuseUnlocks[_id] <= block.timestamp, "Cannot exit yet");

        _checkpoints[_id].push(Types.Checkpoint({fromBlock: uint32(block.number), shares: 0}));
        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, 1);
        totalSupply--;
        fuseUnlocks[_id] = 0;
    }

    function migrateShare(uint256 _id, uint48 _unlocks, bool _allowOverwrite) external override onlyAmplifier {
        require(fuseUnlocks[_id] == 0 || _allowOverwrite, "Share already exists");

        _checkpoints[_id].push(Types.Checkpoint({fromBlock: uint32(block.number), shares: 1}));

        fuseUnlocks[_id] = _unlocks;

        unchecked {
            totalSupply++;
        }

        _writeCheckpoint(_totalSupplyCheckpoints, _add, 1);
    }

    function pot() external payable onlyOwner {
        potPerPeriod[block.number] =
            Types.Pot({timestamp: uint48(block.timestamp), value: SafeCast.toUint208(msg.value)});
        emit PotAccrued(msg.value);
    }

    function claim(uint256 _id, uint256[] calldata _blockNumbers) external onlyAmplifier returns (uint256) {
        uint256 owed;

        uint256 length = _blockNumbers.length;
        for (uint256 i = 0; i < length;) {
            uint256 claimAmount = _claim(_blockNumbers[i], _id);
            emit Claimed(_id, _blockNumbers[i], claimAmount);
            owed += claimAmount;
            unchecked {
                ++i;
            }
        }

        _claimPayments(owed, _id);

        return owed;
    }

    function _claim(uint256 _blockNumber, uint256 _id) internal returns (uint256) {
        require(!hasClaimedPeriod[_id][_blockNumber], "Already claimied this period");
        require(fuseUnlocks[_id] > potPerPeriod[_blockNumber].timestamp, "Period after unlock time");
        hasClaimedPeriod[_id][_blockNumber] = true;
        return getClaimAmount(_blockNumber, _id);
    }

    function _claimPayments(uint256 owed, uint256 _id) internal {
        require(owed > 0, "No ETH claimable");

        Types.AmplifierV2 memory amplifier = amplifierContract.amplifiers(_id);

        (bool success,) = amplifier.minter.call{value: owed}("");
        require(success, "Could not send ETH");
    }

    function _writeCheckpoint(
        Types.Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].shares;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].shares = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(
                Types.Checkpoint({fromBlock: uint32(block.number), shares: SafeCast.toUint224(newWeight)})
            );
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    function getClaimAmount(uint256 _blockNumber, uint256 _id) public view returns (uint256) {
        return
            (getPastShares(_id, _blockNumber) * potPerPeriod[_blockNumber].value) / (getPastTotalSupply(_blockNumber));
    }

    function ETHOwed(uint256[] memory _blockNumbers, uint256 _id) public view returns (uint256) {
        uint256 owed = 0;
        for (uint256 i = 0; i < _blockNumbers.length;) {
            uint256 blockNumber = _blockNumbers[i];
            if (!hasClaimedPeriod[_id][blockNumber]) {
                owed += (getPastShares(_id, blockNumber) * potPerPeriod[blockNumber].value)
                    / (getPastTotalSupply(blockNumber));
            }

            unchecked {
                ++i;
            }
        }
        return owed;
    }

    function getPastShares(uint256 id, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "block not yet mined");
        return _checkpointsLookup(_checkpoints[id], blockNumber);
    }

    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    function _checkpointsLookup(Types.Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
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
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].shares;
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success,) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    function emergencyDeposit() external payable onlyOwner {}
}