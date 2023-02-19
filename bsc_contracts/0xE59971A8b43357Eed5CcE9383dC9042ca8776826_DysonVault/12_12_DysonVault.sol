// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IStrategyDystopia.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 * The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract DysonVault is Initializable, OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // The strategy currently in use by the vault.
  IStrategyDystopia public strategy;

  bool private _isStrategyInitialized;

  /**
   * @dev Sets the value of {token} to the token that the vault will
   * hold as underlying value. It initializes the vault's own 'moo' token.
   * This token is minted when someone does a deposit. It is burned in order
   * to withdraw the corresponding portion of the underlying assets.
   * @param _name the name of the vault token.
   * @param _symbol the symbol of the vault token.
   */

  function __DysonVault_init(string memory _name, string memory _symbol) public initializer {
    __Ownable_init_unchained();
    __ERC20_init_unchained(_name, _symbol);
    __ReentrancyGuard_init_unchained();
    __DysonVault_init_unchained();
  }

  function __DysonVault_init_unchained() internal initializer {}

  function want() public view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(strategy.want());
  }

  /**
   * @dev It calculates the total underlying value of {token} held by the system.
   * It takes into account the vault contract balance, the strategy contract balance
   *  and the balance deployed in other contracts as part of the strategy.
   */
  function balance() public view returns (uint256) {
    return want().balanceOf(address(this)) + IStrategyDystopia(strategy).balanceOf();
  }

  function available() public view returns (uint256) {
    return want().balanceOf(address(this));
  }

  /**
   * @dev Function for various UIs to display the current value of one of our yield tokens.
   * Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
   */
  function getPricePerFullShare() public view returns (uint256) {
    return totalSupply() == 0 ? 1e18 : (balance() * 1e18) / totalSupply();
  }

  /**
   * @dev A helper function to call deposit() with all the sender's funds.
   */
  function depositAll() external {
    deposit(want().balanceOf(msg.sender));
  }

  /**
   * @dev The entrypoint of funds into the system. People deposit with this function
   * into the vault. The vault is then in charge of sending funds into the strategy.
   */
  function deposit(uint256 _amount) public nonReentrant {
    strategy.beforeDeposit();

    uint256 _pool = balance();
    want().safeTransferFrom(msg.sender, address(this), _amount);
    earn();
    uint256 _after = balance();
    _amount = _after - _pool;
    // Additional check for deflationary tokens
    uint256 shares = 0;
    if (totalSupply() == 0) {
      shares = _amount;
    } else {
      shares = (_amount * totalSupply()) / _pool;
    }
    _mint(msg.sender, shares);
  }

  /**
   * @dev Function to send funds into the strategy and put them to work. It's primarily called
   * by the vault's deposit() function.
   */
  function earn() public {
    uint256 _bal = available();
    want().safeTransfer(address(strategy), _bal);
    strategy.deposit();
  }

  /**
   * @dev A helper function to call withdraw() with all the sender's funds.
   */
  function withdrawAll() external {
    withdraw(balanceOf(msg.sender));
  }

  /**
   * @dev Function to exit the system. The vault will withdraw the required tokens
   * from the strategy and pay up the token holder. A proportional number of IOU
   * tokens are burned in the process.
   */
  function withdraw(uint256 _shares) public nonReentrant {
    uint256 r = (balance() * _shares) / totalSupply();
    _burn(msg.sender, _shares);

    uint256 b = want().balanceOf(address(this));
    if (b < r) {
      uint256 _withdraw = r - b;
      strategy.withdraw(_withdraw);
      uint256 _after = want().balanceOf(address(this));
      uint256 _diff = _after - b;
      if (_diff < _withdraw) {
        r = b + _diff;
      }
    }

    want().safeTransfer(msg.sender, r);
  }

  /**
   * @dev Rescues random funds stuck that the strat can't handle.
   * @param _token address of the token to rescue.
   */
  function inCaseTokensGetStuck(address _token) external onlyOwner {
    require(_token != address(want()), "!token");

    uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));
    IERC20Upgradeable(_token).safeTransfer(msg.sender, amount);
  }

  function setStrategy(IStrategyDystopia _strategy) public onlyOwner {
    require(!_isStrategyInitialized, "strategy already initialized");
    strategy = _strategy;
  }
}