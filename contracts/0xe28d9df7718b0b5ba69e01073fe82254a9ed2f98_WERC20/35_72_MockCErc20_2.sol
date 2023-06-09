pragma solidity 0.6.12;

// import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import '../../interfaces/ICErc20_2.sol';

contract MockCErc20_2 is ICErc20_2 {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  IERC20 public token;
  uint public mintRate = 1e18;
  uint public totalSupply = 0;
  mapping(address => uint) public override balanceOf;

  constructor(IERC20 _token) public {
    token = _token;
  }

  function setMintRate(uint _mintRate) external override {
    mintRate = _mintRate;
  }

  function underlying() external override returns (address) {
    return address(token);
  }

  function mint(uint mintAmount) external override returns (uint) {
    uint amountIn = mintAmount.mul(mintRate).div(1e18);
    IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
    totalSupply = totalSupply.add(mintAmount);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(mintAmount);
    return 0;
  }

  function redeem(uint redeemAmount) external override returns (uint) {
    uint amountOut = redeemAmount.mul(1e18).div(mintRate);
    IERC20(token).safeTransfer(msg.sender, amountOut);
    totalSupply = totalSupply.sub(redeemAmount);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(redeemAmount);
    return 0;
  }
}