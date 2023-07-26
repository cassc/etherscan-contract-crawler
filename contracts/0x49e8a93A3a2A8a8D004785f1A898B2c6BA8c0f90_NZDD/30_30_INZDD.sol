// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @title IEasyCrypto.sol
 * @notice The interface for the Easy Crypto ERC20 token.
 */
interface INZDD {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          ERRORS                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /**
   * Error thrown when a parameter provided is empty (commonly address or strings).
   * @param param The name of the parameter that contains the zero address.
   */
  error EmptyParameter(string param);

  /**
   * @notice Error thrown when an account that is being blacklisted is already on the blacklist.
   * @param _account The account that is already blacklisted.
   */
  error AddressAlreadyBlacklisted(address _account);

  /**
   * @notice Error thrown when trying to unblacklist an account that hasn't been blacklisted.
   * @param _account The account that is already blacklisted.
   */
  error AddressNotBlacklisted(address _account);

  /**
   * @notice Error thrown when trying to transfer tokens to or from a blacklisted account.
   * @param _account The account that is blacklisted.
   */
  error AddressBlacklisted(address _account);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          EVENTS                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /**
   * Event emitted when a user is blacklisted.
   *
   * @param _account The account that is blacklisted.
   */
  event Blacklisted(address indexed _account);

  /**
   * The event emitted when a user is unblacklisted.
   *
   * @param _account The account that has been unblacklisted.
   */
  event UnBlacklisted(address indexed _account);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          FUNCTIONS                         */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /**
   * Pause function - pauses all transfers.
   * @notice Only callable by the DEFAULT_ADMIN_ROLE.
   */
  function pause() external;

  /**
   * @notice Unpause function - unpauses all transfers.
   * @dev only callable by the DEFAULT_ADMIN_ROLE.
   */
  function unpause() external;

  /**
   * @notice The mint function for this ERC-20 contract.
   * @param _to The address to mint tokens to
   * @param _amount The amount of tokens to mint (with X decimals)
   * @dev only callable by accounts with the NZDD_MINTER_ROLE assigned.
   */
  function mint(address _to, uint256 _amount) external;

  /**
   * @notice A helper function that returns true or false if an account is blacklisted.
   * @param _account The address to check blacklist status of.
   */
  function isBlacklisted(address _account) external view returns (bool);

  /**
   * @notice Adds account to the blacklist.
   * @param _account The address to blacklist.
   * @dev Only callable by accounts with the NZDD_BLACKLISTER_ROLE.
   */
  function blacklist(address _account) external;

  /**
   * @notice Removes account from blacklist.
   * @param _account The address to remove from the blacklist.
   * @dev Only callable by accounts with the NZDD_BLACKLISTER_ROLE.
   */
  function unBlacklist(address _account) external;
}