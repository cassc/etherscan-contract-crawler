// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface PulseBitcoin {
    struct MinerStore {
        uint128 bitoshisMiner;
        uint128 bitoshisReturned;
        uint96 pSatoshisMined;
        uint96 bitoshisBurned;
        uint40 minerId;
        uint24 day;
    }

    function minerStart(uint256 bitoshisMiner) external;

    function minerEnd(
        uint256 minerIndex,
        uint256 minerId,
        address minerAddr
    ) external;

    function calcPayoutAndFee(uint256 bitoshis)
    external
    view
    returns (
        uint256 pSatoshisMine,
        uint256 bitoshisBurn,
        uint256 bitoshisReturn,
        bool isHalving
    );

    function minerList(address, uint256)
    external
    view
    returns (
        uint128,
        uint128,
        uint96,
        uint96,
        uint40,
        uint24
    );
}

interface PLSDStaker {
    function depositPLSB(uint256 _amount) external;

    function depositASIC(uint256 _amount) external;
}

contract CarnivalCommunityASICMiner is ReentrancyGuard {
    using SafeERC20 for IERC20;
    // Constants
    uint256 public constant MIN_ASIC_DEPOSIT = 25 * 1e12;
    uint256 public constant CARN_COST = 10 * 1e12;
    uint256 public constant MINING_PERIOD = 30 days;
    uint256 public constant RELOAD_PERIOD = 5 days;
    uint256 public constant TRAPPED_POOL_TARGET = 100000 * 1e12; // 100K CARNs

    // Token Addresses
    address public immutable CARN;
    address public immutable ASIC;
    address public immutable PLSB;

    address public immutable waatcaPool;
    address public immutable buyAndBurnContract;
    address public immutable plsdStakingContract;

    // Variables
    mapping(address => AsicDeposit) public asicDeposits; // keeps track of user's ASIC deposits for the session

    uint256 public totalAsicDepositForThePreviousSession; // total ASICs deposited for the previous sessionId
    uint256 public totalAsicDepositForTheCurrentSession; // total ASICs deposited for the current sessionId
    uint256 public trappedAsicReleasePool; // keeps track of carn deposited by the community

    uint256 public nextMiningStartTime; // start of next mining session as timestamp
    uint256 public nextReloadTime; // start of next reload period as timestamp

    uint256 public totalPLSBRewards; // total PLSB rewards for the mining session
    uint256 public currentSessionId; // keeps track of current mining session Id
    uint256 public unclaimedRewards; // keeps track of unclaimed amount from reward pool

    uint256 public numParticipantsForThisSession; // total depositors for each session
    uint256 public numTotalDepositsForAllSessions; // total sum of all depositors from all sessions
    uint256 public asicUsedToMine; // keeps track of how much asic was used to mine in a session...we cant just use the balance of the account since the asic gets MINED!

    enum State {RELOAD, MINING}

    State public state; // keeps track of the current state of the contract

    struct AsicDeposit {uint256 amount; uint256 sessionId;}

    // Events
    event Deposit(address indexed depositor, uint256 indexed sessionId, uint256 asicAmount, uint256 carnAmount);
    event RewardClaim(address indexed withdrawer, uint256 indexed sessionId, uint256 plsbAmount);
    event MiningSessionStart(address indexed caller, uint256 id, uint256 startTime);
    event ReloadPeriodStart(address indexed caller, uint256 id, uint256 reloadTime);
    event RewardReset(address indexed miner, uint256 indexed sessionId);
    event CARNDepositToTrappedPool(address indexed depositor, uint256 amount, uint256 time);
    event ASICReleased(uint256 amount, uint256 time);
    event CARNReleased(uint256 amount, uint256 time);

    constructor(
        address _waatcaPoolAddress,
        address _buyAndBurnContractAddress,
        address _plsdStakingContractAddress,
        address _CARN,
        address _PLSB,
        address _ASIC
    ) {
        waatcaPool = _waatcaPoolAddress;
        buyAndBurnContract = _buyAndBurnContractAddress;
        plsdStakingContract = _plsdStakingContractAddress;
        CARN = _CARN;
        PLSB = _PLSB;
        ASIC = _ASIC;

        nextMiningStartTime = block.timestamp + 30 days;
        currentSessionId = 1;
    }


    function deposit(uint256 _asicAmount) public nonReentrant {
        numParticipantsForThisSession += 1;
        numTotalDepositsForAllSessions += 1;
        if (block.timestamp > nextReloadTime && state != State.RELOAD) {
            startReloadPeriod();
        }

        if (
            asicDeposits[msg.sender].amount == 0 &&
            asicDeposits[msg.sender].sessionId != currentSessionId
        ) {
            // new miner/miner don't have any pending claims, update sessionId
            asicDeposits[msg.sender].sessionId = currentSessionId;
        }

        require(
            _asicAmount >= MIN_ASIC_DEPOSIT,
            "At least minimum ASIC deposit required"
        );


        require(state == State.RELOAD, "Not in reload period");

        require(
            asicDeposits[msg.sender].sessionId == currentSessionId,
            "Please claim rewards for the previous session"
        );

        asicDeposits[msg.sender].amount += _asicAmount;
        totalAsicDepositForTheCurrentSession += _asicAmount;

        // Transfer the ASIC to contract
        IERC20(ASIC).safeTransferFrom(msg.sender, address(this), _asicAmount);
        IERC20(CARN).safeTransferFrom(msg.sender, buyAndBurnContract, CARN_COST);

        emit Deposit(msg.sender, currentSessionId, _asicAmount, CARN_COST);

        // Start mining session if it has not already started
        if (block.timestamp > nextMiningStartTime && state == State.RELOAD) {
            startMiningSession();
        }
    }

    function startMiningSession() public {
        require(state != State.MINING, "Mining session already started");
        require(
            block.timestamp > nextMiningStartTime,
            "Reload period not ended yet"
        );

        uint256 _asicBalance = IERC20(ASIC).balanceOf(address(this));
        (totalPLSBRewards, , , ) = PulseBitcoin(PLSB).calcPayoutAndFee(
            _asicBalance
        );

        totalPLSBRewards += unclaimedRewards;
        nextMiningStartTime = block.timestamp + MINING_PERIOD + RELOAD_PERIOD;
        nextReloadTime = block.timestamp + MINING_PERIOD;

        state = State.MINING;
        currentSessionId++;

        totalAsicDepositForThePreviousSession = totalAsicDepositForTheCurrentSession;
        totalAsicDepositForTheCurrentSession = 0;

        asicUsedToMine = _asicBalance;
        PulseBitcoin(PLSB).minerStart(_asicBalance);
        emit MiningSessionStart(
            msg.sender,
            currentSessionId - 1,
            block.timestamp
        );
    }

    function getMinerStore() internal view returns (uint128, uint128, uint96, uint96, uint40, uint24) {
        return PulseBitcoin(PLSB).minerList(address(this), 0);
    }

    function startReloadPeriod() public {
        numParticipantsForThisSession = 0;
        require(state != State.RELOAD, "Already in reload period");
        require(
            block.timestamp > nextReloadTime,
            "Mining session not ended yet"
        );

        state = State.RELOAD;

        uint256 _asicBalance = IERC20(ASIC).balanceOf(address(this));
        uint256 _asicToTransfer = (_asicBalance * 5) / 100;
        uint256 _plsbToTransfer = (totalPLSBRewards * 5) / 100;

        uint40 _minerId;
        (, , , , _minerId, ) = getMinerStore();
        PulseBitcoin(PLSB).minerEnd(0, _minerId, address(this));

        IERC20(PLSB).approve(plsdStakingContract, _plsbToTransfer);
        PLSDStaker(plsdStakingContract).depositPLSB(_plsbToTransfer);
        IERC20(PLSB).safeTransfer(waatcaPool, _plsbToTransfer);

        IERC20(ASIC).approve(plsdStakingContract, _asicToTransfer);
        PLSDStaker(plsdStakingContract).depositASIC(_asicToTransfer);
        IERC20(ASIC).safeTransfer(waatcaPool, _asicToTransfer);

        totalPLSBRewards -= _plsbToTransfer * 2;
        unclaimedRewards = totalPLSBRewards;
        emit ReloadPeriodStart(msg.sender, currentSessionId, block.timestamp);
    }

    function claimReward() external nonReentrant {
        if (block.timestamp > nextReloadTime && state != State.RELOAD) {
            // mining ended, start reload period
            startReloadPeriod();
        }

        require(state == State.RELOAD, "Can't claim during mining session");
        require(asicDeposits[msg.sender].amount > 0, "No deposits");

        if (asicDeposits[msg.sender].sessionId == currentSessionId - 1) {
            // normal case - user can claim their rewards
            uint256 _plsbReward = (totalPLSBRewards * asicDeposits[msg.sender].amount) / totalAsicDepositForThePreviousSession;

            unclaimedRewards -= _plsbReward;

            asicDeposits[msg.sender].amount = 0;
            asicDeposits[msg.sender].sessionId = currentSessionId;
            IERC20(PLSB).safeTransfer(msg.sender, _plsbReward);
            emit RewardClaim(msg.sender, currentSessionId - 1, _plsbReward);
        } else if (asicDeposits[msg.sender].sessionId == currentSessionId) {
            revert("Mining for this session is not finished yet");
        } else {
            // Invalid sessionId - reset user's amount and sessionId
            asicDeposits[msg.sender].amount = 0;
            asicDeposits[msg.sender].sessionId = currentSessionId;

            emit RewardReset(msg.sender, currentSessionId);
        }

        if (block.timestamp > nextMiningStartTime && state == State.RELOAD) {
            // reload period ended, start mining
            startMiningSession();
        }
    }




    function depositCARNToTrappedPool(uint256 _carnAmount) external nonReentrant {
        trappedAsicReleasePool += _carnAmount;
        IERC20(CARN).safeTransferFrom(msg.sender, address(this), _carnAmount);
        emit CARNDepositToTrappedPool(msg.sender, _carnAmount, block.timestamp);
        if (
            trappedAsicReleasePool >= TRAPPED_POOL_TARGET &&
            state == State.RELOAD
        ) {
            require(trappedAsicReleasePool >= TRAPPED_POOL_TARGET, "Target not reached yet");
            releaseASIC();
            releaseCARN();
            trappedAsicReleasePool = 0;
        }
    }

    function releaseASIC() internal {
        uint256 _asicBalance = IERC20(ASIC).balanceOf(address(this)) - totalAsicDepositForTheCurrentSession;
        uint256 _asicToPlsdStaker = (_asicBalance * 60) / 100;
        uint256 _asicToWaatca = _asicBalance - _asicToPlsdStaker;

        IERC20(ASIC).approve(plsdStakingContract, _asicToPlsdStaker);
        PLSDStaker(plsdStakingContract).depositASIC(_asicToPlsdStaker);
        IERC20(ASIC).safeTransfer(waatcaPool, _asicToWaatca);
        emit ASICReleased(_asicBalance, block.timestamp);
    }

    function releaseCARN() internal {
        uint256 _carnBalance = IERC20(CARN).balanceOf(address(this));
        IERC20(CARN).safeTransfer(buyAndBurnContract, _carnBalance);
        emit CARNReleased(_carnBalance, block.timestamp);
    }
}