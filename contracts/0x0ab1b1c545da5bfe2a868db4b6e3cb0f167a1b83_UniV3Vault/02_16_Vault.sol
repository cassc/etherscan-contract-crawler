// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./VaultBearerToken.sol";
import "./adapters/AdapterBase.sol";
import "./interfaces/IVault.sol";
import "./vendor/@uniswap/v3-periphery/contracts/libraries/FullMath.sol";

/// @title Saffron Fixed Income Vault
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Foundational contract for building vaults, which coordinate user deposits and earnings
/// @dev Extend this abstract class to implement vaults
abstract contract Vault is IVault, ReentrancyGuard {
  using SafeERC20 for IERC20;
  /// @notice True when the vault is initialized
  bool public initialized;
  /// @notice Vault factory address
  address public factory;

  /// @notice Adapter that manages fixed side deposit assets and associated earnings
  AdapterBase public adapter;

  /// @notice Vault identifier
  uint256 public vaultId;

  /// @notice Length of the earning period of the vault in seconds
  uint256 public duration;

  /// @notice End of duration; funds can be withdrawn after this time
  /// @dev Calculated when vault starts via (block.timestamp + duration)
  uint256 public endTime;

  /// @inheritdoc IVault
  bool public override isStarted;

  /// @inheritdoc IVault
  bool public override earningsSettled;

  /// @notice Variable side ERC20 base asset
  address public variableAsset;

  /// @inheritdoc IVault
  uint256 public override fixedSideCapacity;

  /// @notice Capacity in units of variableAsset
  uint256 public variableSideCapacity;

  /// @notice Saffron fee in basis points
  uint256 public feeBps;

  /// @notice Address that collects the protocol fee
  address public feeReceiver;

  /// @notice ERC20 bearer token that entitles owner to a portion of the fixed side deposits
  VaultBearerToken public fixedBearerToken;

  /// @notice ERC20 bearer token that entitles owner to a portion of the vault earnings
  VaultBearerToken public variableBearerToken;

  /// @notice ERC20 bearer token that entitles owner to a portion of the fixed side bearer tokens and the variable side premium payment
  /// @dev If the vault hasn't started, this is used to return the fixed side deposit
  VaultBearerToken public claimToken;

  uint256 constant FIXED = 0;
  uint256 constant VARIABLE = 1;

  /// @notice Emitted when the funds are deposited into the vault
  /// @param amounts Amounts deposited
  /// @param side Fixed or Variable sides (0 or 1)
  /// @param user Address of user
  event FundsDeposited(uint256[] amounts, uint256 side, address indexed user);

  /// @notice Emitted when the funds are withdrawn from the vault
  /// @param amounts Amounts withdrawn
  /// @param side Fixed or Variable sides (0 or 1)
  /// @param user Address of user
  /// @param isEarly Indicates whether withdrawal occurred before or after the vault was started
  event FundsWithdrawn(uint256[] amounts, uint256 side, address indexed user, bool indexed isEarly);

  /// @notice Emitted when the vault has filled and moved into the started phase
  /// @param timeStarted Time the vault started
  /// @param user Address of user that triggered the start of the vault
  event VaultStarted(uint256 timeStarted, address indexed user);

  /// @notice Emitted when the vault has passed its expiration time and moved into the ended phase
  /// @param timeEnded Time the vault ended
  /// @param user Address of user that triggered the end of the vault
  event VaultEnded(uint256 timeEnded, address indexed user);

  /// @dev Vault factory will always be msg.sender
  constructor() {
    factory = msg.sender;
  }

  modifier notInitialized() {
    require(!initialized, "AI");
    _;
  }

  modifier isInitialized() {
    require(initialized, "NI");
    _;
  }

  /// @inheritdoc IVault
  function initialize(
    uint256 _vaultId,
    uint256 _duration,
    address _adapter,
    uint256 _fixedSideCapacity,
    uint256 _variableSideCapacity,
    address _variableAsset,
    uint256 _feeBps,
    address _feeReceiver
  ) public virtual override notInitialized {
    // Validate args
    // vaultId and feeBps are already checked in the VaultFactory
    require(msg.sender == factory, "NF");
    require(_duration != 0, "NEI");
    require(_adapter != address(0), "NEI");
    require(_variableSideCapacity != 0, "NEI");
    require(_fixedSideCapacity != 0, "NEI");
    require(_variableAsset != address(0), "NEI");
    require(_feeReceiver != address(0), "NEI");

    // Initialize contract state variables
    adapter = AdapterBase(_adapter);
    require(adapter.factoryAddress() == factory, "AWF");
    initialized = true;
    vaultId = _vaultId;
    duration = _duration;
    variableAsset = _variableAsset;
    feeBps = _feeBps;
    feeReceiver = _feeReceiver;
    fixedSideCapacity = _fixedSideCapacity;
    variableSideCapacity = _variableSideCapacity;

    // Create bearer token contracts
    fixedBearerToken = new VaultBearerToken("Saffron Vault Fixed Bearer Token", "SAFF-BTF");
    variableBearerToken = new VaultBearerToken("Saffron Vault Variable Bearer Token", "SAFF-BTV");
    claimToken = new VaultBearerToken("Saffron Vault Fixed Claim Token", "SAFF-CT");
  }

  /// @notice Claim fixed side bearer tokens with fixed side claim tokens
  function claim() public virtual isInitialized nonReentrant {
    require(isStarted, "CBS");

    // Check and cache balance for gas savings
    uint256 claimBal = claimToken.balanceOf(msg.sender);
    require(claimBal > 0, "NCT");

    // Send a proportional share of the total variable side deposits (premium) to the fixed side depositor
    uint256 amount = FullMath.mulDiv(
      FullMath.mulDiv(claimBal, 1e18, claimToken.totalSupply()),
      IERC20(variableAsset).balanceOf(address(this)),
      1e18
    );
    IERC20(variableAsset).safeTransfer(msg.sender, amount);

    // Mint bearer token
    fixedBearerToken.mint(msg.sender, claimBal);

    // Burn claim tokens
    claimToken.burn(msg.sender, claimBal);
  }

  /// @notice Vaults are auto-started when fixed and variable sides have reached capacity
  function start() internal virtual {
    isStarted = true;
    endTime = block.timestamp + duration;
    emit VaultStarted(block.timestamp, msg.sender);
  }

  /// @notice Mint variable side tokens for feeReceiver who is allocated a percentage of earnings
  function applyFee() internal virtual {
    uint256 fee = FullMath.mulDiv(variableBearerToken.totalSupply(), feeBps, 10_000 - feeBps);
    if (fee > 0) {
      // Mint bearer tokens for protocol fee
      variableBearerToken.mint(feeReceiver, fee);
    }
  }
}