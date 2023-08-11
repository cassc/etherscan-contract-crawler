//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

abstract contract TW33TPausable is ERC20, Pausable {
  mapping (address => bool) _pauseWhitelist;

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(_pauseWhitelist[from] || !paused(), "TW33TPausable: token transfer is paused");
  }
}

contract TW33T is TW33TPausable, AccessControl {
  using SafeMath for uint256;
  using Address for address;

  bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
  bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

  IUniswapV2Router02 private router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address private weth = router.WETH();
  IUniswapV2Factory private factory = IUniswapV2Factory(router.factory());

  // addresses in fee whitelist aren't taxed
  mapping (address => bool) public feeWhitelist;
  // feeAmount is fee% * 100
  uint256 public feeAmount;
  // currently max fee is 66.6%
  uint256 constant public maxFee = 66.6 * 100;
  // burnAmount is amount of the fee that will be burnt
  uint256 constant public burnAmount = 50 * 100;
  // feeTo is address that will receive fees
  address public feeTo;
  // launchTime contains time of the uniswap launch
  uint256 public launchTime;
  // launchBlock contains block of the uniswap launch
  uint256 public launchBlock;

  constructor(address liquidity, address marketing, address feeAddr, address team) ERC20("TW33T Token", "TW33T") {
    // mint all of the supply right away
    // supply needed for liquidity
    _mint(liquidity, 333333 * (10 ** 18));
    _mint(liquidity, 199999.8 * (10 ** 18));

    _mint(marketing, 99999.9 * (10 ** 18));
    _mint(team, 33333.3 * (10 ** 18));

    feeTo = feeAddr;
    feeAmount = maxFee;
    // grant token owner admin rights
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DISTRIBUTOR_ROLE, liquidity);
    _pauseWhitelist[liquidity] = true;
    // not sure if we need this
    _pauseWhitelist[msg.sender] = true;
    // pause the token right away, since we don't want any of them to wander off
    _pause();
  }

  function whitelist(address target, bool status) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DISTRIBUTOR_ROLE, msg.sender), "Whitelist: only admin or distributor can change whitelist status");
    feeWhitelist[target] = status;
  }

  // after the unpause, token cannot be paused back
  function unpause() public {
    require(hasRole(DISTRIBUTOR_ROLE, msg.sender), "Unpause: only distributor can unpause");
    launchTime = block.timestamp;
    launchBlock = block.number;
    _unpause();
  }

  function setFeeAddr(address feeAddr) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "FeeAddr: only admin can change fee address");
    feeTo = feeAddr;
  }

  function setFee(uint256 fee) public {
    require(hasRole(FEE_SETTER_ROLE, msg.sender), "Fee: only fee_setter can change fee");
    require(fee <= maxFee, "Fee: fee exceeds max fee");
    feeAmount = fee;
  }

  function calculateFee(uint256 amount) public view returns (uint256) {
    // if this fails, you're transferring too much
    // will never overflow with current total supply
    return amount.mul(feeAmount).div(10000);
  }

  function calculateBurn(uint256 amount) public pure returns (uint256) {
    return amount.mul(burnAmount).div(10000);
  }

  function canBuy(address sender, address recipient, uint256 amount) internal view returns (bool) {
    // buy limitations are over
    if(block.timestamp >= launchTime + 10 minutes) {
      return true;
    }
    IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(this), weth));
    // not a buy at all, doesn't matter
    if(sender != address(pair)) {
      return true;
    }
    // too soon, buying is blocked
    if(block.number < launchBlock + 2) {
      return false;
    }
    (uint reserve0, uint reserve1,) = pair.getReserves();
    (reserve0, reserve1) = pair.token0() == weth ? (reserve1, reserve0) : (reserve0, reserve1);
    uint price = router.getAmountIn(amount, reserve1, reserve0);
    //     recipient is not a contract, contracts can't buy in first 10 minutes
    return !recipient.isContract() && (price <= 10 ether);
  }

  modifier canBuyTokens(address sender, address recipient, uint256 amount) {
    require(canBuy(sender, recipient, amount), "Buy rules violation");
    _;
  }

  function transfer(address recipient, uint256 amount) public override canBuyTokens(msg.sender, recipient, amount) returns (bool) {
    if(feeWhitelist[_msgSender()]) {
      _transfer(_msgSender(), recipient, amount);
    } else {
      uint256 fee = calculateFee(amount);
      uint256 amountWithoutFee = amount.sub(fee);
      _transfer(_msgSender(), recipient, amountWithoutFee);
      uint256 burn = calculateBurn(fee);
      _burn(_msgSender(), burn);
      uint256 feeWithoutBurn = fee.sub(burn);
      _transfer(_msgSender(), feeTo, feeWithoutBurn);
    }
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override canBuyTokens(sender, recipient, amount) returns (bool) {
    if(feeWhitelist[sender]) {
      _transfer(sender, recipient, amount);
      _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
    } else {
      uint256 fee = calculateFee(amount);
      // prevent stack too deep error
      {
        uint256 amountWithoutFee = amount.sub(fee);
        _transfer(sender, recipient, amountWithoutFee);
      }
      // one more stack too deep error
      {
        uint256 burn = calculateBurn(fee);
        _burn(sender, burn);
        uint256 feeWithoutBurn = fee.sub(burn);
        _transfer(sender, feeTo, feeWithoutBurn);
      }
      _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
    }
    return true;
  }
}