// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Storage.sol";
import "./dex/IPair.sol";
import "./dex/IRouter.sol";
import "./IWrap.sol";

contract LPTokensManager is Ownable {
  using SafeERC20 for IERC20;

  /// @notice Storage contract
  Storage public info;

  struct Swap {
    address[] path;
    uint256 outMin;
  }

  event StorageChanged(address indexed info);

  constructor(address _info) {
    require(_info != address(0), "LPTokensManager::constructor: invalid storage contract address");
    info = Storage(_info);
  }

  receive() external payable {}

  fallback() external payable {}

  /**
   * @notice Change storage contract address.
   * @param _info New storage contract address.
   */
  function changeStorage(address _info) external onlyOwner {
    require(_info != address(0), "LPTokensManager::changeStorage: invalid storage contract address");
    info = Storage(_info);
    emit StorageChanged(_info);
  }

  function _swap(
    address router,
    uint256 amount,
    uint256 outMin,
    address[] memory path,
    uint256 deadline
  ) internal {
    if (path[0] == path[path.length - 1]) return;

    IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amount,
      outMin,
      path,
      address(this),
      deadline
    );
  }

  /**
   * @return Current call commission.
   */
  function fee() public view returns (uint256) {
    uint256 feeUSD = info.getUint(keccak256("DFH:Fee:Automate:LPTokensManager"));
    if (feeUSD == 0) return 0;

    (, int256 answer, , , ) = AggregatorV3Interface(info.getAddress(keccak256("DFH:Fee:PriceFeed"))).latestRoundData();
    require(answer > 0, "LPTokensManager::fee: invalid price feed response");

    return (feeUSD * 1e18) / uint256(answer);
  }

  function _payCommission() internal {
    uint256 payFee = fee();
    if (payFee == 0) return;
    require(msg.value >= payFee, "LPTokensManager::_payCommission: insufficient funds to pay commission");
    address treasury = info.getAddress(keccak256("DFH:Contract:Treasury"));
    require(treasury != address(0), "LPTokensManager::_payCommission: invalid treasury contract address");

    // solhint-disable-next-line avoid-low-level-calls
    (bool sentTreasury, ) = payable(treasury).call{value: payFee}("");
    require(sentTreasury, "LPTokensManager::_payCommission: transfer fee to the treasury failed");
    if (msg.value > payFee) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool sentRemained, ) = payable(msg.sender).call{value: msg.value - payFee}("");
      require(sentRemained, "LPTokensManager::_payCommission: transfer of remained tokens to the sender failed");
    }
  }

  function _returnRemainder(address[3] memory tokens) internal {
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == address(0)) continue;
      uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
      if (tokenBalance > 0) {
        IERC20(tokens[i]).safeTransfer(msg.sender, tokenBalance);
      }
    }
  }

  function _approve(
    IERC20 token,
    address spender,
    uint256 amount
  ) internal {
    if (token.allowance(address(this), spender) != 0) {
      token.safeApprove(spender, 0);
    }
    token.safeApprove(spender, amount);
  }

  function _buyLiquidity(
    uint256 amount,
    address router,
    Swap memory swap0,
    Swap memory swap1,
    IPair to,
    uint256 deadline
  ) internal returns (address token0, address token1) {
    require(
      info.getBool(keccak256(abi.encodePacked("DFH:Contract:LPTokensManager:allowedRouter:", router))),
      "LPTokensManager::_buyLiquidity: invalid router address"
    );
    require(swap0.path[0] == swap1.path[0], "LPTokensManager::_buyLiqudity: start token not equals");

    // Get tokens in
    token0 = to.token0();
    require(swap0.path[swap0.path.length - 1] == token0, "LPTokensManager::_buyLiqudity: invalid token0");
    token1 = to.token1();
    require(swap1.path[swap1.path.length - 1] == token1, "LPTokensManager::_buyLiqudity: invalid token1");

    // Swap tokens
    _approve(IERC20(swap0.path[0]), router, amount);
    uint256 amount0In = amount / 2;
    _swap(router, amount0In, swap0.outMin, swap0.path, deadline);
    uint256 amount1In = amount - amount0In;
    _swap(router, amount1In, swap1.outMin, swap1.path, deadline);

    // Add liquidity
    amount0In = IERC20(token0).balanceOf(address(this));
    amount1In = IERC20(token1).balanceOf(address(this));
    _approve(IERC20(token0), router, amount0In);
    _approve(IERC20(token1), router, amount1In);
    IRouter(router).addLiquidity(token0, token1, amount0In, amount1In, 0, 0, msg.sender, deadline);
  }

  function buyLiquidity(
    uint256 amount,
    address router,
    Swap memory swap0,
    Swap memory swap1,
    IPair to,
    uint256 deadline
  ) public payable {
    _payCommission();
    IERC20(swap0.path[0]).safeTransferFrom(msg.sender, address(this), amount);
    (address token0, address token1) = _buyLiquidity(amount, router, swap0, swap1, to, deadline);
    _returnRemainder([token0, token1, swap0.path[0]]);
  }

  function buyLiquidityETH(
    address router,
    Swap memory swap0,
    Swap memory swap1,
    IPair to,
    uint256 deadline
  ) external payable {
    uint256 amountIn = msg.value;

    uint256 payFee = fee();
    if (payFee > 0) {
      amountIn -= payFee;
      address treasury = info.getAddress(keccak256("DFH:Contract:Treasury"));
      require(treasury != address(0), "LPTokensManager::buyLiquidityETH: invalid treasury contract address");
      // solhint-disable-next-line avoid-low-level-calls
      (bool sentTreasury, ) = payable(treasury).call{value: payFee}("");
      require(sentTreasury, "LPTokensManager::buyLiquidityETH: transfer fee to the treasury failed");
    }

    IWrap wrapper = IWrap(info.getAddress(keccak256("NativeWrapper:Contract")));
    wrapper.deposit{value: amountIn}();

    (address token0, address token1) = _buyLiquidity(amountIn, router, swap0, swap1, to, deadline);
    _returnRemainder([token0, token1, swap0.path[0]]);
  }

  function _sellLiquidity(
    uint256 amount,
    address router,
    Swap memory swap0,
    Swap memory swap1,
    IPair from,
    uint256 deadline
  ) internal returns (address token0, address token1) {
    require(
      info.getBool(keccak256(abi.encodePacked("DFH:Contract:LPTokensManager:allowedRouter:", router))),
      "LPTokensManager::sellLiquidity: invalid router address"
    );
    require(
      swap0.path[swap0.path.length - 1] == swap1.path[swap1.path.length - 1],
      "LPTokensManager::sellLiqudity: end token not equals"
    );

    // Get tokens in
    token0 = from.token0();
    require(swap0.path[0] == token0, "LPTokensManager::sellLiqudity: invalid token0");
    token1 = from.token1();
    require(swap1.path[0] == token1, "LPTokensManager::sellLiqudity: invalid token1");

    // Remove liquidity
    _approve(IERC20(from), router, amount);
    IRouter(router).removeLiquidity(token0, token1, amount, 0, 0, address(this), deadline);

    // Swap tokens
    uint256 amount0In = IERC20(token0).balanceOf(address(this));
    _approve(IERC20(token0), router, amount0In);
    _swap(router, amount0In, swap0.outMin, swap0.path, deadline);
    uint256 amount1In = IERC20(token1).balanceOf(address(this));
    _approve(IERC20(token1), router, amount1In);
    _swap(router, amount1In, swap1.outMin, swap1.path, deadline);
  }

  function sellLiquidity(
    uint256 amount,
    address router,
    Swap memory swap0,
    Swap memory swap1,
    IPair from,
    uint256 deadline
  ) external payable {
    _payCommission();
    IERC20(from).safeTransferFrom(msg.sender, address(this), amount);
    (address token0, address token1) = _sellLiquidity(amount, router, swap0, swap1, from, deadline);
    _returnRemainder([token0, token1, swap0.path[swap0.path.length - 1]]);
  }

  function sellLiquidityETH(
    uint256 amount,
    address router,
    Swap memory swap0,
    Swap memory swap1,
    IPair from,
    uint256 deadline
  ) external payable {
    _payCommission();
    IERC20(from).safeTransferFrom(msg.sender, address(this), amount);
    (address token0, address token1) = _sellLiquidity(amount, router, swap0, swap1, from, deadline);

    IWrap wrapper = IWrap(info.getAddress(keccak256("NativeWrapper:Contract")));
    wrapper.withdraw(wrapper.balanceOf(address(this)));

    // solhint-disable-next-line avoid-low-level-calls
    (bool sentRecipient, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(sentRecipient, "LPTokensManager::sellLiquidityETH: transfer ETH to recipeint failed");
    _returnRemainder([token0, token1, swap0.path[swap0.path.length - 1]]);
  }
}