// SPDX-License-Identifier: MIT

/// @title The Saturna Lottery Contract

pragma solidity ^0.8.6;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISaturnaLotteryHub} from "./interfaces/ISaturnaLotteryHub.sol";
import {KeeperCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import {ITicket} from "./interfaces/ITicket.sol";
import {RNGInterface} from "./interfaces/RNGInterface.sol";

contract SaturnaLotteryHub is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ISaturnaLotteryHub,
    KeeperCompatibleInterface,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20 for IERC20;

    IERC20 private s_usdc;

    ITicket public s_ticket;

    uint256 private s_entryFee;

    uint256 private s_duration;

    uint256 private s_houseFeePercentage;

    bool private s_isHouseFeesPercentageLocked;

    Lottery public s_lottery;

    CountersUpgradeable.Counter private s_lotteryId;

    uint256 private s_entryBuffer;

    mapping(uint256 => mapping(uint256 => address)) public s_participants;

    mapping(uint256 => mapping(address => bool)) public s_hasEntered;

    RNGInterface internal s_rng;

    RNGInterface.RngRequest internal s_rngRequest;

    function initialize(
        address _usdcAddress,
        uint256 _entryFee,
        uint256 _duration,
        uint256 _houseFeePercentage,
        uint256 _entryBuffer,
        RNGInterface _rngService,
        ITicket _ticket
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _pause();

        s_usdc = IERC20(_usdcAddress);
        s_entryFee = _entryFee;
        s_duration = _duration;
        s_houseFeePercentage = _houseFeePercentage;
        _setRngService(_rngService);
        s_entryBuffer = _entryBuffer;
        s_isHouseFeesPercentageLocked = false;
        s_ticket = _ticket;
    }

    /// ***********************
    /// ***EXTERNAL FUNCTIONS**
    /// ***********************

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (
            bool upKeepNeeded,
            bytes memory /*performData*/
        )
    {
        bool timePased = (_currentTime() > s_lottery.endTime);
        bool upkeepNeeded = (timePased);
        return (upkeepNeeded, "");
    }

    /// ***********************
    /// ***PUBLIC FUNCTIONS****
    /// ***********************

    function enterLottery() public nonReentrant whenNotPaused {
        Lottery memory _lottery = s_lottery;

        require(_currentTime() <= _lottery.endTime, "Lottery Ended");

        if (s_hasEntered[s_lotteryId.current()][_msgSender()]) {
            revert SaturnaLotteryHub__AlreadyEnteredThisLottery();
        }

        if (!(_currentTime() <= _lottery.endTime - s_entryBuffer)) {
            revert SaturnaLotteryHub__CannotEnterLotteryEnteryBufferExpired();
        }

        s_ticket.mint(s_lotteryId.current(), _msgSender());
        s_usdc.safeTransferFrom(_msgSender(), address(this), s_entryFee);

        s_participants[s_lotteryId.current()][_lottery.entries] = _msgSender();
        s_lottery.entries++;
        s_hasEntered[s_lotteryId.current()][_msgSender()] = true;

        emit LotteryEntered(_msgSender(), _currentTime());
    }

    function performUpkeep(
        bytes calldata /*performData*/
    ) external override nonReentrant whenNotPaused {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Upkeep not needed");
        _settleLotteryAndDeclareWinner();
        _payWinnerAndHouse();
        _createLottery();
    }

    function settleLotteryAndPay() public nonReentrant whenPaused {
        _settleLotteryAndDeclareWinner();
        _payWinnerAndHouse();
    }

    /// ***********************
    /// **INTERNAL FUNCTIONS***
    /// ***********************

    function _createLottery() internal {
        uint256 startTime = _currentTime();
        uint256 endTime = startTime + s_duration;

        s_lotteryId.increment();

        s_lottery = Lottery({
            lotteryId: s_lotteryId.current(),
            startTime: startTime,
            endTime: endTime,
            entryFee: s_entryFee,
            entries: 0,
            winner: payable(owner()),
            setteled: false
        });

        (address feeToken, uint256 requestFee) = s_rng.getRequestFee();

        if (feeToken != address(0) && requestFee > 0) {
            IERC20(feeToken).safeIncreaseAllowance(address(s_rng), requestFee);
        }

        (uint32 requestId, uint32 lockBlock) = s_rng.requestRandomNumber();

        s_rngRequest.id = requestId;
        s_rngRequest.lockBlock = lockBlock;
        s_rngRequest.requestedAt = _currentTime();

        emit LotteryCreated(s_lotteryId.current(), startTime, endTime);
    }

    function _currentTime() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }

    function _settleLotteryAndDeclareWinner() internal {
        if (_currentTime() <= s_lottery.endTime)
            revert SaturnaLotteryHub__LotteryHasNotEnded();

        uint256 randomNumber = s_rng.randomNumber(s_rngRequest.id);
        uint64 time = _currentTime();

        if (s_lottery.entries != 0) {
            uint256 moduloRandomNumber = randomNumber % s_lottery.entries;

            address winner = s_participants[s_lotteryId.current()][
                moduloRandomNumber
            ];

            if (winner == address(0)) {
                s_lottery.winner = payable(owner());
            }

            s_lottery.winner = payable(winner);

            emit WinnerDeclared(winner, time);
        } else {
            s_lottery.winner = payable(owner());
            emit WinnerDeclared(owner(), time);
        }

        emit LotterySetteled(s_lotteryId.current());
    }

    function _payWinnerAndHouse() internal {
        uint256 balance = s_usdc.balanceOf(address(this));
        uint256 commision = (balance / 100) * s_houseFeePercentage;

        s_usdc.safeTransfer(owner(), commision);
        s_usdc.safeTransfer(s_lottery.winner, s_usdc.balanceOf(address(this)));

        emit WinnerPaid(s_lottery.winner, balance - commision);
        emit CommissionIssued(owner(), commision);
        emit WinnerDeclaredAndPaid(s_lottery.winner, balance, _currentTime());
    }

    function _setRngService(RNGInterface _rng) internal {
        s_rng = _rng;
        emit RNGUpdated(_rng);
    }

    /// ***********************
    /// *****VIEW FUNCTIONS****
    /// ***********************

    function getEntryFee() public view returns (uint256) {
        return s_entryFee;
    }

    function getCurrentLotteryId() public view returns (uint256) {
        return s_lotteryId.current();
    }

    function getDuration() public view returns (uint256) {
        return s_duration;
    }

    function getCurrentLotteryStartTime() public view returns (uint256) {
        return s_lottery.startTime;
    }

    function getCurrentLotteryEndTime() public view returns (uint256) {
        return s_lottery.endTime;
    }

    function getHouseFeePercentage() public view returns (uint256) {
        return s_houseFeePercentage;
    }

    function isHouseFeePercentageLocked() public view returns (bool) {
        return s_isHouseFeesPercentageLocked;
    }

    function getEntryBuffer() public view returns (uint256) {
        return s_entryBuffer;
    }

    /// ***********************
    /// ****HOUSE FUNCTIONS****
    /// ***********************

    function changeEntryFee(uint256 _entryFee) public whenNotPaused onlyOwner {
        s_entryFee = _entryFee;
        emit EntryFeeChanged(_entryFee);
    }

    function changeDuration(uint256 _duration) public whenNotPaused onlyOwner {
        s_duration = _duration;
        emit DurationChanged(_duration);
    }

    function changeHouseFeePercentage(uint256 _houseFeePercentage)
        public
        whenNotPaused
        onlyOwner
    {
        if (s_isHouseFeesPercentageLocked)
            revert SaturnaLotteryHub__HouseFeePercentageLocked();
        s_houseFeePercentage = _houseFeePercentage;
        emit HouseFeePercentageChanged(_houseFeePercentage);
    }

    function setRngService(RNGInterface _rng) public onlyOwner {
        _setRngService(_rng);
    }

    function lockHouseFeePercentage() public whenNotPaused onlyOwner {
        if (s_isHouseFeesPercentageLocked)
            revert SaturnaLotteryHub__HouseFeePercentageLocked();
        s_isHouseFeesPercentageLocked = true;
        emit HouseFeePercentageLocked();
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();

        if (s_lottery.startTime == 0 || s_lottery.setteled) {
            _createLottery();
        }
    }

    function deposite() public payable {}

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}