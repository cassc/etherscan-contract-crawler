// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

// =====================================================================
//
// |  \/  (_) |         | |                 |  _ \                   | |
// | \  / |_| | ___  ___| |_ ___  _ __   ___| |_) | __ _ ___  ___  __| |
// | |\/| | | |/ _ \/ __| __/ _ \| '_ \ / _ \  _ < / _` / __|/ _ \/ _` |
// | |  | | | |  __/\__ \ || (_) | | | |  __/ |_) | (_| \__ \  __/ (_| |
// |_|  |_|_|_|\___||___/\__\___/|_| |_|\___|____/ \__,_|___/\___|\__,_|
//
// =====================================================================
// ======================= IContractsRegistry ==========================
// =====================================================================

/**
 * @dev External interface of `ContractsRegistry`
 */
interface IContractsRegistry {
  /**
   * @dev The error means that a certain field equal ZERO_ADDRESS, which shouldn't be
   *
   * Emitted when key registration
   */
  error ZeroAddress();

  /**
   * @dev The error means that an unregistered key was transmitted.
   *
   * Emitted when a method is called with an input parameter the key than the key must
   * be registered but it is not so
   */
  error KeyNotRegistered(uint256 key);

  /**
   * @dev The error means that the arrays have different lengths in the places where it is required
   */
  error ArrayDifferentLength();

  /**
   * @dev Emitted when `contractAddress` are set by `key` to register
   *
   * Note that `contractAddress` is the new address.
   * Note If `contractAddress` is `ZERO_ADDRESS` it's mean then it's delet
   */
  event UpdateKey(uint256 indexed key, address contractAddress);

  /**
   * @dev Emitted when `contractAddresses` are set by `keys` to register
   *
   * Note that `contractsAddresses` is the new addresses.
   */
  event UpdateKeys(uint256[] indexed keys, address[] contractsAddresses);

  /**
   * @dev Function to initialize the contract which replaces the constructor.
   * Appointment to establish the owner of the contract. Can be called only once
   */
  function initialize() external;

  /**
   * @dev Registers `contractAddress_` by `key_`.
   *
   * If `key_` had been registered, then the function will update
   * the address by key to a new one
   *
   * Requirements:
   *
   * - the caller must be `Owner`.
   * - `contractAddress_` must be not `ZERO_ADDRESS`
   *
   * Emits a {UpdateKey} event.
   */
  function registerContract(uint256 key_, address contractAddress_) external;

  /**
   * @dev Registers `contractsAddresses_` by `keys_`.
   *
   * If any key from `keys_` had been registered, then the function will update
   * the address by key to a new one
   *
   * Keys are tied to addresses, and addresses are tied to keys by the number
   * of the element in the arrays
   *
   * Requirements:
   *
   * - the caller must be `Owner`.
   * - `contractsAddresses_` must be not containts `ZERO_ADDRESS`
   * - arrays must be of the same length
   *
   * Emits a {UpdateKeys} event.
   */
  function registerContracts(
    uint256[] calldata keys_,
    address[] calldata contractsAddresses_
  ) external;

  /**
   * @dev Unregisters `contractAddress_` by `key_`.
   *
   * If `key_` had not been registered, then the function will revert
   *
   * Requirements:
   *
   * - the caller must be `Owner`.
   * - `key_` must be registered
   *
   * Emits a {UpdateKey} event.
   */
  function unregisterContract(uint256 key_) external;

  /**
   * @dev Returns the status of whether the `key_` is registered
   *
   * Returns types:
   * - `false` - if contract not registered
   * - `true` - if contract registered
   */
  function isRegistered(uint256 key_) external view returns (bool result);

  /**
   * @dev Returns the contract address by `key_`
   *
   * IMPORTANT: If `key_` had not been registered, then return `ZERO_ADDRESS`
   */
  function register(uint256 key_) external view returns (address result);

  /**
   * @dev Returns the contract address by `key_`
   *
   * IMPORTANT: If `key_` had not been registered, then the function will revert
   */
  function getContractByKey(uint256 key_)
    external
    view
    returns (address result);

  /**
   * @dev Returns the contracts addresses by `keys_`
   *
   * Keys are tied to addresses, and addresses are tied to keys by the number
   * of the element in the arrays
   *
   * IMPORTANT: If any key from `keys_` had not been registered, then the function will revert
   */
  function getContractsByKeys(uint256[] calldata keys_)
    external
    view
    returns (address[] memory result);
}