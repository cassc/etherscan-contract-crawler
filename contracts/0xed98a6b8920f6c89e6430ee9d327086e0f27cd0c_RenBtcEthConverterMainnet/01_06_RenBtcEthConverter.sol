// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/CurvePools/ICurveInt128.sol";
import "../interfaces/IWETH.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract RenBtcEthConverterMainnet {
  ICurveInt128 rencrv = ICurveInt128(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
  address constant renbtc = address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
  address constant wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  uint256 constant MaxUintApprove = type(uint256).max;

  constructor() {}

  function initialize() public {
    bool success;
    (success, ) = renbtc.call(abi.encodeWithSelector(IERC20.approve.selector, address(rencrv), MaxUintApprove));
    require(success, "!renbtc");
    (success, ) = wbtc.call(abi.encodeWithSelector(IERC20.approve.selector, address(router), MaxUintApprove));
    require(success, "!wbtc");
    (success, ) = weth.call(abi.encodeWithSelector(IERC20.approve.selector, address(router), MaxUintApprove));
    require(success, "!weth");
  }

  function convertToEth(uint256 minOut) public returns (uint256 amount) {
    uint256 wbtcAmount = IERC20(wbtc).balanceOf(address(this));
    //minout encoded to 1 because of intermediate call
    (bool success, ) = address(rencrv).call(
      abi.encodeWithSelector(rencrv.exchange.selector, 0, 1, IERC20(renbtc).balanceOf(address(this)), 1)
    );
    require(success, "!curve");
    wbtcAmount = IERC20(wbtc).balanceOf(address(this)) - wbtcAmount;
    bytes memory path = abi.encodePacked(wbtc, uint24(500), weth);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: wbtcAmount,
      amountOutMinimum: minOut,
      path: path
    });
    amount = router.exactInput(params);
    IWETH(weth).withdraw(amount);
    address payable sender = payable(msg.sender);
    sender.transfer(amount);
  }

  receive() external payable {
    // no-op
  }
}