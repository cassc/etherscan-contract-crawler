// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/Initializable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { EnsResolve } from "torn-token/contracts/ENS.sol";
import { ENSNamehash } from "./utils/ENSNamehash.sol";
import { TORN } from "torn-token/contracts/TORN.sol";
import { TornadoStakingRewards } from "./staking/TornadoStakingRewards.sol";
import { IENS } from "./interfaces/IENS.sol";

import "./tornado-proxy/TornadoRouter.sol";
import "./tornado-proxy/FeeManager.sol";

struct RelayerState {
  uint256 balance;
  bytes32 ensHash;
}

/**
 * @notice Registry contract, one of the main contracts of this protocol upgrade.
 *         The contract should store relayers' addresses and data attributed to the
 *         master address of the relayer. This data includes the relayers stake and
 *         his ensHash.
 *         A relayers master address has a number of subaddresses called "workers",
 *         these are all addresses which burn stake in communication with the proxy.
 *         If a relayer is not registered, he is not displayed on the frontend.
 * @dev CONTRACT RISKS:
 *      - if setter functions are compromised, relayer metadata would be at risk, including the noted amount of his balance
 *      - if burn function is compromised, relayers run the risk of being unable to handle withdrawals
 *      - the above risk also applies to the nullify balance function
 * */
contract RelayerRegistry is Initializable, EnsResolve {
  using SafeMath for uint256;
  using SafeERC20 for TORN;
  using ENSNamehash for bytes;

  TORN public immutable torn;
  address public immutable governance;
  IENS public immutable ens;
  TornadoStakingRewards public immutable staking;
  FeeManager public immutable feeManager;

  address public tornadoRouter;
  uint256 public minStakeAmount;

  mapping(address => RelayerState) public relayers;
  mapping(address => address) public workers;

  event RelayerBalanceNullified(address relayer);
  event WorkerRegistered(address relayer, address worker);
  event WorkerUnregistered(address relayer, address worker);
  event StakeAddedToRelayer(address relayer, uint256 amountStakeAdded);
  event StakeBurned(address relayer, uint256 amountBurned);
  event MinimumStakeAmount(uint256 minStakeAmount);
  event RouterRegistered(address tornadoRouter);
  event RelayerRegistered(bytes32 relayer, string ensName, address relayerAddress, uint256 stakedAmount);

  modifier onlyGovernance() {
    require(msg.sender == governance, "only governance");
    _;
  }

  modifier onlyTornadoRouter() {
    require(msg.sender == tornadoRouter, "only proxy");
    _;
  }

  modifier onlyRelayer(address sender, address relayer) {
    require(workers[sender] == relayer, "only relayer");
    _;
  }

  constructor(
    address _torn,
    address _governance,
    address _ens,
    bytes32 _staking,
    bytes32 _feeManager
  ) public {
    torn = TORN(_torn);
    governance = _governance;
    ens = IENS(_ens);
    staking = TornadoStakingRewards(resolve(_staking));
    feeManager = FeeManager(resolve(_feeManager));
  }

  /**
   * @notice initialize function for upgradeability
   * @dev this contract will be deployed behind a proxy and should not assign values at logic address,
   *      params left out because self explainable
   * */
  function initialize(bytes32 _tornadoRouter) external initializer {
    tornadoRouter = resolve(_tornadoRouter);
  }

  /**
   * @notice This function should register a master address and optionally a set of workeres for a relayer + metadata
   * @dev Relayer can't steal other relayers workers since they are registered, and a wallet (msg.sender check) can always unregister itself
   * @param ensName ens name of the relayer
   * @param stake the initial amount of stake in TORN the relayer is depositing
   * */
  function register(
    string calldata ensName,
    uint256 stake,
    address[] calldata workersToRegister
  ) external {
    _register(msg.sender, ensName, stake, workersToRegister);
  }

  /**
   * @dev Register function equivalent with permit-approval instead of regular approve.
   * */
  function registerPermit(
    string calldata ensName,
    uint256 stake,
    address[] calldata workersToRegister,
    address relayer,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    torn.permit(relayer, address(this), stake, deadline, v, r, s);
    _register(relayer, ensName, stake, workersToRegister);
  }

  function _register(
    address relayer,
    string calldata ensName,
    uint256 stake,
    address[] calldata workersToRegister
  ) internal {
    bytes32 ensHash = bytes(ensName).namehash();
    require(relayer == ens.owner(ensHash), "only ens owner");
    require(workers[relayer] == address(0), "cant register again");
    RelayerState storage metadata = relayers[relayer];

    require(metadata.ensHash == bytes32(0), "registered already");
    require(stake >= minStakeAmount, "!min_stake");

    torn.safeTransferFrom(relayer, address(staking), stake);
    emit StakeAddedToRelayer(relayer, stake);

    metadata.balance = stake;
    metadata.ensHash = ensHash;
    workers[relayer] = relayer;

    for (uint256 i = 0; i < workersToRegister.length; i++) {
      address worker = workersToRegister[i];
      _registerWorker(relayer, worker);
    }

    emit RelayerRegistered(ensHash, ensName, relayer, stake);
  }

  /**
   * @notice This function should allow relayers to register more workeres
   * @param relayer Relayer which should send message from any worker which is already registered
   * @param worker Address to register
   * */
  function registerWorker(address relayer, address worker) external onlyRelayer(msg.sender, relayer) {
    _registerWorker(relayer, worker);
  }

  function _registerWorker(address relayer, address worker) internal {
    require(workers[worker] == address(0), "can't steal an address");
    workers[worker] = relayer;
    emit WorkerRegistered(relayer, worker);
  }

  /**
   * @notice This function should allow anybody to unregister an address they own
   * @dev designed this way as to allow someone to unregister themselves in case a relayer misbehaves
   *      - this should be followed by an action like burning relayer stake
   *      - there was an option of allowing the sender to burn relayer stake in case of malicious behaviour, this feature was not included in the end
   *      - reverts if trying to unregister master, otherwise contract would break. in general, there should be no reason to unregister master at all
   * */
  function unregisterWorker(address worker) external {
    if (worker != msg.sender) require(workers[worker] == msg.sender, "only owner of worker");
    require(workers[worker] != worker, "cant unregister master");
    emit WorkerUnregistered(workers[worker], worker);
    workers[worker] = address(0);
  }

  /**
   * @notice This function should allow anybody to stake to a relayer more TORN
   * @param relayer Relayer main address to stake to
   * @param stake Stake to be added to relayer
   * */
  function stakeToRelayer(address relayer, uint256 stake) external {
    _stakeToRelayer(msg.sender, relayer, stake);
  }

  /**
   * @dev stakeToRelayer function equivalent with permit-approval instead of regular approve.
   * @param staker address from that stake is paid
   * */
  function stakeToRelayerPermit(
    address relayer,
    uint256 stake,
    address staker,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    torn.permit(staker, address(this), stake, deadline, v, r, s);
    _stakeToRelayer(staker, relayer, stake);
  }

  function _stakeToRelayer(
    address staker,
    address relayer,
    uint256 stake
  ) internal {
    require(workers[relayer] == relayer, "!registered");
    torn.safeTransferFrom(staker, address(staking), stake);
    relayers[relayer].balance = stake.add(relayers[relayer].balance);
    emit StakeAddedToRelayer(relayer, stake);
  }

  /**
   * @notice This function should burn some relayer stake on withdraw and notify staking of this
   * @dev IMPORTANT FUNCTION:
   *      - This should be only called by the tornado proxy
   *      - Should revert if relayer does not call proxy from valid worker
   *      - Should not overflow
   *      - Should underflow and revert (SafeMath) on not enough stake (balance)
   * @param sender worker to check sender == relayer
   * @param relayer address of relayer who's stake is being burned
   * @param pool instance to get fee for
   * */
  function burn(
    address sender,
    address relayer,
    ITornadoInstance pool
  ) external onlyTornadoRouter {
    address masterAddress = workers[sender];
    if (masterAddress == address(0)) {
      require(workers[relayer] == address(0), "Only custom relayer");
      return;
    }

    require(masterAddress == relayer, "only relayer");
    uint256 toBurn = feeManager.instanceFeeWithUpdate(pool);
    relayers[relayer].balance = relayers[relayer].balance.sub(toBurn);
    staking.addBurnRewards(toBurn);
    emit StakeBurned(relayer, toBurn);
  }

  /**
   * @notice This function should allow governance to set the minimum stake amount
   * @param minAmount new minimum stake amount
   * */
  function setMinStakeAmount(uint256 minAmount) external onlyGovernance {
    minStakeAmount = minAmount;
    emit MinimumStakeAmount(minAmount);
  }

  /**
   * @notice This function should allow governance to set a new tornado proxy address
   * @param tornadoRouterAddress address of the new proxy
   * */
  function setTornadoRouter(address tornadoRouterAddress) external onlyGovernance {
    tornadoRouter = tornadoRouterAddress;
    emit RouterRegistered(tornadoRouterAddress);
  }

  /**
   * @notice This function should allow governance to nullify a relayers balance
   * @dev IMPORTANT FUNCTION:
   *      - Should nullify the balance
   *      - Adding nullified balance as rewards was refactored to allow for the flexibility of these funds (for gov to operate with them)
   * @param relayer address of relayer who's balance is to nullify
   * */
  function nullifyBalance(address relayer) external onlyGovernance {
    address masterAddress = workers[relayer];
    require(relayer == masterAddress, "must be master");
    relayers[masterAddress].balance = 0;
    emit RelayerBalanceNullified(relayer);
  }

  /**
   * @notice This function should check if a worker is associated with a relayer
   * @param toResolve address to check
   * @return true if is associated
   * */
  function isRelayer(address toResolve) external view returns (bool) {
    return workers[toResolve] != address(0);
  }

  /**
   * @notice This function should check if a worker is registered to the relayer stated
   * @param relayer relayer to check
   * @param toResolve address to check
   * @return true if registered
   * */
  function isRelayerRegistered(address relayer, address toResolve) external view returns (bool) {
    return workers[toResolve] == relayer;
  }

  /**
   * @notice This function should get a relayers ensHash
   * @param relayer address to fetch for
   * @return relayer's ensHash
   * */
  function getRelayerEnsHash(address relayer) external view returns (bytes32) {
    return relayers[workers[relayer]].ensHash;
  }

  /**
   * @notice This function should get a relayers balance
   * @param relayer relayer who's balance is to fetch
   * @return relayer's balance
   * */
  function getRelayerBalance(address relayer) external view returns (uint256) {
    return relayers[workers[relayer]].balance;
  }
}