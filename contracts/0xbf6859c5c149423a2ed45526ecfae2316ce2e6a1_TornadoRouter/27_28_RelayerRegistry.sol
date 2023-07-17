// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// OZ imports

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/Initializable.sol";

// Tornado imports

import { TORN } from "torn-token/contracts/TORN.sol";

// Local imports

import { IENS } from "./interfaces/IENS.sol";

import { ENSNamehash } from "./libraries/ENSNamehash.sol";

import { ENSResolver } from "./libraries/ENSResolver.sol";

import { TornadoStakingRewards } from "./TornadoStakingRewards.sol";

import { FeeOracleManager } from "./FeeOracleManager.sol";

contract RegistryLegacyStorage {
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LEGACY STORAGE, ABANDONED ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @dev From Initializable.sol of first contract
     */
    bool private _deprecatedInitialized;

    /**
     * @dev From Initializable.sol of first contract
     */
    bool private _deprecatedInitializing;

    /**
     * @dev This one will be moved for visibility
     */
    address private _deprecatedRouterAddress;

    /**
     * @dev We are not using this one because we will pull some magic
     */
    uint256 private _deprecatedMinStakeAmount;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LEGACY STORAGE, IN USE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice Relayer metadata: their (non-refundable) TORN balances and ENS node
     */
    mapping(address => RelayerMetadata) public metadata;

    /**
     * @notice Address ownership chain
     */
    mapping(address => address) public ownerOf;
}

struct RelayerMetadata {
    uint256 balance;
    bytes32 ensNode;
}

contract RelayerRegistry is RegistryLegacyStorage, ENSResolver, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ IMMUTABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice The address of the Governance proxy.
     */
    address public immutable governanceProxyAddress;

    /**
     * @notice The TORN token.
     */
    TORN public immutable torn;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ NEW STORAGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~ ACCESS ALLOWED CONTRACTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice This contract will have relayer funds forwarded to.
     */
    address public stakedTokensReceiver;

    /**
     * @notice This contract may deduct balances.
     */
    address public balanceDeductor;

    /**
     * @notice This contract may nullify balances.
     */
    address public balanceNullifier;

    /**
     * @notice This contract will be setting the minimumTornStake;
     */
    address public minimumStakeOracle;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ PARAMETERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice This is the minimum TORN stake necessary for relayers
     */
    uint256 public minimumTornStake;

    /**
     * @notice Just so we can avoid shenanigans where a relayer would like to register someone elses worker by
     * frontrunning txs, we will allow worker addrs to be reserved.
     */
    mapping(address => address) public reservedAccounts;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    // ENS
    event ENSUpdated(address ens);

    // Balances
    event BalanceDeductorUpdated(address balanceDeductor);
    event BalanceNullifierUpdated(address balanceNullifier);

    // Minimum TORN Stake
    event MinimumTornStakeUpdated(uint256 tornStake);
    event MinimumTornStakeOracleUpdated(address stakeOracle);

    // Relayer Metadata
    event RelayerRegistered(string ensName, bytes32 ensNode, address relayerAddress, uint256 stakedAmount);
    event RelayerBalanceNullified(address relayer);

    // Relayer Stake
    event StakeAddedToRelayer(address relayer, uint256 amountStakeAdded);
    event StakeDeducted(address relayer, uint256 amountBurned);
    event StakedTokensReceiverUpdated(address stakingRewards);

    // Relayers Workers
    event WorkerRegistered(address relayer, address worker);
    event WorkerUnregistered(address relayer, address worker);

    // Accounts
    event AccountReserved(address relayer, address worker);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LOGIC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    constructor(address _governanceProxyAddress, address _tornTokenAddress) public {
        governanceProxyAddress = _governanceProxyAddress;
        torn = TORN(_tornTokenAddress);
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceProxyAddress, "RelayerRegistry: only governance");
        _;
    }

    modifier onlyBalanceDeductor() {
        require(msg.sender == balanceDeductor, "RelayerRegistry: only relayer balance deductor");
        _;
    }

    modifier onlyBalanceNullifier() {
        require(msg.sender == balanceNullifier, "RelayerRegistry: only relayer balance nullifier");
        _;
    }

    modifier onlyMinimumStakeOracle() {
        require(msg.sender == minimumStakeOracle, "RelayerRegistry: only minimum torn stake oracle");
        _;
    }

    modifier onlyENSOwner(address _relayer, bytes32 _ensNode) {
        require(_relayer == ownerByNode(_ensNode), "RelayerRegistry: only ENS domain owner");
        _;
    }

    modifier onlyWorkerOf(address _possibleRelayer, address _possibleWorker) {
        require(isWorkerOf(_possibleRelayer, _possibleWorker), "RelayerRegistry: only owner of worker");
        _;
    }

    function version() public pure virtual returns (string memory) {
        return "v2-infrastructure-upgrade";
    }

    function initialize(
        address _balanceDeductor,
        address _balanceNullifier,
        address _stakedTokensReceiver,
        address _minimumStakeOracle,
        uint256 _minimumTornStake
    ) public virtual onlyGovernance initializer {
        balanceDeductor = _balanceDeductor;
        balanceNullifier = _balanceNullifier;
        minimumTornStake = _minimumTornStake;
        minimumStakeOracle = _minimumStakeOracle;
        stakedTokensReceiver = _stakedTokensReceiver;
    }

    function register(string calldata _ensName, uint256 _staked, address[] calldata _workers)
        public
        virtual
    {
        _register(_ensName, ENSNamehash.namehash(bytes(_ensName)), msg.sender, _staked, _workers);
    }

    function registerPermit(
        string calldata _ensName,
        uint256 _staked,
        address[] calldata _workers,
        address _relayer,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        torn.permit(_relayer, address(this), _staked, _deadline, v, r, s);
        _register(_ensName, ENSNamehash.namehash(bytes(_ensName)), _relayer, _staked, _workers);
    }

    /**
     * @dev Since the relayer is only going to be set once as its own owner, subsequent calls can't work.
     * Furthermore, `_workers` can only be workers and not relayers, and not the workers of some other
     * relayer, because of the checks inside of the internal call.
     */
    function _register(
        string memory _ensName,
        bytes32 _ensNode,
        address _relayer,
        uint256 _staked,
        address[] calldata _workers
    ) internal onlyENSOwner(_relayer, _ensNode) {
        // Relayer must be free or taken as a worker
        require(!isRelayer(_relayer), "RelayerRegistry: relayer is registered");

        // Check if a sufficient amount of TORN is to be staked
        require(minimumTornStake <= _staked, "RelayerRegistry: stake too low");

        // Then transfer it to the token receiver
        IERC20(torn).safeTransferFrom(_relayer, stakedTokensReceiver, _staked);

        // Then store metadata ("register"), can't be removed
        metadata[_relayer] = RelayerMetadata({ balance: _staked, ensNode: _ensNode });

        // iff ownerOf[_relayer] = _relayer, then relayer can't be set to different addr again
        ownerOf[_relayer] = _relayer;

        // Register all workers
        for (uint256 i = 0; i < _workers.length; i++) {
            _registerWorker(_relayer, _workers[i]);
        }

        // Log
        emit RelayerRegistered(_ensName, _ensNode, _relayer, _staked);
    }

    function registerWorker(address _relayer, address _worker)
        public
        virtual
        // `_relayer` must be working through a valid worker
        onlyWorkerOf(_relayer, msg.sender)
    {
        _registerWorker(_relayer, _worker);
    }

    function _registerWorker(address _relayer, address _worker) internal {
        // `_worker` must be a worker
        require(isWorker(_worker), "RelayerRegistry: worker is not a valid worker");

        // `_worker` must be free or reserved for the relayer
        require(
            (ownerOf[_worker] == address(0) && reservedAccounts[_worker] == address(0))
                || reservedAccounts[_worker] == _relayer,
            "RelayerRegistry: worker is owned"
        );

        // Only the `_relayer` can do this assignment
        ownerOf[_worker] = _relayer;

        // Log
        emit WorkerRegistered(_relayer, _worker);
    }

    function reserveAccount(address _account) public virtual {
        // Account can't be 0
        require(_account != address(0), "RelayerRegistry: account cant be 0");

        // Reserve
        reservedAccounts[msg.sender] = _account;

        // Log
        emit AccountReserved(_account, msg.sender);
    }

    function unregisterWorker(address _worker) public virtual {
        // It's either the worker or the relayer owning the worker
        require(
            msg.sender == _worker || isWorkerOf(msg.sender, _worker),
            "RelayerRegistry: sender must own worker"
        );

        // Worker must not be relayer
        require(isWorker(_worker), "RelayerRegistry: cant unregister relayer");

        // Unset
        delete ownerOf[_worker];

        // Log
        emit WorkerUnregistered(ownerOf[_worker], _worker);
    }

    function stakeToRelayer(address _relayer, uint256 _staked) public virtual {
        _addStake(msg.sender, _relayer, _staked);
    }

    function stakeToRelayerPermit(
        address _relayer,
        uint256 _staked,
        address _staker,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        torn.permit(_staker, address(this), _staked, _deadline, v, r, s);
        _addStake(_staker, _relayer, _staked);
    }

    function _addStake(address _staker, address _relayer, uint256 _staked)
        internal
        onlyWorkerOf(_relayer, _relayer)
    {
        IERC20(torn).safeTransferFrom(_staker, stakedTokensReceiver, _staked);
        metadata[_relayer].balance = _staked.add(metadata[_relayer].balance);
        emit StakeAddedToRelayer(_relayer, _staked);
    }

    function deductBalance(address _sender, address _relayer, uint256 _deducted)
        public
        virtual
        onlyBalanceDeductor
        onlyWorkerOf(_relayer, _sender)
    {
        metadata[_relayer].balance = metadata[_relayer].balance.sub(_deducted);
        emit StakeDeducted(_relayer, _deducted);
    }

    function nullifyBalance(address _account) public virtual onlyBalanceNullifier {
        address relayer = ownerOf[_account];
        metadata[relayer].balance = 0;
        emit RelayerBalanceNullified(relayer);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function setMinimumTornStake(uint256 _newMinimumTornStake) public virtual onlyMinimumStakeOracle {
        minimumTornStake = _newMinimumTornStake;
        emit MinimumTornStakeUpdated(_newMinimumTornStake);
    }

    function setMinimumStakeOracle(address _newMinimumStakeOracle) public virtual onlyGovernance {
        minimumStakeOracle = _newMinimumStakeOracle;
        emit MinimumTornStakeOracleUpdated(_newMinimumStakeOracle);
    }

    function setBalanceDeductor(address _newBalanceDeductor) public virtual onlyGovernance {
        balanceDeductor = _newBalanceDeductor;
        emit BalanceDeductorUpdated(_newBalanceDeductor);
    }

    function setBalanceNullifier(address _newBalanceNullifier) public virtual onlyGovernance {
        balanceNullifier = _newBalanceNullifier;
        emit BalanceNullifierUpdated(_newBalanceNullifier);
    }

    function setStakedTokensReceiver(address _newStakedTokensReceiver) public virtual onlyGovernance {
        stakedTokensReceiver = _newStakedTokensReceiver;
        emit StakedTokensReceiverUpdated(_newStakedTokensReceiver);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function isRegistered(address _account) public view virtual returns (bool) {
        return ownerOf[_account] != address(0);
    }

    function isRelayer(address _possibleRelayer) public view virtual returns (bool) {
        if (_possibleRelayer == address(0)) {
            return false;
        }
        return _possibleRelayer == ownerOf[_possibleRelayer];
    }

    function isWorker(address _possibleWorker) public view virtual returns (bool) {
        if (_possibleWorker == address(0)) {
            return false;
        }
        return _possibleWorker != ownerOf[_possibleWorker];
    }

    function isWorkerOf(address _possibleOwner, address _possibleWorker) public view virtual returns (bool) {
        if (_possibleOwner == address(0) || _possibleWorker == address(0)) {
            return false;
        }
        return _possibleOwner == ownerOf[_possibleWorker];
    }

    function getRelayerBalance(address _worker) public view virtual returns (uint256) {
        return metadata[ownerOf[_worker]].balance;
    }

    function getRelayerENSNode(address _worker) public view virtual returns (bytes32) {
        return metadata[ownerOf[_worker]].ensNode;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ENS GETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function isRegisteredByENSName(string memory _possibleRegisteredENSName)
        public
        view
        virtual
        returns (bool)
    {
        return isRegistered(ownerByName(_possibleRegisteredENSName));
    }

    function isRelayerByENSName(string memory _possibleRelayerENSName) public view virtual returns (bool) {
        return isRelayer(ownerByName(_possibleRelayerENSName));
    }

    function isWorkerByENSName(string memory _possibleWorkerENSName) public view virtual returns (bool) {
        return isWorker(ownerByName(_possibleWorkerENSName));
    }

    function isWorkerOfByENSName(string memory _possibleOwnerENSName, address _possibleWorker)
        public
        view
        virtual
        returns (bool)
    {
        return isWorkerOf(ownerByName(_possibleOwnerENSName), _possibleWorker);
    }

    function getRelayerBalanceByENSName(string memory _ensName) public view virtual returns (uint256) {
        return metadata[ownerByName(_ensName)].balance;
    }

    function getRelayerENSNodeByENSName(string memory _ensName) public pure virtual returns (bytes32) {
        return ENSNamehash.namehash(bytes(_ensName));
    }
}