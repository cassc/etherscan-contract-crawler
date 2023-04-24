// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/NameVersion.sol";
import "../token/IERC20.sol";
import "../library/SafeERC20.sol";
import "../library/SafeMath.sol";
import "../library/SafeMath.sol";
import "./RebateCalculator.sol";
import "./RebateStorage.sol";

contract RebateImplementation is RebateStorage, NameVersion {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for int256;

    event SetUpdater(address updater, bool isActive);

    event SetApprover(address approver, bool isActive);

    event TraderRegistered(
        address indexed trader,
        address indexed broker,
        uint256 timestamp
    );

    event BrokerRegistered(
        address indexed broker,
        address indexed recruiter,
        uint256 timestamp
    );

    event RecruiterRegistered(address indexed recruiter, uint256 timestamp);

    event ClaimRebate(address indexed account, uint256 amount);

    using SafeERC20 for IERC20;

    uint256 constant UONE = 1e18;

    address public immutable tokenB0;

    uint256 public immutable decimalsTokenB0;

    address public immutable collector;

    constructor(
        address tokenB0_,
        address collector_
    ) NameVersion("RebateImplementation", "1.0.0") {
        tokenB0 = tokenB0_;
        decimalsTokenB0 = IERC20(tokenB0_).decimals();
        collector = collector_;
    }

    function setUpdater(address updater, bool isActive) external _onlyAdmin_ {
        isUpdater[updater] = isActive;
        emit SetUpdater(updater, isActive);
    }

    function setApprover(address approver, bool isActive) external _onlyAdmin_ {
        isApprover[approver] = isActive;
        emit SetApprover(approver, isActive);
    }

    function registerTrader(string calldata brokerCode) external {
        address account = msg.sender;
        bytes32 brokerId = keccak256(abi.encodePacked(brokerCode));
        address brokerAddress = brokerAddresses[brokerId];

        require(
            brokerAddress != address(0),
            "RebateImplementation: referral not exist"
        );
        require(
            traderReferral[account] == address(0),
            "RebateImplementation: can not reset"
        );

        traderReferral[account] = brokerAddress;
        emit TraderRegistered(account, brokerAddress, block.timestamp);
    }

    function registerBroker(
        string calldata brokerCode,
        string calldata recruiterCode
    ) external {
        address account = msg.sender;
        bytes32 brokerId = keccak256(abi.encodePacked(brokerCode));
        bytes32 recruiterId = keccak256(abi.encodePacked(recruiterCode));
        address recruiter = recruiterAddresses[recruiterId];
        require(
            brokerAddresses[brokerId] == address(0),
            "RebateImplementation: code not available"
        );
        require(
            brokerIds[account] == bytes32(0),
            "RebateImplementation: can not reset"
        );
        require(
            recruiter != address(0),
            "RebateImplementation: referral not exist"
        );

        brokerAddresses[brokerId] = account;
        brokerIds[account] = brokerId;
        brokerInfos[account] = BrokerInfo({
            code: brokerCode,
            id: brokerId,
            referral: recruiter
        });

        emit BrokerRegistered(account, recruiter, block.timestamp);
    }

    function registerRecruiter(
        address recruiter,
        string calldata recruiterCode
    ) external {
        require(isApprover[msg.sender], "RebateImplementation: only approver");
        bytes32 recruiterId = keccak256(abi.encodePacked(recruiterCode));
        require(
            recruiterAddresses[recruiterId] == address(0),
            "RebateImplementation: code not available"
        );
        require(
            recruiterIds[recruiter] == bytes32(0),
            "RebateImplementation: can not reset"
        );

        recruiterAddresses[recruiterId] = recruiter;
        recruiterIds[recruiter] = recruiterId;
        recruiterInfos[recruiter] = RecruiterInfo({
            code: recruiterCode,
            id: recruiterId
        });

        emit RecruiterRegistered(recruiter, block.timestamp);
    }

    function updateFees(
        address[] calldata brokers,
        int256[] calldata updateBrokerFees,
        address[] calldata recruiters,
        int256[] calldata updateRecruiterFees,
        uint256 timestamp
    ) external {
        require(isUpdater[msg.sender], "RebateImplementation: only updater");
        require(
            timestamp > updatedTimestamp,
            "RebateImplementation: duplicate update"
        );
        require(
            brokers.length == updateBrokerFees.length &&
                recruiters.length == updateRecruiterFees.length,
            "RebateImplementation: invalid input length"
        );
        if (brokers.length > 0) {
            for (uint256 i = 0; i < brokers.length; i++) {
                brokerFees[brokers[i]] += updateBrokerFees[i];
            }
        }
        if (recruiters.length > 0) {
            for (uint256 i = 0; i < recruiters.length; i++) {
                recruiterFees[recruiters[i]] += updateRecruiterFees[i];
            }
        }
        updatedTimestamp = timestamp;
    }

    function claimBrokerRebate() external _reentryLock_ {
        uint256 fee = brokerFees[msg.sender].itou();
        (, uint256 totalRebate) = RebateCalculator.calculateTotalBrokerRebate(
            fee
        );
        uint256 claimed = brokerClaimed[msg.sender];
        require(
            totalRebate > claimed,
            "RebateImplementation: nothing to claim"
        );
        uint256 unclaimed = totalRebate - claimed;
        brokerClaimed[msg.sender] = totalRebate;

        ICollector(collector).transferOut(
            msg.sender,
            unclaimed.rescale(18, decimalsTokenB0)
        );
        emit ClaimRebate(msg.sender, unclaimed.rescale(18, decimalsTokenB0));
    }

    function claimRecruiterRebate() external _reentryLock_ {
        uint256 fee = recruiterFees[msg.sender].itou();
        (, uint256 totalRebate) = RebateCalculator
            .calculateTotalRecruiterRebate(fee);
        uint256 claimed = recruiterClaimed[msg.sender];
        require(
            totalRebate > claimed,
            "RebateImplementation: nothing to claim"
        );

        uint256 unclaimed = totalRebate - claimed;
        recruiterClaimed[msg.sender] = totalRebate;

        ICollector(collector).transferOut(
            msg.sender,
            unclaimed.rescale(18, decimalsTokenB0)
        );
        emit ClaimRebate(msg.sender, unclaimed.rescale(18, decimalsTokenB0));
    }

    // HELPERS
    function getBrokerRebate(
        address broker
    )
        external
        view
        returns (uint256 currentBrokerRate, uint256 totalBrokerRebate)
    {
        uint256 fee = brokerFees[broker].itou();
        (currentBrokerRate, totalBrokerRebate) = RebateCalculator
            .calculateTotalBrokerRebate(fee);
    }

    function getRecruiterRebate(
        address recruiter
    )
        external
        view
        returns (uint256 currentRecruiterRate, uint256 totalRecruiterRebate)
    {
        uint256 fee = recruiterFees[recruiter].itou();
        (currentRecruiterRate, totalRecruiterRebate) = RebateCalculator
            .calculateTotalRecruiterRebate(fee);
    }
}

interface ICollector {
    function transferOut(address recepient, uint256 amount) external;
}