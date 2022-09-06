// SPDX-License-identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/IWETH.sol";
import "../interfaces/IPCAEthPool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {ERC20PausableUpgradeable as PauseableERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20PausableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable as NonReentrant} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract PCAEthPool is IPCAEthPool, Initializable, Ownable, PauseableERC20, NonReentrant {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  ILiquidityEthPool public pool;
  ERC20 public weth;

  //@custom:oz-upgrades-unsafe-allow constructor 
  //solhint-disable-next-line no-empty-blocks
  constructor() public initializer {}

  function initialize(
    ILiquidityEthPool _pool,
    string memory _name,
    string memory _symbol
  ) external initializer {
    require(address(_pool) != address(0), "ZERO_ADDRESS");

    __Context_init_unchained();
    __Ownable_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();
    __ERC20_init_unchained(_name, _symbol);
    __ERC20Pausable_init_unchained();

    pool = _pool;
    weth = ERC20(pool.underlyer());
    require(address(weth) != address(0), "POOL_DNE");
  }

  ///@dev Handles funds in case of direct ether tx
  receive() external payable {
    depositAsset(msg.sender, 0);
  }

  function decimals() public view override returns (uint8) {
    return weth.decimals();
  }

  function depositAsset(address account, uint256 amount) public payable override whenNotPaused {
    uint256 value = msg.value;
    require(account != address(0), "INVALID_ADDRESS");
    require(amount > 0 || value > 0, "INVALID_AMOUNT");
    _mint(account, amount.add(value));
    if (amount > 0) {
      weth.safeTransferFrom(msg.sender, address(pool), amount);
    }
    _etherCheckAndTransfer(value);
  }

  function depositPoolAsset(address account, uint256 amount) external payable override whenNotPaused {
    uint256 value = msg.value;
    require(account != address(0), "INVALID_ADDRESS");
    require(amount > 0 || value > 0, "INVALID_AMOUNT");
    _mint(account, amount.add(value));
    if (amount > 0) {
      pool.controlledBurn(amount, msg.sender);
    }
    _etherCheckAndTransfer(value);
  }

  function updatePool(ILiquidityEthPool newPool) external override onlyOwner {
    address poolAddress = address(newPool);
    require(poolAddress != address(0), "INVALID_ADDRESS");
    require(address(newPool.underlyer()) == address(weth), "UNDERLYER_MISMATCH");
    pool = newPool;

    emit PoolUpdated(poolAddress);
  }

  function pause() external override onlyOwner {
    _pause();
  }

  function unpause() external override onlyOwner {
    _unpause();
  }

  function _etherCheckAndTransfer(uint256 value) private nonReentrant {
    if(value > 0) {
      IWETH(address(weth)).deposit{value: value}();
      weth.safeTransfer(address(pool), value);
    }
  }
}