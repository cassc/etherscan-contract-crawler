/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Capped.sol';

import '../../interfaces/uniswap/IUniswapV2Router02.sol';
import '../../interfaces/uniswap/IUniswapV2Factory.sol';
import '../../interfaces/uniswap/IUniswapV2Pair.sol';

import '../investment/interfaces/IRewardHandler.sol';
import '../investment/interfaces/ITxWorker.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

import './interfaces/IERC20WolfMintable.sol';

contract WowsToken is
  IERC20WolfMintable,
  ERC20Capped,
  AccessControl,
  IRewardHandler,
  AddressBook
{
  using SafeMath for uint256;

  /**
   * @dev The ERC 20 token name used by wallets to identify the token
   */
  string private constant TOKEN_NAME = 'Wolves Of Wall Street';

  /**
   * @dev The ERC 20 token symbol used as an abbreviation of the token, such
   * as BTC, ETH, AUG or SJCX.
   */
  string private constant TOKEN_SYMBOL = 'WOWS';

  /**
   * @dev The number of decimal places to which the token will be calculated.
   * The most common number of decimals to consider is 18.
   */
  uint8 private constant TOKEN_DECIMALS = 18;

  /**
   * @dev 60.000 tokens maximal supply
   */
  uint256 private constant MAX_SUPPLY = 60000 * 1e18;

  /**
   * @dev Role to allow minting of new tokens
   */
  bytes32 public constant MINTER_ROLE = 'minter_role';

  /**
   * @dev Role to allow reward distributon
   */
  bytes32 public constant REWARD_ROLE = 'reward_role';

  address public immutable uniV2Pair;
  bytes32 private immutable _uniV2PairCodeHash;

  address private immutable _teamWallet;
  address private immutable _marketingWallet;

  /**
   * @dev booster address for rewards
   */
  address public booster;

  /**
   * @dev transaction worker for low gas service tasks
   */
  ITxWorker public txWorker;

  /**
   * @dev If false, this pair is blocked
   */
  mapping(address => bool) private _uniV2Whitelist;

  /**
   * @dev Construct a token instance
   *
   * @param _addressRegistry registry to get required contracts
   */
  constructor(IAddressRegistry _addressRegistry)
    ERC20Capped(MAX_SUPPLY)
    ERC20(TOKEN_NAME, TOKEN_SYMBOL)
  {
    // Initialize ERC20 base
    _setupDecimals(TOKEN_DECIMALS);

    /*
     * Mint 3600 into teams wallet
     *
     *   1.) 1800 token for development costs (audits / bug-bounty ...)
     *   2.) 1800 token for marketing (influencer / design ...)
     */
    // reverts if address is invalid
    address __marketingWallet =
      _addressRegistry.getRegistryEntry(MARKETING_WALLET);
    _mint(__marketingWallet, 3600 * 1e18);
    _marketingWallet = __marketingWallet;

    /*
     * Mint 7500 token into teams wallet
     *
     *   1.) 500 tokens * 15 month = 7500 team rewards
     */
    // reverts if address is invalid
    address __teamWallet = _addressRegistry.getRegistryEntry(TEAM_WALLET);
    _mint(__teamWallet, 7500 * 1e18);
    _teamWallet = __teamWallet;

    // Multi-sig teamwallet has initial admin rights, eg for adding minters
    _setupRole(DEFAULT_ADMIN_ROLE, __marketingWallet);

    // Reverts if address is invalid
    IUniswapV2Router02 _uniV2Router =
      IUniswapV2Router02(
        _addressRegistry.getRegistryEntry(UNISWAP_V2_ROUTER02)
      );

    // Create the UniV2 liquidity pool
    address _uniV2Pair =
      IUniswapV2Factory(_uniV2Router.factory()).createPair(
        address(this),
        _uniV2Router.WETH()
      );
    uniV2Pair = _uniV2Pair;

    // Retrieve the code hash of UniV2 pair which is same for all other univ2 pairs
    bytes32 codeHash;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codeHash := extcodehash(_uniV2Pair)
    }
    _uniV2PairCodeHash = codeHash;
  }

  /**
   * @dev Mint tokens
   *
   * @param account The account to receive the tokens
   * @param amount The amount to mint
   *
   * @return True if successful, reverts on failure
   */
  function mint(address account, uint256 amount)
    external
    override
    returns (bool)
  {
    // Mint is only allowed by addresses with minter role
    require(hasRole(MINTER_ROLE, msg.sender), 'Only minters');

    _mint(account, amount);

    return true;
  }

  /**
   * @dev Add ETH/WOLF univ2 pair address to whitelist
   *
   * @param enable True to enable the univ2 pair, false to disable
   */
  function enableUniV2Pair(bool enable) external override {
    require(hasRole(MINTER_ROLE, msg.sender), 'Only minters');
    _uniV2Whitelist[uniV2Pair] = enable;
  }

  /**
   * @dev Add univ2 pair address to whitelist
   *
   * @param pairAddress The address of the univ2 pair
   */
  function enableUniV2Pair(address pairAddress) external {
    require(
      hasRole(MINTER_ROLE, msg.sender) ||
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      'Only minters and admins'
    );
    _uniV2Whitelist[pairAddress] = true;
  }

  /**
   * @dev Remove univ2 pair address from whitelist
   */
  function disableUniV2Pair(address pairAddress) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only admins');
    _uniV2Whitelist[pairAddress] = false;
  }

  /**
   * @dev Request the state of the univ2 pair address
   */
  function isUniV2PairEnabled(address pairAddress)
    external
    view
    returns (bool)
  {
    return _uniV2Whitelist[pairAddress];
  }

  /**
   * @dev Override to prevent creation of uniswap LP's with WOLF token
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    // Minters are always allowed to transfer
    require(
      hasRole(MINTER_ROLE, sender) ||
        hasRole(MINTER_ROLE, recipient) ||
        (_checkForUniV2Pair(sender) && _checkForUniV2Pair(recipient)),
      'Only minters and != pairs'
    );
    super._transfer(sender, recipient, amount);

    // check for low gas tasks
    if (address(txWorker) != address(0)) txWorker.onTransaction(0);
  }

  /**
   * @dev Check if recipient is either on the whitelist, or not an UniV2 pair
   *
   * Only minter and admin role are allowed to enable initial blacklisted
   * pairs. Goal is to let us initialize uniV2 pairs with a ratio defined
   * from concept.
   */
  function _checkForUniV2Pair(address recipient) public view returns (bool) {
    // Early exit if recipient is already whitelisted
    if (_uniV2Whitelist[recipient]) return true;

    // Compare contract code of recipient with
    bytes32 codeHash;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codeHash := extcodehash(recipient)
    }

    // Return true, if codehash != uniV2PairCodeHash
    return codeHash != _uniV2PairCodeHash;
  }

  function setBooster(address _booster) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only admins');
    booster = _booster;
  }

  function setTXWorker(address _txWorker) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only admins');
    txWorker = ITxWorker(_txWorker);
  }

  /* ================ IRewardHandler ================= */

  function distribute(
    address _recipient,
    uint256 _amount,
    uint32 _fee,
    uint32 _toTeam,
    uint32 _toMarketing,
    uint32 _toBooster,
    uint32 _toRewardPool
  ) external override {
    require(hasRole(REWARD_ROLE, msg.sender), 'Only rewarders');

    if (_amount == 0) return;

    // Check how much we have to mint
    uint256 balance = balanceOf(address(this));
    if (balance < _amount) _mint(address(this), _amount - balance);

    // Distribute the fee
    uint256 absFee = _amount.mul(_fee).div(1e6);
    _transfer(address(this), _teamWallet, absFee.mul(_toTeam).div(1e6));
    _transfer(
      address(this),
      _marketingWallet,
      absFee.mul(_toMarketing).div(1e6)
    );

    if (booster != address(0))
      _transfer(address(this), booster, absFee.mul(_toBooster).div(1e6));

    // Nothing to do with _toRewardPool beause we are rewardPool
    _toRewardPool;

    // Now send rewards to the user
    _transfer(address(this), _recipient, _amount.sub(absFee));
  }
}