// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IWETH.sol";
import "./interfaces/ISmartRouter.sol";
import "./interfaces/ISwapRouter02.sol";
import "./interfaces/IUniswapV2.sol";

import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";

contract SwapPlusv1 is Ownable {
  using SafeERC20 for IERC20;

  struct swapRouter {
    string platform;
    address tokenIn;
    address tokenOut;
    uint256 amountOutMin;
    uint256 meta; // fee, flag(stable), 0=v2
    uint256 percent;
  }
  struct swapLine {
    swapRouter[] swaps;
  }
  struct swapBlock {
    swapLine[] lines;
  }

  address public WETH;
  address public treasury;
  uint256 public swapFee = 3000;
  uint256 public managerDecimal = 1000000;
  mapping (address => bool) public noFeeWallets;
  mapping (address => bool) public managers;

  mapping(string => address) public routers;

  event SwapPlus(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountUsed, uint256 amountOut);

  constructor(
    address _WETH,
    address _treasury
  ) {
    routers["UniswapV3"] = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    routers["UniswapV2"] = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    routers["Sushiswap"] = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    routers["PancakeV3"] = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    routers["PancakeStable"] = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    routers["PancakeV2"] = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;

    WETH = _WETH;
    treasury = _treasury;
    managers[msg.sender] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LC swap+: !manager");
    _;
  }

  receive() external payable {
  }

  function swap(address tokenIn, uint256 amount, address tokenOut, address recipient, swapBlock[] calldata swBlocks) public payable returns(uint256, uint256) {
    if (tokenIn != address(0)) {
      IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
    }
    uint256 usedAmount = amount;
    if (noFeeWallets[msg.sender] == false) {
      usedAmount = _cutFee(tokenIn, usedAmount);
    }

    if (tokenIn == address(0)) {
      IWETH(WETH).deposit{value: usedAmount}();
    }

    uint256 blockLen = swBlocks.length;
    uint256 inAmount = usedAmount;
    uint256 outAmount = 0;
    for (uint256 x=0; x<blockLen; x++) {
      uint256 lineLen = swBlocks[x].lines.length;
      outAmount = 0;
      for (uint256 y=0; y<lineLen; y++) {
        outAmount += _swap(swBlocks[x].lines[y], inAmount);
      }
      inAmount = outAmount;
    }

    if (tokenOut == address(0)) {
      IWETH(WETH).withdraw(outAmount);
      (bool success, ) = payable(recipient).call{value: outAmount}("");
      require(success, "LC swap+: Failed receipt");
    }
    else {
      IERC20(tokenOut).safeTransfer(recipient, outAmount);
    }

    emit SwapPlus(tokenIn, tokenOut, amount, usedAmount, outAmount);

    return (usedAmount, outAmount);
  }

  function _swap(swapLine memory line, uint256 amount) internal returns(uint256) {
    uint256 swLen = line.swaps.length;
    uint256 inAmount = amount;
    uint256 outAmount = 0;
    for (uint256 x=0; x<swLen; x++) {
      _approveTokenIfNeeded(line.swaps[x].tokenIn, routers[line.swaps[x].platform], inAmount);
      if (_compareStrings(line.swaps[x].platform, "PancakeV3")) {
        ISmartRouter.ExactInputSingleParams memory pm = ISmartRouter.ExactInputSingleParams({
          tokenIn: line.swaps[x].tokenIn,
          tokenOut: line.swaps[x].tokenOut,
          fee: uint24(line.swaps[x].meta),
          recipient: address(this),
          amountIn: inAmount * line.swaps[x].percent / managerDecimal,
          amountOutMinimum: line.swaps[x].amountOutMin,
          sqrtPriceLimitX96: 0
        });
        outAmount = ISmartRouter(routers["PancakeV3"]).exactInputSingle{value:0}(pm);
      }
      else if (_compareStrings(line.swaps[x].platform, "PancakeStable")) {
        address[] memory path = new address[](2);
        path[0] = line.swaps[x].tokenIn;
        path[1] = line.swaps[x].tokenOut;
        uint256[] memory flag = new uint256[](1);
        flag[0] = line.swaps[x].meta;
        outAmount = ISmartRouter(routers["PancakeStable"]).exactInputStableSwap{value:0}(
          path, flag, inAmount * line.swaps[x].percent / managerDecimal, line.swaps[x].amountOutMin, address(this)
        );
      }
      else if (_compareStrings(line.swaps[x].platform, "PancakeV2")) {
        address[] memory path = new address[](2);
        path[0] = line.swaps[x].tokenIn;
        path[1] = line.swaps[x].tokenOut;
        outAmount = ISmartRouter(routers["PancakeV2"]).swapExactTokensForTokens{value:0}(
          inAmount * line.swaps[x].percent / managerDecimal, line.swaps[x].amountOutMin, path, address(this)
        );
      }
      else if (_compareStrings(line.swaps[x].platform, "UniswapV3")) {
        ISwapRouter02.ExactInputSingleParams memory pm = ISwapRouter02.ExactInputSingleParams({
          tokenIn: line.swaps[x].tokenIn,
          tokenOut: line.swaps[x].tokenOut,
          fee: uint24(line.swaps[x].meta),
          recipient: address(this),
          amountIn: inAmount * line.swaps[x].percent / managerDecimal,
          amountOutMinimum: line.swaps[x].amountOutMin,
          sqrtPriceLimitX96: 0
        });
        outAmount = ISwapRouter02(routers["UniswapV3"]).exactInputSingle{value:0}(pm);
      }
      else if (_compareStrings(line.swaps[x].platform, "UniswapV2")) {
        address[] memory path = new address[](2);
        path[0] = line.swaps[x].tokenIn;
        path[1] = line.swaps[x].tokenOut;
        outAmount = ISwapRouter02(routers["UniswapV2"]).swapExactTokensForTokens{value:0}(
          inAmount * line.swaps[x].percent / managerDecimal, line.swaps[x].amountOutMin, path, address(this)
        );
      }
      else if (routers[line.swaps[x].platform] != address(0)) {
        address[] memory path = new address[](2);
        path[0] = line.swaps[x].tokenIn;
        path[1] = line.swaps[x].tokenOut;
        uint256[] memory amounts = IUniswapV2(routers[line.swaps[x].platform]).swapExactTokensForTokens(
          inAmount * line.swaps[x].percent / managerDecimal,
          line.swaps[x].amountOutMin,
          path,
          address(this),
          block.timestamp
        );
        outAmount = amounts[amounts.length - 1];
      }
      inAmount = outAmount;
    }
    return outAmount;
  }

  function _cutFee(address token, uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * swapFee / managerDecimal;
      if (fee > 0) {
        if (token == address(0)) {
          (bool success, ) = payable(treasury).call{value: fee}("");
          require(success, "LC swap+: Failed cut fee");
        }
        else {
          IERC20(token).safeTransfer(treasury, fee);
        }
      }
      return _amount - fee;
    }
    return 0;
  }

  function _approveTokenIfNeeded(address token, address spender, uint256 amount) private {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).approve(spender, 0);
      IERC20(token).approve(spender, type(uint256).max);
    }
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setNoFeeWallets(address account, bool access) public onlyManager {
    noFeeWallets[account] = access;
  }

  function setSwapFee(uint256 _swapFee) public onlyManager {
    swapFee = _swapFee;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }

  function addUniv2Router(string memory _platform, address _router) public onlyManager {
    routers[_platform] = _router;
  }

  function withdraw(address token, uint256 amount) public onlyManager {
    if (token == address(0)) {
      if (amount > address(this).balance) {
        amount = address(this).balance;
      }
      if (amount > 0) {
        (bool success1, ) = msg.sender.call{value: amount}("");
        require(success1, "LC swap+: Failed revoke");
      }
    }
    else {
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (amount > balance) {
        amount = balance;
      }
      if (amount > 0) {
        IERC20(token).safeTransfer(msg.sender, amount);
      }
    }
  }

  function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
}