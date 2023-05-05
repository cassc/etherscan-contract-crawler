// SPDX-License-Identifier: MIT

// ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
// ⬜⬜⬜⬜⬜⬜⬜⬛⬛⬛⬛⬛⬛⬛⬜⬜⬜⬜⬜⬜⬜
// ⬜⬜⬜⬜⬜⬛⬛🟥⬛⬛🟥🟥🟥🟥⬛⬛⬜⬜⬜⬜⬜
// ⬜⬜⬜⬜⬛🟥🟥⬛⬛🟥🟥🟥🟥🟥🟥🟥⬛⬜⬜⬜⬜
// ⬜⬜⬜⬛🟥🟥⬛⬛⬛🟥🟥🟥🟥🟥🟥🟥🟥⬛⬜⬜⬜
// ⬜⬜⬛🟥🟥⬛⬛⬛⬛🟥🟥🟥🟥🟥🟥🟥🟥🟥⬛⬜⬜
// ⬜⬜⬛🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥🟥🟥⬛⬜⬜
// ⬜⬛🟥🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥🟥🟥⬛⬜
// ⬜⬛🟥🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥🟥⬛⬜
// ⬜⬛🟥🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥⬛⬜
// ⬜⬛🟥🟥🟥⬛⬛⬛⬛⬛🟥🟥⬛⬛⬛⬛⬛⬛🟥⬛⬜
// ⬜⬛🟥🟥🟥⬛⬛⬛⬛⬛🟥🟥⬛⬛⬛⬛⬛⬛🟥⬛⬜
// ⬜⬛🟥🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥⬛⬜
// ⬜⬛🟥🟥🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥⬛🟥⬛⬜
// ⬜⬜⬛⬛🟥🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥⬛⬛⬜⬜
// ⬜⬜⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥🟥🟥⬛⬜⬜
// ⬜⬜⬜⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥🟥🟥🟥⬛⬜⬜⬜
// ⬜⬜⬜⬜⬛🟥🟥⬛⬛⬛🟥🟥🟥🟥🟥🟥⬛⬜⬜⬜⬜
// ⬜⬜⬜⬜⬜⬛⬛🟥🟥🟥🟥🟥🟥🟥⬛⬛⬜⬜⬜⬜⬜
// ⬜⬜⬜⬜⬜⬜⬜⬛⬛⬛⬛⬛⬛⬛⬜⬜⬜⬜⬜⬜⬜
// ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
//
//             [ SOCIALS ]
// -----------------------------------
// | https://t.me/WeebPortalERC      |
// | https://weebcoin.wtf            |
// | https://twitter.com/Weebcoinerc |
// -----------------------------------

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./IUniswapRouter.sol";
import "./IUniswapFactory.sol";
import "./Restrictable.sol";
import "./IUniswapV2Pair.sol";
import "hardhat/console.sol";

contract WeebCoin is
  AccessControl,
  Restrictable,
  Pausable,
  ERC20,
  AutomationCompatible {
  using SafeMath for uint256;

  /* ===== CONSTANTS ===== */
  uint256 private constant SELL_TAX = 5;
  uint256 private constant INITIAL_SUPPLY   = 177_013_000_000_000 ether;
  uint256 private constant INITIAL_LP       = 123_909_100_000_000 ether; // INITIAL_SUPPLY.mul(70).div(100); = 70%
  uint256 public constant MAX_WALLET        =   1_770_130_000_000 ether; // INITIAL_SUPPLY.mul(1).div(200); = 0.5%
  uint256 private constant TOTAL_LP_TO_BURN =  61_954_550_000_000 ether; // INITIAL_LP.mul(50).div(100); = 50%
  uint256 public constant BURN_AMOUNT       =     123_909_100_000 ether; // INITIAL_LP.mul(1).div(1000); = 0.1%
  uint256 public constant MAX_BUY           =     885_065_000_000 ether; // MAX_WALLET.mul(50).div(100); = 50%
  uint256 public deadBlock = 0;
  bool public isIgnited;
  bool public isTaxable;
  bool public naniBaka;
  mapping(address => bool) private chanList;
  mapping(address => bool) private bakaList;

  bytes32 public constant RESTRICTER_ROLE = keccak256("RESTRICTIONS_ROLE");
  bytes32 public constant TAX_ROLE = keccak256("TAX_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant SENPAI_ROLE = keccak256("SENPAI_ROLE");
  bytes32 public constant BAKA_ROLE = keccak256("BAKA_ROLE");


  /* ===== GENERAL ===== */

  address public weth;
  address public uniswapV2Factory;
  address public uniswapV2Router;
  uint256 public totalLpBurned;
  address public uniswapV2Pair;
  address public marketingWallet;

  /* ===== EVENTS ===== */

  event BuyTransfer();
  event Nani(uint256 burnAmount, uint256 totalLpBurned);
  event TransferFee(uint256 transferAmount);
  event MarketingWalletSet(address);
  event LiquidityPairSet(address);

  constructor(
    address _uniswapV2Factory,
    address _uniswapV2Router,
    address _weth
  ) ERC20("WeebCoin", "WEEB") {
    weth = _weth;
    uniswapV2Factory = _uniswapV2Factory;
    uniswapV2Router = _uniswapV2Router;
    totalLpBurned = 0;

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(RESTRICTER_ROLE, _msgSender());
    _grantRole(TAX_ROLE, _msgSender());
    _grantRole(PAUSER_ROLE, _msgSender());
    _grantRole(MINTER_ROLE, _msgSender());
    _grantRole(SENPAI_ROLE, _msgSender());
    _grantRole(BAKA_ROLE, _msgSender());
    setAddressToChanList(_msgSender(), true);
    _setLiquidityPair(address(this));

    defuse();
    enableTax();
    enableBaka();
    _pause();
  }

  /* ===== FUNCTIONALITY ===== */

  function mintInitial(address to) public onlyRole(MINTER_ROLE) {
    _mint(to, INITIAL_SUPPLY);
    _revokeRole(MINTER_ROLE, _msgSender());
  }

  function isChan(address _address) public view returns (bool) {
    return chanList[_address];
  }

  function isBaka(address _address) public view returns (bool) {
    return bakaList[_address];
  }

  function setAddressToChanList(address _address, bool _allow) public onlyRole(SENPAI_ROLE) {
    chanList[_address] = _allow;
  }

  function setAddressToBakaList(address _address, bool _allow) public onlyRole(SENPAI_ROLE) {
    _setAddressToBakaList(_address, _allow);
  }

  function _setAddressToBakaList(address _address, bool _allow) private {
    bakaList[_address] = _allow;
  }

  function setDeadBlock(uint256 _currentBlock) public onlyRole(DEFAULT_ADMIN_ROLE) {
    deadBlock = _currentBlock + 5;
  }

  function revokeAllAccess() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _revokeRole(RESTRICTER_ROLE, _msgSender());
    _revokeRole(TAX_ROLE, _msgSender());
    _revokeRole(PAUSER_ROLE, _msgSender());
    _revokeRole(SENPAI_ROLE, _msgSender());
    _revokeRole(BAKA_ROLE, _msgSender());
  }

  function performUpkeep(bytes calldata /* performData */) external override {
    _nani();
    defuse();
  }

  function checkUpkeep(bytes calldata)
      external
      view
      override
      returns (bool upkeepNeeded, bytes memory performData) {
      return (isIgnited && totalLpBurned < TOTAL_LP_TO_BURN, "");
  }

  /* ===== MUTATIVE ===== */

  function ignite() internal {
    isIgnited = true;
  }

  function defuse() internal {
    isIgnited = false;
  }

  function enableTax() public onlyRole(TAX_ROLE) {
    isTaxable = true;
  }

  function disableTax() public onlyRole(TAX_ROLE) {
    isTaxable = false;
  }

  function enableBaka() public onlyRole(BAKA_ROLE) {
    naniBaka = true;
  }

  function disableBaka() public onlyRole(BAKA_ROLE) {
    naniBaka = false;
  }

  function restrict() public onlyRole(RESTRICTER_ROLE) {
    _restrict();
  }

  function unrestrict() public onlyRole(RESTRICTER_ROLE) {
    _unrestrict();
  }

  function pause() public onlyRole(PAUSER_ROLE) {
      _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
      _unpause();
  }

  function setMarketingWallet(address _marketingWallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_marketingWallet != address(0), "Cannot assign to zero address.");
    marketingWallet = _marketingWallet;
    emit MarketingWalletSet(marketingWallet);
  }

  function _setLiquidityPair(address _contractAddress) private {
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Factory).createPair(_contractAddress, weth);
    emit LiquidityPairSet(uniswapV2Pair);
  }

  /* ===== INTERNAL ===== */
  function _nani() internal {
    require(totalLpBurned <= TOTAL_LP_TO_BURN, "50% has been burned already.");
    require(isIgnited, "The Burn Bomb hasn't been ignited.");

    _burn(uniswapV2Pair, BURN_AMOUNT);
    totalLpBurned += BURN_AMOUNT;

    IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
    pair.sync();
    emit Nani(BURN_AMOUNT, totalLpBurned);
  }

  function _isContract(address _address) internal view returns (bool) {
    uint32 size;
    assembly {
        size := extcodesize(_address)
    }
    return (size > 0);
  }

  function _isAllowedToTransfer(address sender, address recipient) internal view returns (bool) {
    return (sender == uniswapV2Pair || recipient == address(0) || (!isBaka(recipient) && !isBaka(sender)));
  }

  function _checkIfBaka(address _address) internal view returns (bool) {
    return ( block.number < deadBlock || _isContract(_address) ) && !isChan(_address);
  }

  function _shouldBurn(address sender, address recipient, uint256 amount) internal view returns(bool){
    return totalLpBurned < TOTAL_LP_TO_BURN && sender == uniswapV2Pair && recipient != address(0) && amount != INITIAL_SUPPLY;
  }

  function _isBuyTokenTransfer(address sender, address recipient) internal view returns(bool) {
    return sender == uniswapV2Pair && recipient != address(0) && recipient != address(uniswapV2Pair);
  }

  function _isSellTokenTransfer(address recipient, uint256 amount) internal view returns(bool) {
    return recipient == uniswapV2Pair && amount != INITIAL_LP;
  }

  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    require(amount > 0, "amount must be greater than zero");
    if (_isBuyTokenTransfer(sender, recipient)) {
      if (naniBaka && _checkIfBaka(recipient) && !isBaka(recipient)) {
        _setAddressToBakaList(recipient, true);
      }
      require(!paused() || isChan(recipient), "Token transfer while paused");
      if (restricted()) {
        require(amount <= MAX_BUY, "amount exceeds maxTransaction");
        require(balanceOf(recipient).add(amount) <= MAX_WALLET, "Max wallet exceeded");
      }
    }

    uint256 fee = 0;
    if (_isSellTokenTransfer(recipient, amount)) {
      if (isTaxable || isBaka(sender)) {
        require(marketingWallet != address(0), "Marketing Wallet cannot be zero address");
        fee = amount.mul(SELL_TAX).div(100);
        super._transfer(sender, marketingWallet, fee);
      }
      require(!isBaka(sender), "Sender is in the disallow list");
    }

    require(_isAllowedToTransfer(sender, recipient), "Baka!");
    require(!paused() || isChan(sender) || isChan(recipient) || sender == address(0), "paused" );
    super._beforeTokenTransfer(sender, recipient, amount.sub(fee));
  }

  function _afterTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    if (_shouldBurn(sender, recipient, amount)) {
      ignite();
      emit BuyTransfer();
    }
    super._afterTokenTransfer(sender, recipient, amount);
  }
}