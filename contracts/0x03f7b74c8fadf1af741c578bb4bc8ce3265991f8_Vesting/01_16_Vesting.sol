//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Token.sol";

uint256 constant CLIFF_PERIOD = 6 * 30 * 24 * 60 * 60;
uint256 constant RELEASE_PERIOD = 3 * 30 * 24 * 60 * 60;

// uint256 constant CLIFF_PERIOD = 30 * 60;
// uint256 constant RELEASE_PERIOD = 15 * 60;

// Author: @webitfactory
contract Vesting is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // STRUCTS
    struct ClaimSchedule {
        uint256 when;
        uint256 amount;
        uint256 transferred;
        uint256 claimed;
    }

    struct ScheduleStats {
        uint256 claimed;
        uint256 vested;
        uint256 transferred;
    }

    struct InvestorData {
        ScheduleStats stats;
        ClaimSchedule[] schedules;
    }

    struct _LoopVariables {
        uint256 startIndex;
        uint256 endIndex;
        uint256 arrayLength;
    }

    struct TransferChunk {
        uint256 sourceScheduleId;
        uint256 amount;
    }

    // PROPERTIES
    Token internal token;
    mapping(address => InvestorData) private investorsData;
    bool private _claimEnabled;

    // EVENTS
    event TransferredOwnership(
        address indexed from,
        address indexed to,
        uint256 timestamp
    );
    event GlobalClaimEnabling(bool isEnabled, uint256 timestamp);
    event VestedTokensTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 timestamp
    );
    event VestedTokensClaim(address who, uint256 amount, uint256 timestamp);
    event VestedTokensAdded(address vestor, uint256 amount, uint256 timestamp);

    // MODIFIERS
    modifier globalClaimEnabled() {
        require(_claimEnabled == true, "Claiming is disabled globally");
        _;
    }

    modifier onlyContractOwner() {
        require(
            owner() == _msgSender(),
            "You are not the owner of the contract"
        );
        _;
    }

    modifier tokenSet() {
        require(
            address(token) != address(0),
            "Address of the token contract is not set"
        );
        _;
    }

    // METHODS
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();

        _claimEnabled = true;
    }

    function transferOwnership(
        address newOwner
    ) public virtual override nonReentrant onlyContractOwner {
        require(
            newOwner != address(0),
            "Cannot transfer ownership to the zero address"
        );

        _transferOwnership(newOwner);

        emit TransferredOwnership(msg.sender, newOwner, block.timestamp);
    }

    function setTokensAddress(
        address contractAddress
    ) public onlyContractOwner nonReentrant {
        require(
            contractAddress != address(0),
            "Cannot set the address of the token contract to the zero address"
        );

        token = Token(contractAddress);
    }

    function getTokensAddress() public view returns (Token) {
        return token;
    }

    function setGlobalClaimEnabled(
        bool isEnabled
    ) public payable onlyContractOwner nonReentrant {
        _claimEnabled = isEnabled;

        emit GlobalClaimEnabling(isEnabled, block.timestamp);
    }

    function getGlobalClaimEnabled() public view returns (bool) {
        return _claimEnabled;
    }

    function vestTokens(
        address vestor,
        uint256 totalAmount
    ) public tokenSet nonReentrant {
        require(
            investorsData[vestor].schedules.length == 0,
            "Vestor already has tokens vested"
        );

        ClaimSchedule[] memory schedule = new ClaimSchedule[](10);

        uint256 remaining = totalAmount;
        uint256 currentTime = getCurrentTime();
        uint256 usedAmount = totalAmount / 10;
        remaining -= usedAmount;

        // After 6 months, 10% of the tokens will be available
        // Then, each 3 months, 10% of the tokens will be available

        schedule[0] = ClaimSchedule({
            when: currentTime + CLIFF_PERIOD,
            amount: usedAmount,
            transferred: 0,
            claimed: 0
        });

        for (uint256 i = 1; i < 10; ++i) {
            if (i == 9) {
                usedAmount = remaining;
            } else {
                usedAmount = totalAmount / 10;
            }

            remaining -= usedAmount;

            schedule[i] = ClaimSchedule({
                when: schedule[i - 1].when + RELEASE_PERIOD,
                amount: usedAmount,
                transferred: 0,
                claimed: 0
            });
        }

        _addVestedTokens(vestor, schedule);
    }

    function claimVestedTokens(
        uint256 amount
    ) public tokenSet globalClaimEnabled nonReentrant {
        InvestorData storage data = investorsData[msg.sender];

        uint256 scheduleLength = data.schedules.length;
        uint256 remainingAmount = amount;
        uint256 currentTime = getCurrentTime();

        for (uint256 i = 0; i < scheduleLength; ++i) {
            ClaimSchedule storage schedule = data.schedules[i];

            if (schedule.when <= currentTime) {
                uint256 claimable = schedule.amount -
                    schedule.claimed -
                    schedule.transferred;

                if (claimable > remainingAmount) {
                    schedule.claimed += remainingAmount;
                    data.stats.claimed += remainingAmount;
                    remainingAmount = 0;
                } else {
                    schedule.claimed += claimable;
                    data.stats.claimed += claimable;
                    remainingAmount -= claimable;
                }

                if (remainingAmount == 0) {
                    break;
                }
            }
        }

        require(remainingAmount == 0, "Not enough claimable tokens");

        token.transfer(msg.sender, amount);

        emit VestedTokensClaim(msg.sender, amount, block.timestamp);
    }

    function getVestorData() public view returns (InvestorData memory) {
        return investorsData[msg.sender];
    }

    function getClaimableAmount() public view returns (uint256) {
        uint256 amount = 0;
        uint256 scheduleLength = investorsData[msg.sender].schedules.length;
        uint256 currentTime = getCurrentTime();

        if (!_claimEnabled) return 0;

        for (uint256 i = 0; i < scheduleLength; ++i) {
            ClaimSchedule memory schedule = investorsData[msg.sender].schedules[
                i
            ];

            if (schedule.when <= currentTime) {
                amount +=
                    schedule.amount -
                    schedule.transferred -
                    schedule.claimed;
            }
        }

        return amount;
    }

    // HELPER METHODS
    function _computeScheduleStats(
        ClaimSchedule[] memory claimSchedule
    ) public pure returns (ScheduleStats memory) {
        ScheduleStats memory stats = ScheduleStats({
            claimed: 0,
            vested: 0,
            transferred: 0
        });

        uint256 scheduleLength = claimSchedule.length;
        for (uint256 i = 0; i < scheduleLength; ++i) {
            stats.vested += claimSchedule[i].amount;
            stats.transferred += claimSchedule[i].transferred;
            stats.claimed += claimSchedule[i].claimed;
        }

        return stats;
    }

    function _addVestedTokens(
        address vestor,
        ClaimSchedule[] memory claimSchedule
    ) private tokenSet {
        require(
            vestor != address(0),
            "Cannot vest tokens for the zero address"
        );

        InvestorData storage data = investorsData[vestor];
        uint256 scheduleLength = claimSchedule.length;
        uint256 vested = 0;

        for (uint256 i = 0; i < scheduleLength; ++i) {
            data.schedules.push(
                ClaimSchedule({
                    when: claimSchedule[i].when,
                    amount: claimSchedule[i].amount,
                    transferred: claimSchedule[i].transferred,
                    claimed: claimSchedule[i].claimed
                })
            );
            data.stats.claimed += claimSchedule[i].claimed;
            data.stats.transferred += claimSchedule[i].transferred;
            data.stats.vested += claimSchedule[i].amount;
            vested += claimSchedule[i].amount;
        }

        emit VestedTokensAdded(vestor, vested, block.timestamp);
    }

    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}