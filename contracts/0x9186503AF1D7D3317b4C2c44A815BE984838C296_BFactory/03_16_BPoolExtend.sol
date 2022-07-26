// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "./IBPool.sol";

interface IOperationsRegistry {
    function allowedAssets(address asset) external view returns (bool);
}

// interface IBPool {
//     function bind(
//         address token,
//         uint256 balance,
//         uint256 denorm
//     ) external;

//     function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

//     function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

//     function swapExactAmountIn(
//         address tokenIn,
//         uint256 tokenAmountIn,
//         address tokenOut,
//         uint256 minAmountOut,
//         uint256 maxPrice
//     ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

//     function swapExactAmountOut(
//         address tokenIn,
//         uint256 maxAmountIn,
//         address tokenOut,
//         uint256 tokenAmountOut,
//         uint256 maxPrice
//     ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

//     function joinswapExternAmountIn(
//         address tokenIn,
//         uint256 tokenAmountIn,
//         uint256 minPoolAmountOut
//     ) external returns (uint256 poolAmountOut);

//     function joinswapPoolAmountOut(
//         address tokenIn,
//         uint256 poolAmountOut,
//         uint256 maxAmountIn
//     ) external returns (uint256 tokenAmountIn);

//     function exitswapPoolAmountIn(
//         address tokenOut,
//         uint256 poolAmountIn,
//         uint256 minAmountOut
//     ) external returns (uint256 tokenAmountOut);

//     function exitswapExternAmountOut(
//         address tokenOut,
//         uint256 tokenAmountOut,
//         uint256 maxPoolAmountIn
//     ) external returns (uint256 poolAmountIn);
// }

contract BPoolExtend is Proxy, ERC1155Holder {
    address public immutable implementation;
    address public immutable exchangeProxy;
    address public immutable operationsRegistry;

    constructor(address _poolImpl, address _operationsRegistry, address _exchProxy, bytes memory _data) {
        implementation = _poolImpl;
        exchangeProxy = _exchProxy;
        operationsRegistry = _operationsRegistry;

        if(_data.length > 0) {
            Address.functionDelegateCall(_poolImpl, _data);
        }
    }

    function _implementation() internal view override returns (address) {
        return implementation;
    }

    function _beforeFallback() internal view override {
       _onlyExchangeProxy();
       _onlyAllowedToken();
    }

    function _onlyExchangeProxy() internal view {
        if (
           msg.sig == IBPool.joinPool.selector ||
           msg.sig == IBPool.exitPool.selector ||
           msg.sig == IBPool.swapExactAmountIn.selector ||
           msg.sig == IBPool.swapExactAmountOut.selector ||
           msg.sig == IBPool.joinswapExternAmountIn.selector ||
           msg.sig == IBPool.joinswapPoolAmountOut.selector ||
           msg.sig == IBPool.exitswapPoolAmountIn.selector ||
           msg.sig == IBPool.exitswapExternAmountOut.selector
        ) {
            require(msg.sender == exchangeProxy, "ERR_NOT_EXCHANGE_PROXY");
       }
    }

    function _onlyAllowedToken() internal view {
        if (msg.sig == IBPool.bind.selector) {
            (address token, , ) = abi.decode(msg.data[4:], (address, address, uint256));
            require(IOperationsRegistry(operationsRegistry).allowedAssets(token), "ERR_NOT_ALLOWED_TOKEN");
        }
    }
}