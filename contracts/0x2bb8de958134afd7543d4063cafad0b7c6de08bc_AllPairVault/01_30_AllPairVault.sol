// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/OndoRegistryClient.sol";
import "contracts/TrancheToken.sol";
import "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/interfaces/IPairVault.sol";
import "contracts/interfaces/IFeeCollector.sol";

/**
 * @title A container for all Vaults
 * @notice Vaults are created and managed here
 * @dev Because Ethereum transactions are so expensive,
 * we reinvent an OO system in this code. There are 4 primary
 * functions:
 *
 * deposit, withdraw: investors can add remove funds into a
 *     particular tranche in a Vault.
 * invest, redeem: a strategist pushes the Vault to buy/sell LP tokens in
 *     an underlying AMM
 */
contract AllPairVault is OndoRegistryClient, IPairVault {
  using OLib for OLib.Investor;
  using SafeERC20 for IERC20;
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;

  // A Vault object is parameterized by these values.
  struct Vault {
    mapping(OLib.Tranche => Asset) assets; // Assets corresponding to each tranche
    IStrategy strategy; // Shared contract that interacts with AMMs
    address creator; // Account that calls createVault
    address strategist; // Has the right to call invest() and redeem(), and harvest() if strategy supports it
    address rollover; // Manager of investment auto-rollover, if any
    uint256 rolloverId;
    uint256 hurdleRate; // Return offered to senior tranche
    OLib.State state; // Current state of Vault
    uint256 startAt; // Time when the Vault is unpaused to begin accepting deposits
    uint256 investAt; // Time when investors can't move funds, strategist can invest
    uint256 redeemAt; // Time when strategist can redeem LP tokens, investors can withdraw
    uint256 performanceFee; // Optional fee on junior tranche goes to strategist
  }

  // (TrancheToken address => (investor address => OLib.Investor)
  mapping(address => mapping(address => OLib.Investor)) investors;

  // An instance of TrancheToken from which all other tokens are cloned
  address public immutable trancheTokenImpl;

  // Address that collects performance fees
  IFeeCollector public performanceFeeCollector;

  // Locate Vault by hashing metadata about the product
  mapping(uint256 => Vault) private Vaults;

  // Locate Vault by starting from the TrancheToken address
  mapping(address => uint256) public VaultsByTokens;

  // All Vault IDs
  EnumerableSet.UintSet private vaultIDs;

  // Access restriction to registered strategist
  modifier onlyStrategist(uint256 _vaultId) {
    require(msg.sender == Vaults[_vaultId].strategist, "Invalid caller");
    _;
  }

  // Access restriction to registered rollover
  modifier onlyRollover(uint256 _vaultId, uint256 _rolloverId) {
    Vault storage vault_ = Vaults[_vaultId];
    require(
      msg.sender == vault_.rollover && _rolloverId == vault_.rolloverId,
      "Invalid caller"
    );
    _;
  }

  // Access is only rollover if rollover addr nonzero, else strategist
  modifier onlyRolloverOrStrategist(uint256 _vaultId) {
    Vault storage vault_ = Vaults[_vaultId];
    address rollover = vault_.rollover;
    require(
      (rollover == address(0) && msg.sender == vault_.strategist) ||
        (msg.sender == rollover),
      "Invalid caller"
    );
    _;
  }

  // Guard functions with state machine
  modifier atState(uint256 _vaultId, OLib.State _state) {
    require(getState(_vaultId) == _state, "Invalid operation");
    _;
  }

  // Determine if one can move to a new state. For now the transitions
  // are strictly linear. No state machines, really.
  function transition(uint256 _vaultId, OLib.State _nextState) private {
    Vault storage vault_ = Vaults[_vaultId];
    OLib.State curState = vault_.state;
    if (_nextState == OLib.State.Live) {
      require(curState == OLib.State.Deposit, "Invalid operation");
      require(vault_.investAt <= block.timestamp, "Not time yet");
    } else {
      require(
        curState == OLib.State.Live && _nextState == OLib.State.Withdraw,
        "Invalid operation"
      );
      require(vault_.redeemAt <= block.timestamp, "Not time yet");
    }
    vault_.state = _nextState;
  }

  // Determine if a Vault can shift to an open state. A Vault is started
  // in an inactive state. It can only move forward when time has
  // moved past the starttime.
  function maybeOpenDeposit(uint256 _vaultId) private {
    Vault storage vault_ = Vaults[_vaultId];
    if (vault_.state == OLib.State.Inactive) {
      require(
        vault_.startAt > 0 && vault_.startAt <= block.timestamp,
        "Not time yet"
      );
      vault_.state = OLib.State.Deposit;
    } else if (vault_.state != OLib.State.Deposit) {
      revert("Invalid operation");
    }
  }

  // modifier onlyETH(uint256 _vaultId, OLib.Tranche _tranche) {
  //   require(
  //     address((getVaultById(_vaultId)).assets[uint256(_tranche)].token) ==
  //       address(registry.weth()),
  //     "Not an ETH vault"
  //   );
  //   _;
  // }

  function onlyETH(uint256 _vaultId, OLib.Tranche _tranche) private view {
    require(
      address((getVaultById(_vaultId)).assets[uint256(_tranche)].token) ==
        address(registry.weth()),
      "Not an ETH vault"
    );
  }

  /**
   * Event declarations
   */
  event CreatedPair(
    uint256 indexed vaultId,
    IERC20 indexed seniorAsset,
    IERC20 indexed juniorAsset,
    ITrancheToken seniorToken,
    ITrancheToken juniorToken
  );

  event SetRollover(
    address indexed rollover,
    uint256 indexed rolloverId,
    uint256 indexed vaultId
  );

  event Deposited(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 indexed trancheId,
    uint256 amount
  );

  event Invested(
    uint256 indexed vaultId,
    uint256 seniorAmount,
    uint256 juniorAmount
  );

  event DepositedLP(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 amount,
    uint256 senior,
    uint256 junior
  );

  event RolloverDeposited(
    address indexed rollover,
    uint256 indexed rolloverId,
    uint256 indexed vaultId,
    uint256 seniorAmount,
    uint256 juniorAmount
  );

  event Claimed(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 indexed trancheId,
    uint256 shares,
    uint256 excess
  );

  event RolloverClaimed(
    address indexed rollover,
    uint256 indexed rolloverId,
    uint256 indexed vaultId,
    uint256 seniorAmount,
    uint256 juniorAmount
  );

  event Redeemed(
    uint256 indexed vaultId,
    uint256 seniorReceived,
    uint256 juniorReceived
  );

  event Withdrew(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 indexed trancheId,
    uint256 amount
  );

  event WithdrewLP(address indexed depositor, uint256 amount);

  // event PerformanceFeeSet(uint256 indexed vaultId, uint256 fee);

  // event PerformanceFeeCollectorSet(address indexed collector);

  /**
   * @notice Container points back to registry
   * @dev Hook up this contract to the global registry.
   */
  constructor(address _registry, address _trancheTokenImpl)
    OndoRegistryClient(_registry)
  {
    require(_trancheTokenImpl != address(0), "Invalid target");
    trancheTokenImpl = _trancheTokenImpl;
  }

  /**
   * @notice Initialize parameters for a Vault
   * @dev
   * @param _params Struct with all initialization info
   * @return vaultId hashed identifier of Vault used everywhere
   **/
  function createVault(OLib.VaultParams calldata _params)
    external
    override
    whenNotPaused
    isAuthorized(OLib.CREATOR_ROLE)
    nonReentrant
    returns (uint256 vaultId)
  {
    require(
      registry.authorized(OLib.STRATEGY_ROLE, _params.strategy),
      "Invalid target"
    );
    require(
      registry.authorized(OLib.STRATEGIST_ROLE, _params.strategist),
      "Invalid target"
    );
    require(_params.startTime >= block.timestamp, "Invalid start time");
    require(
      _params.enrollment > 0 && _params.duration > 0,
      "No zero intervals"
    );
    require(_params.hurdleRate < 1e8, "Maximum hurdle is 10000%");
    require(denominator <= _params.hurdleRate, "Min hurdle is 100%");

    require(
      _params.seniorAsset != address(0) &&
        _params.seniorAsset != address(this) &&
        _params.juniorAsset != address(0) &&
        _params.juniorAsset != address(this),
      "Invalid target"
    );
    uint256 investAtTime = _params.startTime + _params.enrollment;
    uint256 redeemAtTime = investAtTime + _params.duration;
    TrancheToken seniorITrancheToken;
    TrancheToken juniorITrancheToken;
    {
      vaultId = uint256(
        keccak256(
          abi.encode(
            _params.seniorAsset,
            _params.juniorAsset,
            _params.strategy,
            _params.hurdleRate,
            _params.startTime,
            investAtTime,
            redeemAtTime
          )
        )
      );
      vaultIDs.add(vaultId);
      Vault storage vault_ = Vaults[vaultId];
      require(address(vault_.strategist) == address(0), "Duplicate");
      vault_.strategy = IStrategy(_params.strategy);
      vault_.creator = msg.sender;
      vault_.strategist = _params.strategist;
      vault_.hurdleRate = _params.hurdleRate;
      vault_.startAt = _params.startTime;
      vault_.investAt = investAtTime;
      vault_.redeemAt = redeemAtTime;

      registry.recycleDeadTokens(2);

      seniorITrancheToken = TrancheToken(
        Clones.cloneDeterministic(
          trancheTokenImpl,
          keccak256(abi.encodePacked(uint256(0), vaultId))
        )
      );
      juniorITrancheToken = TrancheToken(
        Clones.cloneDeterministic(
          trancheTokenImpl,
          keccak256(abi.encodePacked(uint256(1), vaultId))
        )
      );
      vault_.assets[OLib.Tranche.Senior].token = IERC20(_params.seniorAsset);
      vault_.assets[OLib.Tranche.Junior].token = IERC20(_params.juniorAsset);
      vault_.assets[OLib.Tranche.Senior].trancheToken = seniorITrancheToken;
      vault_.assets[OLib.Tranche.Junior].trancheToken = juniorITrancheToken;

      vault_.assets[OLib.Tranche.Senior].trancheCap = _params.seniorTrancheCap;
      vault_.assets[OLib.Tranche.Senior].userCap = _params.seniorUserCap;
      vault_.assets[OLib.Tranche.Junior].trancheCap = _params.juniorTrancheCap;
      vault_.assets[OLib.Tranche.Junior].userCap = _params.juniorUserCap;

      VaultsByTokens[address(seniorITrancheToken)] = vaultId;
      VaultsByTokens[address(juniorITrancheToken)] = vaultId;
      if (vault_.startAt == block.timestamp) {
        vault_.state = OLib.State.Deposit;
      }

      IStrategy(_params.strategy).addVault(
        vaultId,
        IERC20(_params.seniorAsset),
        IERC20(_params.juniorAsset)
      );

      seniorITrancheToken.initialize(
        vaultId,
        _params.seniorName,
        _params.seniorSym,
        address(this)
      );
      juniorITrancheToken.initialize(
        vaultId,
        _params.juniorName,
        _params.juniorSym,
        address(this)
      );
    }

    emit CreatedPair(
      vaultId,
      IERC20(_params.seniorAsset),
      IERC20(_params.juniorAsset),
      seniorITrancheToken,
      juniorITrancheToken
    );
  }

  /**
   * @notice Set the rollover details for a Vault
   * @dev
   * @param _vaultId Vault to update
   * @param _rollover Account of approved rollover agent
   * @param _rolloverId Rollover fund in RolloverVault
   */
  function setRollover(
    uint256 _vaultId,
    address _rollover,
    uint256 _rolloverId
  ) external override isAuthorized(OLib.ROLLOVER_ROLE) {
    Vault storage vault_ = Vaults[_vaultId];
    if (vault_.rollover != address(0)) {
      require(
        msg.sender == vault_.rollover && _rolloverId == vault_.rolloverId,
        "Invalid caller"
      );
    }
    vault_.rollover = _rollover;
    vault_.rolloverId = _rolloverId;
    emit SetRollover(_rollover, _rolloverId, _vaultId);
  }

  /** @dev Enforce cap on user investment if any
   */
  function depositCapGuard(uint256 _allowedAmount, uint256 _amount)
    internal
    pure
  {
    require(
      _allowedAmount == 0 || _amount <= _allowedAmount,
      "Exceeds user cap"
    );
  }

  /**
   * @notice Deposit funds into specific tranche of specific Vault
   * @dev OLib.Tranche balances are maintained by a unique ERC20 contract
   * @param _vaultId Specific ID for this Vault
   * @param _tranche Tranche to be deposited in
   * @param _amount Amount of tranche asset to transfer to the strategy contract
   */
  function _deposit(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    uint256 _amount,
    address _payer
  ) internal whenNotPaused {
    maybeOpenDeposit(_vaultId);
    Vault storage vault_ = Vaults[_vaultId];
    vault_.assets[_tranche].token.safeTransferFrom(
      _payer,
      address(vault_.strategy),
      _amount
    );
    uint256 _total = vault_.assets[_tranche].deposited += _amount;
    OLib.Investor storage _investor =
      investors[address(vault_.assets[_tranche].trancheToken)][msg.sender];
    uint256 userSum =
      _investor.userSums.length > 0
        ? _investor.userSums[_investor.userSums.length - 1] + _amount
        : _amount;
    depositCapGuard(vault_.assets[_tranche].userCap, userSum);
    _investor.prefixSums.push(_total);
    _investor.userSums.push(userSum);
    emit Deposited(msg.sender, _vaultId, uint256(_tranche), _amount);
  }

  function deposit(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    uint256 _amount
  ) external override nonReentrant {
    _deposit(_vaultId, _tranche, _amount, msg.sender);
  }

  function depositETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    payable
    override
    nonReentrant
  {
    onlyETH(_vaultId, _tranche);
    registry.weth().deposit{value: msg.value}();
    _deposit(_vaultId, _tranche, msg.value, address(this));
  }

  /**
   * @notice Called by rollover to deposit funds
   * @dev Rollover gets priority over other depositors.
   * @param _vaultId Vault to work on
   * @param _rolloverId Rollover that is depositing funds
   * @param _seniorAmount Total available amount of assets
   * @param _juniorAmount Total available amount of assets
   */
  function depositFromRollover(
    uint256 _vaultId,
    uint256 _rolloverId,
    uint256 _seniorAmount,
    uint256 _juniorAmount
  )
    external
    override
    onlyRollover(_vaultId, _rolloverId)
    whenNotPaused
    nonReentrant
  {
    maybeOpenDeposit(_vaultId);
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    senior_.deposited += _seniorAmount;
    junior_.deposited += _juniorAmount;
    senior_.rolloverDeposited += _seniorAmount;
    junior_.rolloverDeposited += _juniorAmount;
    senior_.token.safeTransferFrom(
      msg.sender,
      address(vault_.strategy),
      _seniorAmount
    );
    junior_.token.safeTransferFrom(
      msg.sender,
      address(vault_.strategy),
      _juniorAmount
    );
    emit RolloverDeposited(
      msg.sender,
      _rolloverId,
      _vaultId,
      _seniorAmount,
      _juniorAmount
    );
  }

  /**
   * @notice Deposit more LP tokens into a Vault that is live
   * @dev When a Vault is created it establishes a ratio between
   *      senior/junior tranche tokens per LP token. If LP tokens are added
   *      while the Vault is running, it will get the same ratio of tranche
   *      tokens in return, regardless of the current balance in the pool.
   * @param _vaultId  reference to Vault
   * @param _lpTokens Amount of LP tokens to provide
   */
  function depositLp(uint256 _vaultId, uint256 _lpTokens)
    external
    override
    whenNotPaused
    nonReentrant
    atState(_vaultId, OLib.State.Live)
    returns (uint256 seniorTokensOwed, uint256 juniorTokensOwed)
  {
    require(registry.tokenMinting(), "Vault tokens inactive");
    Vault storage vault_ = Vaults[_vaultId];
    IERC20 pool;
    (seniorTokensOwed, juniorTokensOwed, pool) = getDepositLp(
      _vaultId,
      _lpTokens
    );

    depositCapGuard(
      vault_.assets[OLib.Tranche.Senior].userCap,
      seniorTokensOwed
    );
    depositCapGuard(
      vault_.assets[OLib.Tranche.Junior].userCap,
      juniorTokensOwed
    );

    vault_.assets[OLib.Tranche.Senior].totalInvested += seniorTokensOwed;
    vault_.assets[OLib.Tranche.Junior].totalInvested += juniorTokensOwed;
    vault_.assets[OLib.Tranche.Senior].trancheToken.mint(
      msg.sender,
      seniorTokensOwed
    );
    vault_.assets[OLib.Tranche.Junior].trancheToken.mint(
      msg.sender,
      juniorTokensOwed
    );

    pool.safeTransferFrom(msg.sender, address(vault_.strategy), _lpTokens);
    vault_.strategy.addLp(_vaultId, _lpTokens);
    emit DepositedLP(
      msg.sender,
      _vaultId,
      _lpTokens,
      seniorTokensOwed,
      juniorTokensOwed
    );
  }

  function getDepositLp(uint256 _vaultId, uint256 _lpTokens)
    public
    view
    atState(_vaultId, OLib.State.Live)
    returns (
      uint256 seniorTokensOwed,
      uint256 juniorTokensOwed,
      IERC20 pool
    )
  {
    Vault storage vault_ = Vaults[_vaultId];
    (uint256 shares, uint256 vaultShares, IERC20 ammPool) =
      vault_.strategy.sharesFromLp(_vaultId, _lpTokens);
    seniorTokensOwed =
      (vault_.assets[OLib.Tranche.Senior].totalInvested * shares) /
      vaultShares;
    juniorTokensOwed =
      (vault_.assets[OLib.Tranche.Junior].totalInvested * shares) /
      vaultShares;
    pool = ammPool;
  }

  /**
   * @notice Invest funds into AMM
   * @dev Push deposited funds into underlying strategy contract
   * @param _vaultId Specific id for this Vault
   * @param _seniorMinIn To ensure you get a decent price
   * @param _juniorMinIn Same. Passed to addLiquidity on AMM
   *
   */
  function invest(
    uint256 _vaultId,
    uint256 _seniorMinIn,
    uint256 _juniorMinIn
  )
    external
    override
    whenNotPaused
    nonReentrant
    onlyRolloverOrStrategist(_vaultId)
    returns (uint256, uint256)
  {
    transition(_vaultId, OLib.State.Live);
    Vault storage vault_ = Vaults[_vaultId];
    investIntoStrategy(vault_, _vaultId, _seniorMinIn, _juniorMinIn);
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    senior_.totalInvested = vault_.assets[OLib.Tranche.Senior].originalInvested;
    junior_.totalInvested = vault_.assets[OLib.Tranche.Junior].originalInvested;
    emit Invested(_vaultId, senior_.totalInvested, junior_.totalInvested);
    return (senior_.totalInvested, junior_.totalInvested);
  }

  /*
   * @dev Separate investable amount calculation and strategy call from storage updates
   to keep the stack down.
   */
  function investIntoStrategy(
    Vault storage vault_,
    uint256 _vaultId,
    uint256 _seniorMinIn,
    uint256 _juniorMinIn
  ) private {
    uint256 seniorInvestableAmount =
      vault_.assets[OLib.Tranche.Senior].deposited;
    uint256 seniorCappedAmount = seniorInvestableAmount;
    if (vault_.assets[OLib.Tranche.Senior].trancheCap > 0) {
      seniorCappedAmount = min(
        seniorInvestableAmount,
        vault_.assets[OLib.Tranche.Senior].trancheCap
      );
    }
    uint256 juniorInvestableAmount =
      vault_.assets[OLib.Tranche.Junior].deposited;
    uint256 juniorCappedAmount = juniorInvestableAmount;
    if (vault_.assets[OLib.Tranche.Junior].trancheCap > 0) {
      juniorCappedAmount = min(
        juniorInvestableAmount,
        vault_.assets[OLib.Tranche.Junior].trancheCap
      );
    }

    (
      vault_.assets[OLib.Tranche.Senior].originalInvested,
      vault_.assets[OLib.Tranche.Junior].originalInvested
    ) = vault_.strategy.invest(
      _vaultId,
      seniorCappedAmount,
      juniorCappedAmount,
      seniorInvestableAmount - seniorCappedAmount,
      juniorInvestableAmount - juniorCappedAmount,
      _seniorMinIn,
      _juniorMinIn
    );
  }

  /**
   * @notice Return undeposited funds and trigger minting in Tranche Token
   * @dev Because the tranches must be balanced to buy LP tokens at
   *      the right ratio, it is likely that some deposits will not be
   *      accepted. This function transfers that "excess" deposit. Also, it
   *      finally mints the tranche tokens for this customer.
   * @param _vaultId  Reference to specific Vault
   * @param _tranche which tranche to act on
   * @return userInvested Total amount actually invested from this tranche
   * @return excess Any uninvested funds
   */
  function _claim(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    address _receiver
  )
    internal
    whenNotPaused
    atState(_vaultId, OLib.State.Live)
    returns (uint256 userInvested, uint256 excess)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage _asset = vault_.assets[_tranche];
    ITrancheToken _trancheToken = _asset.trancheToken;
    OLib.Investor storage investor =
      investors[address(_trancheToken)][msg.sender];
    require(!investor.claimed, "Already claimed");
    IStrategy _strategy = vault_.strategy;
    (userInvested, excess) = investor.getInvestedAndExcess(
      _getNetOriginalInvested(_asset)
    );
    if (excess > 0)
      _strategy.withdrawExcess(_vaultId, _tranche, _receiver, excess);
    if (registry.tokenMinting()) {
      _trancheToken.mint(msg.sender, userInvested);
    }

    investor.claimed = true;
    emit Claimed(msg.sender, _vaultId, uint256(_tranche), userInvested, excess);
    return (userInvested, excess);
  }

  function claim(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256, uint256)
  {
    return _claim(_vaultId, _tranche, msg.sender);
  }

  function claimETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256 invested, uint256 excess)
  {
    onlyETH(_vaultId, _tranche);
    (invested, excess) = _claim(_vaultId, _tranche, address(this));
    registry.weth().withdraw(excess);
    safeTransferETH(msg.sender, excess);
  }

  /**
   * @notice Called by rollover to claim both tranches
   * @dev Triggers minting of tranche tokens. Moves excess to Rollover.
   * @param _vaultId Vault id
   * @param _rolloverId Rollover ID
   * @return srRollInv Amount invested in tranche
   * @return jrRollInv Amount invested in tranche
   */
  function rolloverClaim(uint256 _vaultId, uint256 _rolloverId)
    external
    override
    whenNotPaused
    nonReentrant
    atState(_vaultId, OLib.State.Live)
    onlyRollover(_vaultId, _rolloverId)
    returns (uint256 srRollInv, uint256 jrRollInv)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    OLib.Investor storage investor =
      investors[address(senior_.trancheToken)][msg.sender];
    require(!investor.claimed, "Already claimed");
    srRollInv = _getRolloverInvested(senior_);
    jrRollInv = _getRolloverInvested(junior_);
    if (srRollInv > 0) {
      senior_.trancheToken.mint(msg.sender, srRollInv);
    }
    if (jrRollInv > 0) {
      junior_.trancheToken.mint(msg.sender, jrRollInv);
    }
    if (senior_.rolloverDeposited > srRollInv) {
      vault_.strategy.withdrawExcess(
        _vaultId,
        OLib.Tranche.Senior,
        msg.sender,
        senior_.rolloverDeposited - srRollInv
      );
    }
    if (junior_.rolloverDeposited > jrRollInv) {
      vault_.strategy.withdrawExcess(
        _vaultId,
        OLib.Tranche.Junior,
        msg.sender,
        junior_.rolloverDeposited - jrRollInv
      );
    }
    investor.claimed = true;
    emit RolloverClaimed(
      msg.sender,
      _rolloverId,
      _vaultId,
      srRollInv,
      jrRollInv
    );
    return (srRollInv, jrRollInv);
  }

  /**
   * @notice Redeem funds into AMM
   * @dev Exchange LP tokens for senior/junior assets. Compute the amount
   *      the senior tranche should get (like 10% more). The senior._received
   *      value should be equal to or less than that expected amount. The
   *      junior.received should be all that's left.
   * @param _vaultId Specific id for this Vault
   * @param _seniorMinReceived Compute total expected to redeem, factoring in slippage
   * @param _juniorMinReceived Same.
   */
  function redeem(
    uint256 _vaultId,
    uint256 _seniorMinReceived,
    uint256 _juniorMinReceived
  )
    external
    override
    whenNotPaused
    nonReentrant
    onlyRolloverOrStrategist(_vaultId)
    returns (uint256, uint256)
  {
    transition(_vaultId, OLib.State.Withdraw);
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    (senior_.received, junior_.received) = vault_.strategy.redeem(
      _vaultId,
      _getSeniorExpected(vault_, senior_),
      _seniorMinReceived,
      _juniorMinReceived
    );
    junior_.received -= takePerformanceFee(vault_, _vaultId);

    emit Redeemed(_vaultId, senior_.received, junior_.received);
    return (senior_.received, junior_.received);
  }

  /**
   * @notice Investors withdraw funds from Vault
   * @dev Based on the fraction of ownership in the original pool of invested assets,
          investors get the same fraction of the resulting pile of assets. All funds are withdrawn.
   * @param _vaultId Specific ID for this Vault
   * @param _tranche Tranche to be deposited in
   * @return tokensToWithdraw Amount investor received from transfer
   */
  function _withdraw(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    address _receiver
  )
    internal
    whenNotPaused
    atState(_vaultId, OLib.State.Withdraw)
    returns (uint256 tokensToWithdraw)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage asset_ = vault_.assets[_tranche];
    (, , , tokensToWithdraw) = vaultInvestor(_vaultId, _tranche);
    ITrancheToken token_ = asset_.trancheToken;
    if (registry.tokenMinting()) {
      uint256 bal = token_.balanceOf(msg.sender);
      if (bal > 0) {
        token_.burn(msg.sender, bal);
      }
    }
    asset_.token.safeTransferFrom(
      address(vault_.strategy),
      _receiver,
      tokensToWithdraw
    );
    investors[address(asset_.trancheToken)][msg.sender].withdrawn = true;
    emit Withdrew(msg.sender, _vaultId, uint256(_tranche), tokensToWithdraw);
    return tokensToWithdraw;
  }

  function withdraw(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256)
  {
    return _withdraw(_vaultId, _tranche, msg.sender);
  }

  function withdrawETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256 amount)
  {
    onlyETH(_vaultId, _tranche);
    amount = _withdraw(_vaultId, _tranche, address(this));
    registry.weth().withdraw(amount);
    safeTransferETH(msg.sender, amount);
  }

  receive() external payable {
    assert(msg.sender == address(registry.weth()));
  }

  /**
   * @notice Exchange the correct ratio of senior/junior tokens to get LP tokens
   * @dev Burn tranche tokens on both sides and send LP tokens to customer
   * @param _vaultId  reference to Vault
   * @param _shares Share of lp tokens to withdraw
   */
  function withdrawLp(uint256 _vaultId, uint256 _shares)
    external
    override
    whenNotPaused
    nonReentrant
    atState(_vaultId, OLib.State.Live)
    returns (uint256 seniorTokensNeeded, uint256 juniorTokensNeeded)
  {
    require(registry.tokenMinting(), "Vault tokens inactive");
    Vault storage vault_ = Vaults[_vaultId];
    (seniorTokensNeeded, juniorTokensNeeded) = getWithdrawLp(_vaultId, _shares);
    vault_.assets[OLib.Tranche.Senior].trancheToken.burn(
      msg.sender,
      seniorTokensNeeded
    );
    vault_.assets[OLib.Tranche.Junior].trancheToken.burn(
      msg.sender,
      juniorTokensNeeded
    );
    vault_.assets[OLib.Tranche.Senior].totalInvested -= seniorTokensNeeded;
    vault_.assets[OLib.Tranche.Junior].totalInvested -= juniorTokensNeeded;
    vault_.strategy.removeLp(_vaultId, _shares, msg.sender);
    emit WithdrewLP(msg.sender, _shares);
  }

  function getWithdrawLp(uint256 _vaultId, uint256 _shares)
    public
    view
    atState(_vaultId, OLib.State.Live)
    returns (uint256 seniorTokensNeeded, uint256 juniorTokensNeeded)
  {
    Vault storage vault_ = Vaults[_vaultId];
    (, uint256 totalShares) = vault_.strategy.getVaultInfo(_vaultId);
    seniorTokensNeeded =
      (vault_.assets[OLib.Tranche.Senior].totalInvested * _shares) /
      totalShares;
    juniorTokensNeeded =
      (vault_.assets[OLib.Tranche.Junior].totalInvested * _shares) /
      totalShares;
  }

  function getState(uint256 _vaultId)
    public
    view
    override
    returns (OLib.State)
  {
    Vault storage vault_ = Vaults[_vaultId];
    return vault_.state;
  }

  /**
   * Helper functions
   */

  /**
   * @notice Compute performance fee for strategist
   * @dev If junior makes at least as much as the senior, then charge
   *      a performance fee on junior's earning beyond the hurdle.
   * @param vault Vault to work on
   * @return fee Amount of tokens deducted from junior tranche
   */
  function takePerformanceFee(Vault storage vault, uint256 vaultId)
    internal
    returns (uint256 fee)
  {
    fee = 0;
    if (address(performanceFeeCollector) != address(0)) {
      Asset storage junior = vault.assets[OLib.Tranche.Junior];
      uint256 juniorHurdle =
        (junior.totalInvested * vault.hurdleRate) / denominator;

      if (junior.received > juniorHurdle) {
        fee =
          (vault.performanceFee * (junior.received - juniorHurdle)) /
          denominator;
        IERC20(junior.token).safeTransferFrom(
          address(vault.strategy),
          address(performanceFeeCollector),
          fee
        );
        performanceFeeCollector.processFee(vaultId, IERC20(junior.token), fee);
      }
    }
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH transfer failed");
  }

  /**
   * @notice Multiply senior by hurdle raten
   * @param vault Vault to work on
   * @param senior Relevant asset
   * @return Max value senior can earn for this Vault
   */
  function _getSeniorExpected(Vault storage vault, Asset storage senior)
    internal
    view
    returns (uint256)
  {
    return (senior.totalInvested * vault.hurdleRate) / denominator;
  }

  function _getNetOriginalInvested(Asset storage asset)
    internal
    view
    returns (uint256)
  {
    uint256 o = asset.originalInvested;
    uint256 r = asset.rolloverDeposited;
    return o > r ? o - r : 0;
  }

  function _getRolloverInvested(Asset storage asset)
    internal
    view
    returns (uint256)
  {
    uint256 o = asset.originalInvested;
    uint256 r = asset.rolloverDeposited;
    return o > r ? r : o;
  }

  /**
   * Setters
   */

  /**
   * @notice Set optional performance fee for Vault
   * @dev Only available before deposits are open
   * @param _vaultId Vault to work on
   * @param _performanceFee Percent fee, denominator is 10000
   */
  function setPerformanceFee(uint256 _vaultId, uint256 _performanceFee)
    external
    onlyStrategist(_vaultId)
    atState(_vaultId, OLib.State.Inactive)
  {
    require(_performanceFee <= denominator, "Too high");
    Vault storage vault_ = Vaults[_vaultId];
    vault_.performanceFee = _performanceFee;
    // emit PerformanceFeeSet(_vaultId, _performanceFee);
  }

  /**
   * @notice All performanceFees go this address. Only set by governance role.
   * @param _collector Address of collector contract
   */
  function setPerformanceFeeCollector(address _collector)
    external
    isAuthorized(OLib.GOVERNANCE_ROLE)
  {
    performanceFeeCollector = IFeeCollector(_collector);
    // emit PerformanceFeeCollectorSet(_collector);
  }

  function canDeposit(uint256 _vaultId) external view override returns (bool) {
    Vault storage vault_ = Vaults[_vaultId];
    if (vault_.state == OLib.State.Inactive) {
      return vault_.startAt <= block.timestamp && vault_.startAt > 0;
    }
    return vault_.state == OLib.State.Deposit;
  }

  function getVaults(uint256 _from, uint256 _to)
    external
    view
    returns (VaultView[] memory vaults)
  {
    EnumerableSet.UintSet storage vaults_ = vaultIDs;
    uint256 len = vaults_.length();
    if (len == 0) {
      return new VaultView[](0);
    }
    if (len <= _to) {
      _to = len - 1;
    }
    vaults = new VaultView[](1 + _to - _from);
    for (uint256 i = _from; i <= _to; i++) {
      vaults[i - _from] = getVaultById(vaults_.at(i));
    }
    return vaults;
  }

  function getVaultByToken(address _trancheToken)
    external
    view
    returns (VaultView memory)
  {
    return getVaultById(VaultsByTokens[_trancheToken]);
  }

  function getVaultById(uint256 _vaultId)
    public
    view
    override
    returns (VaultView memory vault)
  {
    Vault storage svault_ = Vaults[_vaultId];
    mapping(OLib.Tranche => Asset) storage sassets_ = svault_.assets;
    Asset[] memory assets = new Asset[](2);
    assets[0] = sassets_[OLib.Tranche.Senior];
    assets[1] = sassets_[OLib.Tranche.Junior];
    vault = VaultView(
      _vaultId,
      assets,
      svault_.strategy,
      svault_.creator,
      svault_.strategist,
      svault_.rollover,
      svault_.hurdleRate,
      svault_.state,
      svault_.startAt,
      svault_.investAt,
      svault_.redeemAt
    );
  }

  function seniorExpected(uint256 _vaultId)
    external
    view
    override
    returns (uint256)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    return _getSeniorExpected(vault_, senior_);
  }

  /*
   * @return position: total user invested = unclaimed invested amount + tranche token balance
   * @return claimableBalance: unclaimed invested deposit amount that can be converted into tranche tokens by claiming
   * @return withdrawableExcess: unclaimed uninvested deposit amount that can be recovered by claiming
   * @return withdrawableBalance: total amount that the user can redeem their position for by withdrawaing, 0 if the product is still live
   */
  function vaultInvestor(uint256 _vaultId, OLib.Tranche _tranche)
    public
    view
    override
    returns (
      uint256 position,
      uint256 claimableBalance,
      uint256 withdrawableExcess,
      uint256 withdrawableBalance
    )
  {
    Asset storage asset_ = Vaults[_vaultId].assets[_tranche];
    OLib.Investor storage investor_ =
      investors[address(asset_.trancheToken)][msg.sender];
    if (!investor_.withdrawn) {
      (position, withdrawableExcess) = investor_.getInvestedAndExcess(
        _getNetOriginalInvested(asset_)
      );
      if (!investor_.claimed) {
        claimableBalance = position;
        position += asset_.trancheToken.balanceOf(msg.sender);
      } else {
        withdrawableExcess = 0;
        if (registry.tokenMinting()) {
          position = asset_.trancheToken.balanceOf(msg.sender);
        }
      }
      if (Vaults[_vaultId].state == OLib.State.Withdraw) {
        claimableBalance = 0;
        withdrawableBalance =
          withdrawableExcess +
          (asset_.received * position) /
          asset_.totalInvested;
      }
    }
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function excall(address target, bytes calldata data)
    external
    isAuthorized(OLib.GUARDIAN_ROLE)
    returns (bytes memory returnData)
  {
    bool success;
    (success, returnData) = target.call(data);
    require(success, "CF");
  }
}