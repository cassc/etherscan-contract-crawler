// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IHexToken {
    function stakeStart(
        uint256 newStakedHearts,
        uint256 newStakedDays
    ) external;

    function stakeGoodAccounting(
        address stakerAddr,
        uint256 stakeIndex,
        uint40 stakeIdParam
    ) external;

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    function stakeLists(
        address,
        uint256
    )
    external
    view
    returns (uint40, uint72, uint72, uint16, uint16, uint16, bool);

    function currentDay() external view returns (uint256);
}

interface IPLSDStaker {
    function depositHEX(uint256 _amount) external;
}

contract HEXCommunityStaker is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MIN_HEX_DEPOSIT = 100 * 1e8;
    uint256 public constant ETH_FEE = 0.002 ether;
    uint256 public constant STAKING_PERIOD = 60; // 60 days
    uint256 public constant RELOAD_PERIOD = 9; // 9 days
    uint256 public constant TRAPPED_POOL_TARGET = 369000 * 1e12; // 369K CARN
    uint256 public constant STARTOFF_AMOUNT = 1000000 * 1e8; // 1M HEX

    uint256 public constant HEXTOPLSDSTAKER_PERCENTAGE = 10;
    uint256 public constant HEXTOWAATCA_PERCENTAGE = 10;
    uint256 public constant HEXTOTHIRDPOOL_PERCENTAGE = 10;

    uint256 public constant TRAPPED_HEXTOPLSDSTAKER_PERCENTAGE = 30;
    uint256 public constant TRAPPED_HEXTOWAATCA_PERCENTAGE = 30;
    uint256 public constant TRAPPED_HEXTOTHIRDPOOL_PERCENTAGE = 40;

    // Token Addresses
    address public immutable CARN;
    address public immutable HEX;

    address public immutable waatcaPool;
    address public immutable buyAndBurnContract;
    address public immutable plsdStakingContract;
    address public immutable thirdPoolAddress;

    enum State {
        RELOAD,
        STAKING
    }

    State public state; // keeps track of the current state of the contract

    struct HexDeposit {
        uint256 amount;
        uint256 sessionId;
    }

    // Variables
    mapping(address => HexDeposit) public hexDeposits; // keeps track of user's HEX deposits for the session

    uint256 public totalHexDepositForThePreviousSession; // total HEX deposited for the previous sessionId
    uint256 public totalHexDepositForTheCurrentSession; // total HEX deposited for the current sessionId
    uint256 public numParticipantsForThisSession; // total depositors for each session
    uint256 public numTotalDepositsForAllSessions; // total sum of all depositors from all sessions
    uint256 public trappedHexReleasePool; // keeps track of carn deposited by the community

    uint256 public nextStakingStartTime; // start of next staking session as timestamp

    uint256 public balanceBefore;

    uint256 public totalRewards; // total rewards for the staking session
    uint256 public currentSessionId; // keeps track of current staking session Id
    uint256 public unclaimedRewards; // keeps track of unclaimed amount from reward pool

    // Events
    event Deposit(
        address indexed depositor,
        uint256 indexed sessionId,
        uint256 hexAmount
    );

    event StakingSessionStart(
        address indexed caller,
        uint256 id,
        uint256 startTime
    );

    event RewardClaim(
        address indexed withdrawer,
        uint256 indexed sessionId,
        uint256 hexAmount
    );

    event RewardReset(address indexed staker, uint256 indexed sessionId);

    event ReloadPeriodStart(
        address indexed caller,
        uint256 id,
        uint256 reloadTime
    );

    event CARNDepositToTrappedPool(
        address indexed depositor,
        uint256 amount,
        uint256 time
    );

    event HEXReleased(uint256 amount, uint256 time);
    event CARNReleased(uint256 amount, uint256 time);

    constructor(
        address _waatcaPoolAddress,
        address _buyAndBurnContractAddress,
        address _plsdStakingContractAddress,
        address _thirdPoolAddress,
        address _CARN,
        address _HEX
    ) {
        waatcaPool = _waatcaPoolAddress;
        buyAndBurnContract = _buyAndBurnContractAddress;
        plsdStakingContract = _plsdStakingContractAddress;
        thirdPoolAddress = _thirdPoolAddress;
        CARN = _CARN;
        HEX = _HEX;

        nextStakingStartTime = block.timestamp + 30 days;
        currentSessionId = 1;
    }

    // Functions
    // Deposit function
    function deposit(uint256 _hexAmount) public payable nonReentrant {
        numParticipantsForThisSession += 1;
        numTotalDepositsForAllSessions += 1;
        if (
            hexDeposits[msg.sender].amount == 0 &&
            hexDeposits[msg.sender].sessionId != currentSessionId
        ) {
            // new staker/staker don't have any pending claims, update sessionId
            hexDeposits[msg.sender].sessionId = currentSessionId;
        }

        require(msg.value == ETH_FEE, "value sent does not match with eth fee");

        require(
            _hexAmount >= MIN_HEX_DEPOSIT,
            "At least minimum HEX deposit required"
        );

        require(state == State.RELOAD, "Not in reload period");

        require(
            hexDeposits[msg.sender].sessionId == currentSessionId,
            "Please claim rewards for the previous session"
        );

        hexDeposits[msg.sender].amount += _hexAmount;
        totalHexDepositForTheCurrentSession += _hexAmount;

        // Transfer the HEX to contract
        IERC20(HEX).safeTransferFrom(msg.sender, address(this), _hexAmount);

//        // Transfer the CARN to contract
//        if (currentSessionId == 1 && _hexAmount > 10000 * 1e8){
//            IERC20(CARN).safeTransferFrom(msg.sender, address(this), 100 * 1e12);
//        }

        emit Deposit(msg.sender, currentSessionId, _hexAmount);

        // Start staking session if it has not already started
        if (currentSessionId == 1 && state == State.RELOAD) {
            if (
                block.timestamp > nextStakingStartTime &&
                totalHexDepositForTheCurrentSession >= STARTOFF_AMOUNT
            ) {
                startStakingSession();
            }
        } else {
            if (
                block.timestamp > nextStakingStartTime && state == State.RELOAD
            ) {
                startStakingSession();
            }
        }
    }

    // function to trigger the staking session
    function startStakingSession() public {
        require(state != State.STAKING, "Staking session already started");
        require(
            block.timestamp > nextStakingStartTime,
            "Reload period not ended yet"
        );

        if (currentSessionId == 1)
            require(
                totalHexDepositForTheCurrentSession >= STARTOFF_AMOUNT,
                "Startoff amount not reached"
            );

        uint256 _hexBalance = IERC20(HEX).balanceOf(address(this));
        balanceBefore = _hexBalance;

        state = State.STAKING;
        currentSessionId++;
        unclaimedRewards = 0;

        totalHexDepositForThePreviousSession = totalHexDepositForTheCurrentSession;
        totalHexDepositForTheCurrentSession = 0;

        IHexToken(HEX).stakeStart(_hexBalance, STAKING_PERIOD);

        emit StakingSessionStart(
            msg.sender,
            currentSessionId - 1,
            block.timestamp
        );
    }

    function getStakeStore()
    public
    view
    returns (uint40, uint72, uint72, uint16, uint16, uint16, bool)
    {
        return IHexToken(HEX).stakeLists(address(this), 0);
    }

    // function to trigger the reload period
    // This function needs to be called manually to end the stake and get rewards
    function startReloadPeriod() public nonReentrant {
        numParticipantsForThisSession = 0;
        uint256 _currentDay = IHexToken(HEX).currentDay();
        uint40 _stakeId;
        uint16 _lockedDay;
        (_stakeId, , , _lockedDay, , , ) = getStakeStore();

        require(
            _currentDay - _lockedDay >= STAKING_PERIOD,
            "Staking session not ended yet"
        );
        require(state != State.RELOAD, "Already in reload period");

        state = State.RELOAD;

        IHexToken(HEX).stakeEnd(0, _stakeId);

        uint256 _balanceAfter = IERC20(HEX).balanceOf(address(this));
        totalRewards = _balanceAfter - balanceBefore;

        uint256 _hexToPLSDStaker = (totalRewards * HEXTOPLSDSTAKER_PERCENTAGE) /
        100;
        uint256 _hexToWaatca = (totalRewards * HEXTOWAATCA_PERCENTAGE) / 100;
        uint256 _hexToThirdPool = (totalRewards * HEXTOTHIRDPOOL_PERCENTAGE) /
        100;

        totalRewards -= (_hexToPLSDStaker + _hexToWaatca + _hexToThirdPool);
        unclaimedRewards = totalRewards;

        IERC20(HEX).approve(plsdStakingContract, _hexToPLSDStaker);
        IPLSDStaker(plsdStakingContract).depositHEX(_hexToPLSDStaker);

        IERC20(HEX).safeTransfer(waatcaPool, _hexToWaatca);
        IERC20(HEX).safeTransfer(thirdPoolAddress, _hexToThirdPool);

        nextStakingStartTime = block.timestamp + RELOAD_PERIOD * 86400;


        // Reward caller with ethBalance to compensate gas cost
        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);

        emit ReloadPeriodStart(msg.sender, currentSessionId, block.timestamp);
    }

    // function to claim rewards once staking ends
    function claimReward() external nonReentrant {
        require(state == State.RELOAD, "Can't claim during staking session");
        require(hexDeposits[msg.sender].amount > 0, "No deposits");

        if (hexDeposits[msg.sender].sessionId == currentSessionId - 1) {
            // normal case - user can claim their rewards
            uint256 _reward = (totalRewards * hexDeposits[msg.sender].amount) /
            totalHexDepositForThePreviousSession;

            unclaimedRewards -= _reward;

            hexDeposits[msg.sender].amount = 0;
            hexDeposits[msg.sender].sessionId = currentSessionId;
            IERC20(HEX).safeTransfer(msg.sender, _reward);
            emit RewardClaim(msg.sender, currentSessionId - 1, _reward);
        } else if (hexDeposits[msg.sender].sessionId == currentSessionId) {
            revert("Staking for this session is not finished yet");
        } else {
            // Invalid sessionId - reset user's amount and sessionId
            hexDeposits[msg.sender].amount = 0;
            hexDeposits[msg.sender].sessionId = currentSessionId;

            emit RewardReset(msg.sender, currentSessionId);
        }

        // Start staking session if it has not already started
        if (currentSessionId == 1 && state == State.RELOAD) {
            if (
                block.timestamp > nextStakingStartTime &&
                totalHexDepositForTheCurrentSession >= STARTOFF_AMOUNT
            ) {
                startStakingSession();
            }
        } else {
            if (
                block.timestamp > nextStakingStartTime && state == State.RELOAD
            ) {
                startStakingSession();
            }
        }
    }

    // function to deposit CARN tokens to the trapped HEX release pool
    function depositCARNToTrappedPool(
        uint256 _carnAmount
    ) external nonReentrant {
        trappedHexReleasePool += _carnAmount;
        IERC20(CARN).safeTransferFrom(msg.sender, address(this), _carnAmount);
        emit CARNDepositToTrappedPool(msg.sender, _carnAmount, block.timestamp);

        if (
            trappedHexReleasePool >= TRAPPED_POOL_TARGET &&
            state == State.RELOAD
        ) {
            releaseHEX();
            releaseCARN();
            trappedHexReleasePool = 0;
        }
    }

    function releaseHEX() internal {
        require(
            trappedHexReleasePool >= TRAPPED_POOL_TARGET,
            "Target not reached yet"
        );

        uint256 _hexBalance = IERC20(HEX).balanceOf(address(this)) - (totalHexDepositForTheCurrentSession + unclaimedRewards);
        uint256 _hexToPlsdStaker = (_hexBalance * TRAPPED_HEXTOPLSDSTAKER_PERCENTAGE) / 100;
        uint256 _hexToWaatca = (_hexBalance * TRAPPED_HEXTOWAATCA_PERCENTAGE) / 100;
        uint256 _hexToThirdPool = _hexBalance - (_hexToPlsdStaker + _hexToWaatca);

        IERC20(HEX).approve(plsdStakingContract, _hexToPlsdStaker);
        IPLSDStaker(plsdStakingContract).depositHEX(_hexToPlsdStaker);

        IERC20(HEX).safeTransfer(waatcaPool, _hexToWaatca);
        IERC20(HEX).safeTransfer(thirdPoolAddress, _hexToThirdPool);

        emit HEXReleased(_hexBalance, block.timestamp);
    }

    function releaseCARN() internal {
        require(
            trappedHexReleasePool >= TRAPPED_POOL_TARGET,
            "Target not reached yet"
        );

        uint256 _carnBalance = IERC20(CARN).balanceOf(address(this));
        IERC20(CARN).safeTransfer(buyAndBurnContract, _carnBalance);
        emit CARNReleased(_carnBalance, block.timestamp);
    }
}