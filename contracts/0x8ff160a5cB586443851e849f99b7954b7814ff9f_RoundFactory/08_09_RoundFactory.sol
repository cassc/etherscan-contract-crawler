// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./IRoundFactory.sol";
import "./IRoundImplementation.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../utils/MetaPtr.sol";

/**
 * @notice Invoked by a RoundOperator to enable creation of a
 * round by cloning the RoundImplementation contract.
 * The factory contract emits an event anytime a round is created
 * which can be used to derive the round registry.
 *
 * @dev RoundFactory is deployed once per chain and stores
 * a reference to the deployed RoundImplementation.
 * @dev RoundFactory uses openzeppelin Clones to reduce deploy
 * costs and also allows upgrading RoundImplementationUpdated.
 * @dev This contract is Ownable thus supports ownership transfership
 *
 */
contract RoundFactory is IRoundFactory, OwnableUpgradeable {
  string public constant VERSION = "0.2.0";

  // --- Data ---

  /// @notice Address of the RoundImplementation contract
  address public roundImplementation;

  /// @notice Address of the Allo settings contract
  address public alloSettings;

  /// @notice Nonce used to generate deterministic salt for Clones
  uint256 public nonce;

  // --- Event ---

  /// @notice Emitted when allo settings contract is updated
  event AlloSettingsUpdated(address alloSettings);

  /// @notice Emitted when a Round implementation contract is updated
  event RoundImplementationUpdated(address roundImplementation);

  /// @notice Emitted when a new Round is created
  event RoundCreated(
    address indexed roundAddress,
    address indexed ownedBy,
    address indexed roundImplementation
  );

  /// @notice constructor function which ensure deployer is set as owner
  function initialize() external initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
  }

  // --- Core methods ---

  /**
   * @notice Allows the owner to update the allo settings contract.
   *
   * @param newAlloSettings New allo settings contract address
   */
  function updateAlloSettings(address newAlloSettings) external onlyOwner {
    alloSettings = newAlloSettings;

    emit AlloSettingsUpdated(alloSettings);
  }

  /**
   * @notice Allows the owner to update the RoundImplementation.
   * This provides us the flexibility to upgrade RoundImplementation
   * contract while relying on the same RoundFactory to get the list of
   * rounds.
   *
   * @param newRoundImplementation New RoundImplementation contract address
   */
  function updateRoundImplementation(address payable newRoundImplementation) external onlyOwner {

    require(newRoundImplementation != address(0), "roundImplementation is 0x");

    roundImplementation = newRoundImplementation;

    emit RoundImplementationUpdated(roundImplementation);
  }

  /**
   * @notice Clones RoundImplementation a new round and emits event
   *
   * @param encodedParameters Encoded parameters for creating a round
   * @param ownedBy Program which created the contract
   */
  function create(
    bytes calldata encodedParameters,
    address ownedBy
  ) external returns (address) {

    nonce++;

    require(roundImplementation != address(0), "roundImplementation is 0x");
    require(alloSettings != address(0), "alloSettings is 0x");

    bytes32 salt = keccak256(abi.encodePacked(msg.sender, nonce));
    address clone = ClonesUpgradeable.cloneDeterministic(roundImplementation, salt);

    emit RoundCreated(clone, ownedBy, payable(roundImplementation));

    IRoundImplementation(payable(clone)).initialize(
      encodedParameters,
      alloSettings
    );

    return clone;
  }
}