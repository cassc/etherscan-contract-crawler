// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";

contract ZeroUniswapFactory {
  address public immutable router;

  event CreateWrapper(address _wrapper);

  constructor(address _router) {
    router = _router;
  }

  function createWrapper(address[] memory _path) public {
    ZeroUniswapWrapper wrapper = new ZeroUniswapWrapper(router, _path);
    emit CreateWrapper(address(wrapper));
  }
}

library AddressSliceLib {
  function slice(
    address[] memory ary,
    uint256 start,
    uint256 end
  ) internal pure returns (address[] memory result) {
    uint256 length = end - start;
    result = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      result[i] = ary[i + start];
    }
  }

  function slice(address[] memory ary, uint256 start) internal pure returns (address[] memory result) {
    result = slice(ary, start, ary.length);
  }
}

contract ZeroUniswapWrapper {
  address[] public path;
  address public immutable router;

  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using AddressSliceLib for address[];

  constructor(address _router, address[] memory _path) {
    router = _router;
    path = _path;
    IERC20(_path[0]).safeApprove(address(_router), type(uint256).max);
  }

  function estimate(uint256 _amount) public view returns (uint256) {
    if (path[0] == address(0x0)) {
      return IUniswapV2Router02(router).getAmountsOut(_amount, path.slice(1))[path.length - 2];
    } else if (path[path.length - 1] == address(0x0)) {
      return IUniswapV2Router02(router).getAmountsOut(_amount, path.slice(0, path.length - 1))[path.length - 2];
    } else {
      return IUniswapV2Router02(router).getAmountsOut(_amount, path)[path.length - 1];
    }
  }

  function convert(address _module) external payable returns (uint256) {
    // Then the input and output tokens are both ERC20
    uint256 _balance = IERC20(path[0]).balanceOf(address(this));
    uint256 _minOut = estimate(_balance).sub(1); //Subtract one for minimum in case of rounding errors
    uint256 _actualOut = IUniswapV2Router02(router).swapExactTokensForTokens(
      _balance,
      _minOut,
      path,
      msg.sender,
      block.timestamp
    )[path.length - 1];
    return _actualOut;
  }
}