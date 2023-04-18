// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IFeeDistributor.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "light-lib/contracts/LibTime.sol";

struct Point {
    int256 bias;
    int256 slope;
    uint256 ts;
    uint256 blk;
}

interface IVotingEscrow {
    function epoch() external view returns (uint256);

    function userPointEpoch(address user) external view returns (uint256);

    function checkpointSupply() external;

    function supplyPointHistory(uint256 epoch) external view returns (Point memory);

    function userPointHistory(address user, uint256 epoch) external view returns (Point memory);
}

interface IStakingHOPE {
    function staking(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external returns (bool);
}

contract FeeDistributor is Ownable2StepUpgradeable, PausableUpgradeable, IFeeDistributor {
    uint256 constant WEEK = 7 * 86400;
    uint256 constant TOKEN_CHECKPOINT_DEADLINE = 86400;

    uint256 public startTime;
    uint256 public timeCursor;

    ///userAddress => timeCursor
    mapping(address => uint256) public timeCursorOf;
    ///userAddress => epoch
    mapping(address => uint256) public userEpochOf;

    ///lastTokenTime
    uint256 public lastTokenTime;
    /// tokensPreWeek
    mapping(uint256 => uint256) public tokensPerWeek;

    ///HOPE Token address
    address public token;
    /// staking hope address
    address public stHOPE;
    /// VeLT contract address
    address public votingEscrow;

    uint256 public tokenLastBalance;

    // VE total supply at week bounds
    mapping(uint256 => uint256) public veSupply;

    bool public canCheckpointToken;
    address public emergencyReturn;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract constructor
     * @param _votingEscrow VotingEscrow contract address
     * @param _startTime Epoch time for fee distribution to start
     * @param _token HOPE token address
     * @param _stHOPE stakingHOPE  address
     * @param _emergencyReturn Address to transfer `_token` balance to if this contract is killed
     */
    function initialize(
        address _votingEscrow,
        uint256 _startTime,
        address _token,
        address _stHOPE,
        address _emergencyReturn
    ) external initializer {
        require(_votingEscrow != address(0), "Invalid Address");
        require(_token != address(0), "Invalid Address");
        require(_stHOPE != address(0), "Invalid Address");

        __Ownable2Step_init();

        uint256 t = LibTime.timesRoundedByWeek(_startTime);
        startTime = t;
        lastTokenTime = t;
        timeCursor = t;
        emergencyReturn = _emergencyReturn;

        token = _token;
        stHOPE = _stHOPE;
        votingEscrow = _votingEscrow;
    }

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
         During setup for the initial distribution this function is only callable
         by the contract owner. Beyond initial distro, it can be enabled for anyone
         to call
     */
    function checkpointToken() external {
        require((msg.sender == owner()) || (canCheckpointToken && (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)), "FD001");
        _checkpointToken();
    }

    function _checkpointToken() internal {
        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        uint256 toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint256 thisWeek = LibTime.timesRoundedByWeek(t);
        uint256 nextWeek = 0;

        for (uint i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0 && block.timestamp == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (block.timestamp - t)) / sinceLast;
                }
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (nextWeek - t)) / sinceLast;
                }
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _user, uint256 _timestamp) external view returns (uint256) {
        uint256 maxUserEpoch = IVotingEscrow(votingEscrow).userPointEpoch(_user);
        uint256 epoch = _findTimestampUserEpoch(votingEscrow, _user, _timestamp, maxUserEpoch);
        Point memory pt = IVotingEscrow(votingEscrow).userPointHistory(_user, epoch);
        return _getPointBalanceOf(pt.bias, pt.slope, _timestamp - pt.ts);
    }

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gauge  at `_timestamp`
     * @dev This function should be manually changed to "view" in the ABI
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _user, uint256 _timestamp) external returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }
        _timestamp = LibTime.timesRoundedByWeek(_timestamp);
        uint256 veForAtValue = this.veForAt(_user, _timestamp);
        uint256 supply = veSupply[_timestamp];
        if (supply == 0) {
            return 0;
        }
        return (veForAtValue * 1e18) / supply;
    }

    /**
     * @notice Update the veLT total supply checkpoint
     * @dev The checkpoint is also updated by the first claimant each
         new epoch week. This function may be called independently
         of a claim, to reduce claiming gas costs.
     */
    function checkpointTotalSupply() external {
        _checkpointTotalSupply();
    }

    function _checkpointTotalSupply() internal {
        uint256 t = timeCursor;
        uint256 roundedTimestamp = LibTime.timesRoundedByWeek(block.timestamp);
        IVotingEscrow(votingEscrow).checkpointSupply();

        for (int i = 0; i < 20; i++) {
            if (t > roundedTimestamp) {
                break;
            } else {
                uint256 epoch = _findTimestampEpoch(votingEscrow, t);
                Point memory pt = IVotingEscrow(votingEscrow).supplyPointHistory(epoch);
                uint256 dt = 0;
                if (t > pt.ts) {
                    /// If the point is at 0 epoch, it can actually be earlier than the first deposit
                    /// Then make dt 0
                    dt = t - pt.ts;
                }
                veSupply[t] = _getPointBalanceOf(pt.bias, pt.slope, dt);
            }
            t += WEEK;
        }
        timeCursor = t;
    }

    function _findTimestampEpoch(address ve, uint256 _timestamp) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = IVotingEscrow(ve).epoch();
        for (int i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            Point memory pt = IVotingEscrow(ve).supplyPointHistory(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _findTimestampUserEpoch(address ve, address user, uint256 _timestamp, uint256 maxUserEpoch) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = maxUserEpoch;
        for (int i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            Point memory pt = IVotingEscrow(ve).userPointHistory(user, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _claim(address addr, address ve, uint256 _lastTokenTime) internal returns (uint256) {
        ///Minimal userEpoch is 0 (if user had no point)
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(addr);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) {
            /// No lock = no fees
            return 0;
        }

        uint256 weekCursor = timeCursorOf[addr];
        if (weekCursor == 0) {
            /// Need to do the initial binary search
            userEpoch = _findTimestampUserEpoch(ve, addr, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[addr];
        }
        if (userEpoch == 0) {
            userEpoch = 1;
        }

        Point memory userPoint = IVotingEscrow(ve).userPointHistory(addr, userEpoch);
        if (weekCursor == 0) {
            weekCursor = LibTime.timesRoundedByWeek(userPoint.ts + WEEK - 1);
        }

        if (weekCursor >= _lastTokenTime) {
            return 0;
        }

        if (weekCursor < _startTime) {
            weekCursor = _startTime;
        }
        Point memory oldUserPoint = Point({bias: 0, slope: 0, ts: 0, blk: 0});

        /// Iterate over weeks
        for (int i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) {
                break;
            }

            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;
                if (userEpoch > maxUserEpoch) {
                    userPoint = Point({bias: 0, slope: 0, ts: 0, blk: 0});
                } else {
                    userPoint = IVotingEscrow(ve).userPointHistory(addr, userEpoch);
                }
            } else {
                // Calc
                // + i * 2 is for rounding errors
                uint256 dt = weekCursor - oldUserPoint.ts;
                uint256 balanceOf = _getPointBalanceOf(oldUserPoint.bias, oldUserPoint.slope, dt);
                if (balanceOf == 0 && userEpoch > maxUserEpoch) {
                    break;
                }
                if (balanceOf > 0) {
                    toDistribute += (balanceOf * tokensPerWeek[weekCursor]) / veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        userEpochOf[addr] = userEpoch;
        timeCursorOf[addr] = weekCursor;

        emit Claimed(addr, toDistribute, userEpoch, maxUserEpoch);

        return toDistribute;
    }

    function _getPointBalanceOf(int256 bias, int256 slope, uint256 dt) internal pure returns (uint256) {
        uint256 currentBias = uint256(slope) * dt;
        uint256 oldBias = uint256(bias);
        if (currentBias > oldBias) {
            return 0;
        }
        return oldBias - currentBias;
    }

    /**
     * @notice Claim fees for `_addr`
     *  @dev Each call to claim look at a maximum of 50 user veLT points.
         For accounts with many veLT related actions, this function
         may need to be called more than once to claim all available
         fees. In the `Claimed` event that fires, if `claim_epoch` is
         less than `max_epoch`, the account may claim again.
         @param _addr Address to claim fees for
         @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address _addr) external whenNotPaused returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }

        if (_addr == address(0)) {
            _addr = msg.sender;
        }
        uint256 _lastTokenTime = lastTokenTime;
        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        uint256 amount = _claim(_addr, votingEscrow, _lastTokenTime);
        if (amount != 0) {
            stakingHOPEAndTransfer2User(_addr, amount);
            tokenLastBalance -= amount;
        }
        return amount;
    }

    /**
     * @notice Claim fees for `_addr`
     * @dev This function should be manually changed to "view" in the ABI
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     *
     */
    function claimableToken(address _addr) external whenNotPaused returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }
        if (_addr == address(0)) {
            _addr = msg.sender;
        }
        uint256 _lastTokenTime = lastTokenTime;
        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        uint256 amount = _claim(_addr, votingEscrow, _lastTokenTime);
        if (amount != 0) {
            stakingHOPEAndTransfer2User(_addr, amount);
            tokenLastBalance -= amount;
        }
        return amount;
    }

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veLT history
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim totol fee
     */
    function claimMany(address[] memory _receivers) external whenNotPaused returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }

        uint256 _lastTokenTime = lastTokenTime;

        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        uint256 total = 0;

        for (uint256 i = 0; i < _receivers.length && i < 50; i++) {
            address addr = _receivers[i];
            if (addr == address(0)) {
                break;
            }
            uint256 amount = _claim(addr, votingEscrow, _lastTokenTime);
            if (amount != 0) {
                stakingHOPEAndTransfer2User(addr, amount);
                total += amount;
            }
        }

        if (total != 0) {
            tokenLastBalance -= total;
        }

        return total;
    }

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external whenNotPaused returns (bool) {
        if (amount != 0) {
            require(IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");
            if (canCheckpointToken && (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
                _checkpointToken();
            }
        }
        return true;
    }

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external onlyOwner {
        bool flag = !canCheckpointToken;
        canCheckpointToken = !canCheckpointToken;
        emit ToggleAllowCheckpointToken(flag);
    }

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external onlyOwner returns (bool) {
        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));
        TransferHelper.doTransferOut(token, emergencyReturn, amount);
        emit RecoverBalance(token, emergencyReturn, amount);
        return true;
    }

    /**
     * @notice Set the token emergency return address
     * @param _addr emergencyReturn address
     */
    function setEmergencyReturn(address _addr) external onlyOwner {
        emergencyReturn = _addr;
        emit SetEmergencyReturn(_addr);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function stakingHOPEAndTransfer2User(address to, uint256 amount) internal {
        TransferHelper.doApprove(token, stHOPE, amount);
        bool success = IStakingHOPE(stHOPE).staking(amount, 0, 0, "");
        require(success, "staking hope fail");
        TransferHelper.doTransferOut(stHOPE, to, amount);
    }
}