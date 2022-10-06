// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {
  BaseControlledMintableBurnableERC20
} from './interfaces/BaseControlledMintableBurnableERC20.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title ERC20 token contract
 */
contract MintableBurnableERC20 is
  BaseControlledMintableBurnableERC20,
  AccessControlEnumerable
{
  bytes32 public constant MINTER_ROLE = keccak256('Minter');

  bytes32 public constant BURNER_ROLE = keccak256('Burner');

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), 'Sender must be the minter');
    _;
  }

  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, msg.sender), 'Sender must be the burner');
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  /**
   * @notice Constructs the ERC20 token contract
   * @param _tokenName Name of the token
   * @param _tokenSymbol Token symbol
   * @param _tokenDecimals Number of decimals for token
   */
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  )
    BaseControlledMintableBurnableERC20(
      _tokenName,
      _tokenSymbol,
      _tokenDecimals
    )
  {
    _setupDecimals(_tokenDecimals);
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(BURNER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Mint new ERC20 tokens
   * @param recipient Recipient of the minted tokens
   * @param value Amount of tokens to be minted
   */
  function mint(address recipient, uint256 value)
    external
    override
    onlyMinter()
    returns (bool)
  {
    _mint(recipient, value);
    return true;
  }

  /**
   * @notice Burn ERC20 tokens
   * @param value Amount of ERC20 tokens to be burned
   */
  function burn(uint256 value) external override onlyBurner() {
    _burn(msg.sender, value);
  }

  /**
   * @notice Assign a new minting role
   * @param account Address of the new minter
   */
  function addMinter(address account) public virtual override {
    grantRole(MINTER_ROLE, account);
  }

  /**
   * @notice Assign a new burning role
   * @param account Address of the new burner
   */
  function addBurner(address account) public virtual override {
    grantRole(BURNER_ROLE, account);
  }

  /**
   * @notice Assign new admin role
   * @param account Address of the new admin
   */
  function addAdmin(address account) public virtual override {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
   * @notice Assign admin, minting and burning priviliges to an address
   * @param account Address to which roles are assigned
   */
  function addAdminAndMinterAndBurner(address account) public virtual override {
    grantRole(DEFAULT_ADMIN_ROLE, account);
    grantRole(MINTER_ROLE, account);
    grantRole(BURNER_ROLE, account);
  }

  /**
   * @notice Self renounce the address calling the function from minter role
   */
  function renounceMinter() public virtual override {
    renounceRole(MINTER_ROLE, msg.sender);
  }

  /**
   * @notice Self renounce the address calling the function from burner role
   */
  function renounceBurner() public virtual override {
    renounceRole(BURNER_ROLE, msg.sender);
  }

  /**
   * @notice Self renounce the address calling the function from admin role
   */
  function renounceAdmin() public virtual override {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /**
   * @notice Self renounce the address calling the function from admin, minter and burner role
   */
  function renounceAdminAndMinterAndBurner() public virtual override {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    renounceRole(MINTER_ROLE, msg.sender);
    renounceRole(BURNER_ROLE, msg.sender);
  }
}