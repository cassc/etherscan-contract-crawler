// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import "../interfaces/IPendleVoteManager.sol";
import "../libraries/math/Math.sol";

/// @title PenpieBribeManager
/// @notice Penpie bribe manager is used to manage market pools for voting and bribing.
///         This contract allows us to add and remove pools for Pendle market tokens.
///         When bribes are added, the tokens will be separated with a fee and transferred
///         to the distributor contract and the fee collector.
///         To save on gas fees, we will save all bribe tokens in each pool using a unique
///         index for pools and bribe tokens for each epoch (or round), instead of using nested mappings.
///         At the end of each epoch, we will retrieve the total bribes from this contract
///         and aggregate the voting results using subgraph querying.
///         We will calculate rewards for each user who has voted, package the distribution
///         using the merkleTree structure, and import it into the distributor contract.
///         This will allow users to claim their rewards from the distributor contract.
///
/// @author Penpie Team
contract PenpieBribeManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    struct Pool {
        address _market;
        bool _active;
        uint256 _chainId;
    }

    struct Bribe {
        address _token;
        uint256 _amount;
    }

    struct PoolVotes {
        address _bribe;
        uint256 _votes;
    }

    /* ============ State Variables ============ */

    address constant NATIVE = address(1);
    uint256 constant DENOMINATOR = 10000;

    address public voteManager;
    address payable public distributor;
    address payable private feeCollector;
    uint256 public feeRatio;
    uint256 public maxBribingBatch;

    uint256 public epochPeriod;
    uint256 public epochStartTime;
    uint256 private currentEpoch;

    Pool[] public pools;
    mapping(address => uint256) public marketToPid;
    mapping(address => uint256) public unCollectedFee;

    address[] public allowedTokens;
    mapping(address => bool) public allowedToken;
    mapping(bytes32 => Bribe) public bribes;  // The index is hashed based on the epoch, pid and token address
    mapping(bytes32 => bytes32[]) public bribesInPool;  // Mapping pool => bribes. The index is hashed based on the epoch, pid
    mapping(address => bool) public allowedOperator;

    /* ============ Events ============ */

    event NewBribe(address indexed _user, uint256 indexed _epoch, uint256 _pid, address _bribeToken, uint256 _amount);
    event NewPool(address indexed _market, uint256 _chainId);
    event EpochPushed(uint256 indexed _epoch, uint256 _startTime);
    event UpdateOperatorStatus(address indexed _user, bool _status);

    /* ============ Errors ============ */

    error InvalidPool();
    error InvalidBribeToken();
    error ZeroAddress();
    error PoolOccupied();
    error InvalidEpoch();
    error OnlyNotInEpoch();
    error OnlyInEpoch();
    error InvalidTime();
    error InvalidBatch();
    error OnlyOperator();

    /* ============ Constructor ============ */

    function __PenpieBribeManager_init(
        address _voteManager,
        uint256 _epochPeriod,
        uint256 _feeRatio
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        voteManager = _voteManager;
        epochPeriod = _epochPeriod;
        feeRatio = _feeRatio;
        maxBribingBatch = 8;
        currentEpoch = 0;
        allowedOperator[owner()] = true;
    }

    /* ============ Modifiers ============ */

    modifier onlyOperator() {
        if (!allowedOperator[msg.sender]) revert OnlyOperator();
        _;
    }    

    /* ============ External Getters ============ */

    function exactCurrentEpoch() public view returns (uint256) {
        if (epochStartTime == 0) return 0;

        uint256 epochEndTime = epochStartTime + epochPeriod;
        if (block.timestamp > epochEndTime)
            return currentEpoch + 1;
        else
            return currentEpoch;
    }

    function getCurrentEpochEndTime() public view returns(uint256 endTime) {
        endTime = epochStartTime + epochPeriod;
    }

    function getApprovedTokens() public view returns(address[] memory) {
        return allowedTokens;
    }

    function getPoolLength() public view returns(uint256) {
        return pools.length;
    }

    /// @notice this function could make havey gas cost, please prevent to call this in non-view functions
    function getBribesInAllPools(uint256 _epoch) external view returns (Bribe[][] memory) {
        Bribe[][] memory rewards = new Bribe[][](pools.length);
        for (uint256 i = 0; i < pools.length; i++){
            rewards[i] = getBribesInPool(_epoch, i);
        }
        return rewards;
    }

    function getBribesInPool(uint256 _epoch, uint256 _pid) public view returns (Bribe[] memory) {
        if (_pid >= getPoolLength()) revert InvalidPool();
        
        bytes32 poolIdentifier = _getPoolIdentifier(_epoch, _pid);

        bytes32[] memory poolBribes = bribesInPool[poolIdentifier];
        Bribe[] memory rewards = new Bribe[](poolBribes.length);

        for (uint256 i = 0; i < poolBribes.length; i++) {
            rewards[i] = bribes[poolBribes[i]];
        }

        return rewards;
    }

    /* ============ External Functions ============ */
    function addBribeNative(uint256 _batch, uint256 _pid) external payable nonReentrant whenNotPaused {
        if (_batch == 0 || _batch > maxBribingBatch) revert InvalidBatch();

        uint256 startFromEpoch = exactCurrentEpoch();
        uint256 totalFee = 0;
        uint256 totalBribing = 0;

        uint256 bribePerEpoch = msg.value / _batch;

        for (uint256 epoch = startFromEpoch; epoch < startFromEpoch + _batch; epoch++) {
            (uint256 fee, uint256 afterFee) = _addBribe(epoch, _pid, NATIVE, bribePerEpoch);
            totalFee += fee;
            totalBribing += afterFee;
        }

        // transfer the token to the target directly in one time to save the gas fee
        bool success;
        if (totalFee > 0) {
            if (feeCollector == address(0)) {
                unCollectedFee[NATIVE] += totalFee;
            } else {
                feeCollector.transfer(totalFee);
            }
        }
        (success, )  = distributor.call{value: totalBribing}("");
        
        if (!success) revert InvalidBribeToken();
    }

    function addBribeERC20(uint256 _batch, uint256 _pid, address _token, uint256 _amount) external nonReentrant whenNotPaused {
        if (_batch == 0 || _batch > maxBribingBatch) revert InvalidBatch();

        uint256 startFromEpoch = exactCurrentEpoch();
        uint256 totalFee = 0;
        uint256 totalBribing = 0;

        uint256 bribePerEpoch = _amount / _batch;

        for (uint256 epoch = startFromEpoch; epoch < startFromEpoch + _batch; epoch++) {
            (uint256 fee, uint256 afterFee) = _addBribe(epoch, _pid, _token, bribePerEpoch);
            totalFee += fee;
            totalBribing += afterFee;
        }

        // transfer the token to the target directly in one time to save the gas fee
        if (totalFee > 0) {
            if (feeCollector == address(0)) {
                unCollectedFee[_token] += totalFee;
                IERC20(_token).safeTransferFrom(msg.sender, address(this), totalFee);
            } else {
                IERC20(_token).safeTransferFrom(msg.sender, feeCollector, totalFee);
            }
        }
        
        IERC20(_token).safeTransferFrom(msg.sender, distributor, totalBribing);
    }

    /* ============ Internal Functions ============ */

    function _getPoolIdentifier(uint256 _epoch, uint256 _pid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_epoch, _pid)
            );
    }

    function _getTokenIdentifier(uint256 _epoch, uint256 _pid, address _token) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_epoch, _pid, _token)
            );
    }

    function _addBribe(uint256 _epoch, uint256 _pid, address _token, uint256 _amount) internal returns (uint256 fee, uint256 afterFee) {
        if (_epoch < exactCurrentEpoch()) revert InvalidEpoch(); // the epoch must be equal or greater then now
        if (_pid >= pools.length) revert InvalidPool();
        Pool memory bribePool = pools[_pid];

        if (!bribePool._active) revert InvalidPool();
        if (!allowedToken[_token] && _token != NATIVE) revert InvalidBribeToken();

        fee = _amount * feeRatio / DENOMINATOR;
        afterFee = _amount - fee;

        // We will generate a unique index for each pool and reward based on the epoch
        bytes32 poolIdentifier = _getPoolIdentifier(_epoch, _pid);
        bytes32 rewardIdentifier = _getTokenIdentifier(_epoch, _pid, _token);

        Bribe storage bribe = bribes[rewardIdentifier];
        bribe._amount += afterFee;
        if(bribe._token == address(0)) {
            bribe._token = _token;
            bribesInPool[poolIdentifier].push(rewardIdentifier);
        }

        emit NewBribe(msg.sender, _epoch, _pid, _token, afterFee);
    }

    /* ============ Admin Functions ============ */

    /// @notice this function will create a new pool in the bribeManager and voteManager
    function newPool(address _market, uint16 _chainId) external onlyOwner {
        if (_market == address(0)) revert ZeroAddress();

        Pool memory pool = Pool(_market, true, _chainId);
        pools.push(pool);

        marketToPid[_market] = pools.length - 1;

        IPendleVoteManager(voteManager).addPool(_market, _chainId);

        emit NewPool(_market, _chainId);
    }

    function removePool(uint256 _pid) external onlyOwner {
        if (_pid >= pools.length) revert InvalidPool();
        pools[_pid]._active = false;
        IPendleVoteManager(voteManager).removePool(_pid);
    }

    function setEpochPeriod(uint256 _epochPeriod) external onlyOwner {
        epochPeriod = _epochPeriod;
    }

    function pushEpoch(uint256 _time) external onlyOperator {
        epochStartTime = _time;
        currentEpoch ++;

        emit EpochPushed(currentEpoch, _time);
    }

    function addAllowedTokens(address _token) external onlyOwner {
        if (allowedToken[_token]) revert InvalidBribeToken();

        allowedTokens.push(_token);

        allowedToken[_token] = true;
    }

    function removeAllowedTokens(address _token) external onlyOwner {
        if (!allowedToken[_token]) revert InvalidBribeToken();
        uint256 allowedTokensLength = allowedTokens.length;
        uint256 i = 0;
        while (allowedTokens[i] != _token) {
            i++;
            if (i >= allowedTokensLength) revert InvalidBribeToken();
        }

        allowedTokens[i] = allowedTokens[allowedTokensLength-1];
        allowedTokens.pop();

        allowedToken[_token] = false;
    }

    function updateAllowedUperator(address _user, bool _allowed) external onlyOwner {
        allowedOperator[_user] = _allowed;

        emit UpdateOperatorStatus(_user, _allowed);
    }

    function setDistributor(address payable _distributor) external onlyOwner {
        distributor= _distributor;
    }

    function setFeeCollector(address payable _collector) external onlyOwner {
        feeCollector= _collector;
    }

    function setFeeRatio(uint256 _feeRatio) external onlyOwner {
        feeRatio = _feeRatio;
    }

    function manualClaimFees(address _token) external onlyOwner {
        if (feeCollector != address(0)) {
            unCollectedFee[_token] = 0;
            if (_token == NATIVE) {
                feeCollector.transfer(address(this).balance);
            } else {
                uint256 balance = IERC20(_token).balanceOf(address(this));
                IERC20(_token).safeTransfer(feeCollector, balance);
            }
        }
    }

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}
}