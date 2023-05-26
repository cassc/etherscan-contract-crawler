// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Auth.sol";
import "./interfaces/IUniV2.sol";
import "./interfaces/IUniV2Factory.sol";

/// @notice Contract for withdrawing LP positions.
/// @dev Calling unwindPairs() withdraws the LP position into one of the two tokens
contract Unwindooor is Auth {

    error SlippageProtection();
    error TransferFailed();

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    IUniV2Factory public immutable factory;

    constructor(
        address owner,
        address user,
        address factoryAddress
    ) Auth(owner, user) {
        factory = IUniV2Factory(factoryAddress);
    }

    // We remove liquidity and sell tokensB[i] for tokensA[i].
    function unwindPairs(
        address[] calldata tokensA,
        address[] calldata tokensB,
        uint256[] calldata amounts,
        uint256[] calldata minimumOuts
    ) external onlyTrusted {
        for (uint256 i = 0; i < tokensA.length; i++) {
            
            address tokenA = tokensA[i];
            address tokenB = tokensB[i];
            bool keepToken0 = tokenA < tokenB;
            address pair = _pairFor(tokenA, tokenB);

            if (_unwindPair(IUniV2(pair), amounts[i], keepToken0, tokenB) < minimumOuts[i]) revert SlippageProtection();
        }
    }

    // Burn liquidity and sell one of the tokens for the other.
    function _unwindPair(
        IUniV2 pair,
        uint256 amount,
        bool keepToken0,
        address tokenToSell
    ) private returns (uint256 amountOut) {

        pair.transfer(address(pair), amount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        if (keepToken0) {
            _safeTransfer(tokenToSell, address(pair), amount1);
            amountOut = _getAmountOut(amount1, uint256(reserve1), uint256(reserve0));
            pair.swap(amountOut, 0, address(this), "");
            amountOut += amount0;
        } else {
            _safeTransfer(tokenToSell, address(pair), amount0);
            amountOut = _getAmountOut(amount0, uint256(reserve0), uint256(reserve1));
            pair.swap(0, amountOut, address(this), "");
            amountOut += amount1;
        }
    }

    // In case we don't want to sell one of the tokens for the other.
    function burnPairs(
        IUniV2[] calldata lpTokens,
        uint256[] calldata amounts,
        uint256[] calldata minimumOut0,
        uint256[] calldata minimumOut1
    ) external onlyTrusted {
        for (uint256 i = 0; i < lpTokens.length; i++) {
            IUniV2 pair = lpTokens[i];
            pair.transfer(address(pair), amounts[i]);
            (uint256 amount0, uint256 amount1) = pair.burn(address(this));
            if (amount0 < minimumOut0[i] || amount1 < minimumOut1[i]) revert SlippageProtection();
        }
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
        )))));
    }

}