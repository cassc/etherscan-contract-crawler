// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IUniswapV2Exchange.sol";

contract Aggregator {
  using SafeMath for uint256;
  using UniswapV2ExchangeLib for IUniswapV2Exchange;
  address public owner;
  
  IERC20 internal weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  IERC20 internal target = IERC20(0x87DE305311D5788e8da38D19bb427645b09CB4e5);

  IUniswapV2Exchange internal exchange = IUniswapV2Exchange(0xbc159C4fF09A134eE7d47dF92C1BE4f3cA136F53);

  uint private unlocked = 1;

  modifier lock() {
    require(unlocked == 1, 'aggregator: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  modifier admin() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function setTarget(address _target) public lock admin {
    target = IERC20(_target);
  }

  function setExchange(address _exchange) public lock admin {
    exchange = IUniswapV2Exchange(_exchange);
  }

  function changeOwner(address _owner) public lock admin {
    owner = _owner;
  }

  function swap(
    uint256 cnt,
    uint256 amount,
    uint256 minReturn
  ) public lock admin returns(uint256 returnAmount) {
    // send token 0 from user to this contract
    weth.transferFrom(msg.sender, address(this), amount);
    for (uint i = 0; i < cnt; i++) {
      uint256 swapAmount = weth.balanceOf(address(this));
      swapOnUniswap(weth, target, swapAmount);
      swapAmount = target.balanceOf(address(this));
      swapOnUniswap(target, weth, swapAmount);
    }
    returnAmount = weth.balanceOf(address(this));
    require(returnAmount >= minReturn, "actual return amount is less than minReturn");
    weth.transfer(msg.sender, returnAmount);
  }

  function swapOnUniswap (
    IERC20 fromToken,
    IERC20 toToken,
    uint256 amount
  ) internal {
    uint256 returnAmount;
    bool needSync;
    bool needSkim;
    (returnAmount, needSync, needSkim) = exchange.getReturn(fromToken, toToken, amount);
    if (needSync) {
      exchange.sync();
    } else if (needSkim) {
      exchange.skim(owner);
    }

    fromToken.transfer(address(exchange), amount);
    if (address(fromToken) < address(toToken)) {
      exchange.swap(0, returnAmount, address(this), "");
    } else {
      exchange.swap(returnAmount, 0, address(this), "");
    }
  }
}