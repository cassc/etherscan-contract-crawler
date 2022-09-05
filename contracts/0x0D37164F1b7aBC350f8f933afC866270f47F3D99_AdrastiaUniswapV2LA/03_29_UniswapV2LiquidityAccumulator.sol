//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

pragma experimental ABIEncoderV2;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../../LiquidityAccumulator.sol";

contract UniswapV2LiquidityAccumulator is LiquidityAccumulator {
    using AddressLibrary for address;

    address public immutable uniswapFactory;

    bytes32 public immutable initCodeHash;

    constructor(
        address uniswapFactory_,
        bytes32 initCodeHash_,
        address quoteToken_,
        uint256 updateTheshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    ) LiquidityAccumulator(quoteToken_, updateTheshold_, minUpdateDelay_, maxUpdateDelay_) {
        uniswapFactory = uniswapFactory_;
        initCodeHash = initCodeHash_;
    }

    /// @inheritdoc LiquidityAccumulator
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        address token = abi.decode(data, (address));

        if (token == address(0) || token == quoteToken) {
            // Invalid token
            return false;
        }

        address pairAddress = pairFor(uniswapFactory, initCodeHash, token, quoteToken);

        if (!pairAddress.isContract()) {
            // Pool doesn't exist
            return false;
        }

        return super.canUpdate(data);
    }

    function fetchLiquidity(address token)
        internal
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        address pairAddress = pairFor(uniswapFactory, initCodeHash, token, quoteToken);

        require(pairAddress.isContract(), "UniswapV2LiquidityAccumulator: POOL_NOT_FOUND");

        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();

        if (token < quoteToken) {
            tokenLiquidity = reserve0;
            quoteTokenLiquidity = reserve1;
        } else {
            tokenLiquidity = reserve1;
            quoteTokenLiquidity = reserve0;
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        bytes32 initCodeHash_,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"ff", factory, keccak256(abi.encodePacked(token0, token1)), initCodeHash_)
                    )
                )
            )
        );
    }
}