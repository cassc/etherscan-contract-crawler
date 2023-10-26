// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Address} from "openzeppelin/utils/Address.sol";

import {ProtocolEvents} from "./interfaces/ProtocolEvents.sol";
import {IPauserRead} from "./interfaces/IPauser.sol";
import {IOracleReadRecord, OracleRecord} from "./interfaces/IOracle.sol";
import {IStakingReturnsWrite} from "./interfaces/IStaking.sol";
import {IReturnsAggregatorWrite} from "./interfaces/IReturnsAggregator.sol";

import {ReturnsReceiver} from "./ReturnsReceiver.sol";

interface ReturnsAggregatorEvents {
    /// @notice Emitted when the protocol collects fees when processing rewards.
    /// @param amount The amount of fees collected.
    event FeesCollected(uint256 amount);
}

/// @title ReturnsAggregator
/// @notice Aggregator contract that aggregates returns from wallets the protocol controls, takes fees where applicable,
/// and forwards the net returns to the staking contract.
contract ReturnsAggregator is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ProtocolEvents,
    ReturnsAggregatorEvents,
    IReturnsAggregatorWrite
{
    error InvalidConfiguration();
    error NotOracle();
    error Paused();
    error ZeroAddress();

    /// @notice The manager role can set the fees receiver wallet and fees basis points.
    bytes32 public constant AGGREGATOR_MANAGER_ROLE = keccak256("AGGREGATOR_MANAGER_ROLE");

    /// @dev A basis point (often denoted as bp, 1bp = 0.01%) is a unit of measure used in finance to describe
    /// the percentage change in a financial instrument. This is a constant value set as 10000 which represents
    /// 100% in basis point terms.
    uint16 internal constant _BASIS_POINTS_DENOMINATOR = 10_000;

    /// @notice The staking contract to which the aggregated returns are forwarded after subtracting protocol fees.
    IStakingReturnsWrite public staking;

    /// @notice The oracle contract from which the returns information is read.
    IOracleReadRecord public oracle;

    /// @notice The contract receiving consensus layer returns, i.e. partial and full withdraws including rewards and
    /// principals.
    ReturnsReceiver public consensusLayerReceiver;

    /// @notice The contract receiving execution layer rewards, i.e. tips and MEV rewards.
    ReturnsReceiver public executionLayerReceiver;

    /// @notice The pauser contract.
    /// @dev Keeps the pause state across the protocol.
    IPauserRead public pauser;

    /// @notice The address receiving protocol fees.
    address payable public feesReceiver;

    /// @notice The protocol fees in basis points (1/10000).
    uint16 public feesBasisPoints;

    /// @notice Configuration for contract initialization.
    struct Init {
        address admin;
        address manager;
        IOracleReadRecord oracle;
        IPauserRead pauser;
        ReturnsReceiver consensusLayerReceiver;
        ReturnsReceiver executionLayerReceiver;
        IStakingReturnsWrite staking;
        address payable feesReceiver;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice Inititalizes the contract.
    /// @dev MUST be called during the contract upgrade to set up the proxies state.
    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        _grantRole(AGGREGATOR_MANAGER_ROLE, init.manager);

        oracle = init.oracle;
        pauser = init.pauser;
        consensusLayerReceiver = init.consensusLayerReceiver;
        executionLayerReceiver = init.executionLayerReceiver;
        staking = init.staking;
        feesReceiver = init.feesReceiver;
        // Default fees are 10%
        feesBasisPoints = 1_000;
    }

    /// @inheritdoc IReturnsAggregatorWrite
    /// @dev Calculates the amount of funds to be forwarded to the staking contract, takes the fees, and forwards them.
    /// Note that we also validate that the funds are forwarded to the staking contract and none are sent to this
    /// contract.
    function processReturns(uint256 rewardAmount, uint256 principalAmount, bool shouldIncludeELRewards)
        external
        assertBalanceUnchanged
    {
        if (msg.sender != address(oracle)) {
            revert NotOracle();
        }

        // Calculate the total amount of returns that will be aggregated.
        uint256 clTotal = rewardAmount + principalAmount;
        uint256 totalRewards = rewardAmount;

        uint256 elRewards = 0;
        if (shouldIncludeELRewards) {
            elRewards = address(executionLayerReceiver).balance;
            totalRewards += elRewards;
        }

        // Calculate protocol fees.
        uint256 fees = Math.mulDiv(feesBasisPoints, totalRewards, _BASIS_POINTS_DENOMINATOR);

        // Aggregate returns in this contract
        address payable self = payable(address(this));
        if (elRewards > 0) {
            executionLayerReceiver.transfer(self, elRewards);
        }
        if (clTotal > 0) {
            consensusLayerReceiver.transfer(self, clTotal);
        }

        // Forward the net returns (if they exist) to the staking contract.
        uint256 netReturns = clTotal + elRewards - fees;
        if (netReturns > 0) {
            staking.receiveReturns{value: netReturns}();
        }

        // Send protocol fees (if they exist) to the fee receiver wallet.
        if (fees > 0) {
            emit FeesCollected(fees);
            Address.sendValue(feesReceiver, fees);
        }
    }

    /// @notice Sets the fees receiver wallet for the protocol.
    /// @param newReceiver The new fees receiver wallet.
    function setFeesReceiver(address payable newReceiver)
        external
        onlyRole(AGGREGATOR_MANAGER_ROLE)
        notZeroAddress(newReceiver)
    {
        feesReceiver = newReceiver;
        emit ProtocolConfigChanged(this.setFeesReceiver.selector, "setFeesReceiver(address)", abi.encode(newReceiver));
    }

    /// @notice Sets the fees basis points.
    /// @param newBasisPoints The new fees basis points.
    function setFeeBasisPoints(uint16 newBasisPoints) external onlyRole(AGGREGATOR_MANAGER_ROLE) {
        if (newBasisPoints > _BASIS_POINTS_DENOMINATOR) {
            revert InvalidConfiguration();
        }

        feesBasisPoints = newBasisPoints;
        emit ProtocolConfigChanged(
            this.setFeeBasisPoints.selector, "setFeeBasisPoints(uint16)", abi.encode(newBasisPoints)
        );
    }

    receive() external payable {}

    /// @notice Ensures that the given address is not the zero address.
    /// @param addr The address to check.
    modifier notZeroAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @notice Ensures that the balance of the contract remains unchanged after the function returns.
    modifier assertBalanceUnchanged() {
        uint256 before = address(this).balance;
        _;
        assert(address(this).balance == before);
    }
}