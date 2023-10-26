// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract PyroLottery is AccessControl, VRFConsumerBaseV2 {
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    VRFCoordinatorV2Interface COORDINATOR;

    struct Lottery {
        uint256 tokens;
        uint256 totalTickets;
        uint256 startTime;
        mapping(address => uint256) userTickets;
        mapping(uint256 => address) tickets;
        bool fullfilled;
        address winner;
    }

    // chainlink vrf setup
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 s_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    mapping(uint256 => uint256) private s_rollers;

    IERC20 public pyro;
    uint256 public lotteryAmount;

    uint256 public currentLotteryId = 1;
    uint256 public lotteryFrequency = 1 days;

    mapping(uint256 => Lottery) public lotteries;
    mapping(address => bool) public blacklist;

    constructor(address _pyro, address _lp, uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        pyro = IERC20(_pyro);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEPOSITOR_ROLE, _pyro);
        blacklist[_lp] = true;
        lotteries[currentLotteryId].startTime = block.timestamp;

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function deposit(address _user, uint256 _amount) external onlyRole(DEPOSITOR_ROLE) {
        pyro.transferFrom(_user, address(this), _amount);
        lotteryAmount += _amount;

        if (block.timestamp >= lotteries[currentLotteryId].startTime + lotteryFrequency) {
            _startLottery();
        }
    }

    function manualDeposit(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pyro.transferFrom(msg.sender, address(this), _amount);
        lotteryAmount += _amount;
    }

    function addTicket(address _user, uint256 _amount) external onlyRole(DEPOSITOR_ROLE) {
        if (!blacklist[_user]) {
            lotteries[currentLotteryId].userTickets[_user] += _amount;
            for (uint256 i = 0; i < _amount; i++) {
                lotteries[currentLotteryId].tickets[lotteries[currentLotteryId].totalTickets + i] = _user;
            }
            lotteries[currentLotteryId].totalTickets += _amount;
        }
    }

    function getUserTickets(address _user, uint256 _lotteryId) external view returns (uint256) {
        return lotteries[_lotteryId].userTickets[_user];
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 lotteryId = s_rollers[requestId];
        require(lotteryId > 0, "Lottery not found");

        uint256 winningTicket = (randomWords[0] % lotteries[lotteryId].totalTickets);

        address winner = lotteries[lotteryId].tickets[winningTicket];
        lotteries[lotteryId].winner = winner;
        lotteries[lotteryId].fullfilled = true;

        pyro.transfer(winner, lotteries[lotteryId].tokens);
    }

    function _startLottery() internal {
        lotteries[currentLotteryId].tokens = lotteryAmount;
        lotteryAmount = 0;

        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords
        );

        s_rollers[requestId] = currentLotteryId;
        currentLotteryId++;
        lotteries[currentLotteryId].startTime = block.timestamp;
    }

    function updateLotteryFrequency(uint256 _frequency) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lotteryFrequency = _frequency;
    }

    function updateBlacklist(address _address, bool _blacklist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklist[_address] = _blacklist;
    }

    function updateChainlinkVRF(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vrfCoordinator = _vrfCoordinator;
        s_keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }
}