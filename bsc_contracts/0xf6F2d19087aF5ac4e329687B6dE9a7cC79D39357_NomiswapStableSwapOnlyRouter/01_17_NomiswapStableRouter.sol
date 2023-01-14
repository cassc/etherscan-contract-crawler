// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import './NomiswapStablePair.sol';

contract NomiswapStableSwapOnlyRouter {

    address public immutable stableSwapFactory;

    constructor(address _stableSwapFactory) {
        stableSwapFactory = _stableSwapFactory;
    }
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'NomiswapRouter: EXPIRED');
        _;
    }

    receive() external payable {
        require(msg.sender == 0x0000000000000000000000000000000000000000, 'NomiswapRouter: no payments'); // only accept ETH via fallback from the WETH contract
    }

    function pairFor(address token0, address token1) public view returns (address) {
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
        bytes memory bytecode = type(NomiswapStablePair).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(token0, token1));
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), stableSwapFactory, salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        safeTransferFrom(
            path[0], msg.sender, pairFor(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            address token0 = input < output ? input : output;
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pairFor(output, path[i + 2]) : _to;
            address pair = pairFor(input, output);
            INomiswapPair(pair).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function getAmountsOut(uint amountIn, address[] memory path) private view returns (uint[] memory amounts) {
        require(path.length >= 2, 'NomiswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            address pair = pairFor(path[i], path[i + 1]);
            amounts[i + 1] = INomiswapStablePair(pair).getAmountOut(path[i], amounts[i]);
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}