// SPDX-License-Identifier: MIT

//
//             [ SOCIALS ]
// -----------------------------------
// | https://t.me/WeebPortalERC      |
// | https://weebcoin.wtf            |
// | https://twitter.com/Weebcoinerc |
// -----------------------------------

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract Weeb is Ownable, Pausable, ERC20, ERC20Burnable, AutomationCompatible {


  /* ===== CONSTANTS ===== */
  uint256 private constant TOTAL_SUPPLY   = 177_013_000_000_000 ether;
  uint256 private constant TOTAL_LP_TO_BURN =  61_954_550_000_000 ether; // INITIAL_LP.mul(50).div(100); = 50%
  uint256 public constant BURN_AMOUNT       =   1_239_091_000_000 ether; // INITIAL_LP.mul(1).div(1000); = 0.1%

  mapping(address => bool) private chanList;
  mapping(address => bool) private bakaList;
  mapping(address => bool) private _pools;
  mapping(address => uint) private _lastBuyTransfer;
  mapping(address => uint) private _lastSellTransfer;


  /* ===== GENERAL ===== */
  bool public isIgnited;
  uint256 public totalLpBurned;
  address public _uniswapV2Pair;
  address private keeperRegistryAddress;
  uint256 private deadBlock;
  bool private _unrestricted;
  bool private _naniBaka;

  /* ===== EVENTS ===== */

  event BuyTransfer();
  event Nani(uint256 burnAmount, uint256 totalLpBurned);
  event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);

  error NoZeroTransfers();
  error NotAllowed();
  error ContractPaused();
  error OnlyKeeperRegistry();

  constructor(
    IUniswapV2Factory _V2Factory,
    address _weth
  ) ERC20("Weeb", "WEEB") {

    chanList[msg.sender] = true;
    _mint(msg.sender, TOTAL_SUPPLY);

    totalLpBurned = 0;
    deadBlock = 0;

    isIgnited = false;
    _naniBaka = true;
    _unrestricted = false;
    _pause();

    _uniswapV2Pair = IUniswapV2Factory(_V2Factory).createPair(address(this), _weth);
  }

  /* ===== FUNCTIONALITY ===== */

  function setPool(address _val, bool _allow) external onlyOwner {
    _pools[_val] = _allow;
  }

  function ignite() internal {
    isIgnited = true;
  }

  function defuse() internal {
    isIgnited = false;
  }

  function enableBaka() public onlyOwner {
    _naniBaka = true;
  }

  function disableBaka() public onlyOwner {
    _naniBaka = false;
  }

  function restrict() public onlyOwner {
    _unrestricted = false;
  }

  function unrestrict() public onlyOwner {
    _unrestricted = true;
  }

  function pause() public onlyOwner {
      _pause();
  }

  function unpause() public onlyOwner {
    deadBlock = block.number + 5;
    _unpause();
  }

  /* ===== CHAINLINK ===== */

  modifier onlyKeeperRegistry() {
    require(msg.sender == keeperRegistryAddress, "Sender is not Keeper");
    _;
  }

  function setKeeperRegistryAddress(
    address _keeperRegistryAddress
  ) public onlyOwner {
    require(_keeperRegistryAddress != address(0), "Address cannot be zero address");
    emit KeeperRegistryAddressUpdated(
        keeperRegistryAddress,
        _keeperRegistryAddress
    );
    keeperRegistryAddress = _keeperRegistryAddress;
  }

  function getKeeperRegistryAddress()
    external
    view
    returns (address _keeperRegistryAddress)
  {
    return keeperRegistryAddress;
  }

  function performUpkeep(bytes calldata /* performData */) external override onlyKeeperRegistry {
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

  function senpaiBurn() external onlyOwner {
    _nani();
  }

  function _nani() internal {
    require(totalLpBurned <= TOTAL_LP_TO_BURN, "50% has been burned already.");
    require(isIgnited, "The Burn Bomb hasn't been ignited.");

    _burn(_uniswapV2Pair, BURN_AMOUNT);
    totalLpBurned += BURN_AMOUNT;

    IUniswapV2Pair pair = IUniswapV2Pair(_uniswapV2Pair);
    pair.sync();
    emit Nani(BURN_AMOUNT, totalLpBurned);
  }

  function _shouldBurn(address sender, address recipient, uint256 amount) internal view returns(bool){
    return totalLpBurned < TOTAL_LP_TO_BURN && _pools[sender] && recipient != address(0) && amount != TOTAL_SUPPLY;
  }

  /* ===== FUCK BOTS ===== */

  function _isContract(address _address) internal view returns (bool) {
    uint32 size;
    assembly {
        size := extcodesize(_address)
    }
    return (size > 0);
  }

  function _isAllowedToTransfer(address sender, address recipient) internal view returns (bool) {
    return (_pools[sender] || recipient == address(0) || (!bakaList[recipient] && !bakaList[sender]));
  }

  function _checkIfBaka(address _address) internal view returns (bool) {
    return ( block.number < deadBlock || _isContract(_address) ) && !chanList[_address];
  }

  /* ===== TRANSFER OVERRIDE ===== */

  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    if (amount == 0) { revert NoZeroTransfers(); }
    if (_unrestricted) { return; }
    if (paused() && (!chanList[recipient] || !chanList[sender])) { revert ContractPaused(); }

    if (_pools[sender]) {
      if (_naniBaka && _checkIfBaka(recipient) && !bakaList[sender]) {
        bakaList[recipient] = true;
      }
      if (block.number == _lastSellTransfer[recipient]) { revert NotAllowed(); }
      _lastBuyTransfer[recipient] = block.number;
    }

    if (_pools[recipient]) {
      if (bakaList[sender]) { revert NotAllowed(); }
      if (block.number == _lastBuyTransfer[sender]) { revert NotAllowed(); }
      _lastSellTransfer[sender] = block.number;
    }

    if (!_isAllowedToTransfer(sender, recipient)) { revert NotAllowed(); }

    super._beforeTokenTransfer(sender, recipient, amount);
  }

  function _afterTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    if (_shouldBurn(sender, recipient, amount)) {
      ignite();
      emit BuyTransfer();
    }
    super._afterTokenTransfer(sender, recipient, amount);
  }
}