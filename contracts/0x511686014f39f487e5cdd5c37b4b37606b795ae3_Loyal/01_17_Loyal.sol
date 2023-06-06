// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Loyal is Ownable, Pausable, ERC20, ERC20Burnable {

  /** Total amount of tokens */
  uint256 private constant  TOTAL_SUPPLY    = 210_000_000_000 ether;
  /** Reserve amount of tokens for future development */
  uint256 private constant  RESERVE         = 42_000_000_000 ether;
  /** Allocation for presale buyers and LP */
  uint256 private constant  DISTRIBUTION    = 168_000_000_000 ether;

  /** Amount must be greater than zero */
  error NoZeroTransfers();
  /** Paused */
  error ContractPaused();
  /** Reserve + Distribution must equal Total Supply (sanity check) */
  error IncorrectSum();

  constructor(
    IUniswapV3Factory _V3Factory,
    IUniswapV2Factory _V2Factory,
    address _weth, 
    address _psyop,
    uint160 _sqrtPriceX96,
    uint160 _psyopSqrtPriceX96,
    address _ben
  ) ERC20("Loyalty Labs", "LOYAL") {
    if (RESERVE + DISTRIBUTION != TOTAL_SUPPLY) { revert IncorrectSum(); }
    _mint(_ben, RESERVE);
    _mint(msg.sender, DISTRIBUTION);
    _pause();

    IUniswapV3Pool(_V3Factory.createPool(address(this), _weth, 3000)).initialize(_sqrtPriceX96);
    IUniswapV3Pool(_V3Factory.createPool(address(this), _weth, 10000)).initialize(_sqrtPriceX96);
    IUniswapV3Pool(_V3Factory.createPool(address(this), _psyop, 3000)).initialize(_psyopSqrtPriceX96);
    IUniswapV3Pool(_V3Factory.createPool(address(this), _psyop, 10000)).initialize(_psyopSqrtPriceX96);
    _V2Factory.createPair(address(this), _weth);
  }

  /// @notice Pause trading
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause trading
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev Hook that is called before any transfer of tokens.  This includes
   * minting and burning.
   *
   * Checks:
   * - transfer amount is non-zero
   * - contract is not paused.
   * - operator allowed during pause to setup LP etc.
   */
  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    if (amount == 0) { revert NoZeroTransfers(); }
    if (paused() && owner() != sender) { revert ContractPaused(); }
    super._beforeTokenTransfer(sender, recipient, amount);
  }
}