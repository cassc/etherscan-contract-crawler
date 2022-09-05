//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

pragma experimental ABIEncoderV2;

import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../../PriceAccumulator.sol";
import "../../../libraries/SafeCastExt.sol";

contract UniswapV2PriceAccumulator is PriceAccumulator {
    using AddressLibrary for address;
    using SafeCastExt for uint256;

    address public immutable uniswapFactory;

    bytes32 public immutable initCodeHash;

    constructor(
        address uniswapFactory_,
        bytes32 initCodeHash_,
        address quoteToken_,
        uint256 updateTheshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    ) PriceAccumulator(quoteToken_, updateTheshold_, minUpdateDelay_, maxUpdateDelay_) {
        uniswapFactory = uniswapFactory_;
        initCodeHash = initCodeHash_;
    }

    /// @inheritdoc PriceAccumulator
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

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
        if (reserve0 == 0 || reserve1 == 0) {
            // Pool doesn't have liquidity
            return false;
        }

        return super.canUpdate(data);
    }

    /**
     * @notice Calculates the price of a token.
     * @dev When the price equals 0, a price of 1 is actually returned.
     * @param token The token to get the price for.
     * @return price The price of the specified token in terms of the quote token, scaled by the quote token decimal
     *   places.
     */
    function fetchPrice(address token) internal view virtual override returns (uint112 price) {
        address pairAddress = pairFor(uniswapFactory, initCodeHash, token, quoteToken);

        require(pairAddress.isContract(), "UniswapV2PriceAccumulator: POOL_NOT_FOUND");

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Note: Reserves are actually stored in uint112, but we promote for handling the math below
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        require(reserve0 > 0 && reserve1 > 0, "UniswapV2PriceAccumulator: NO_LIQUIDITY");

        if (token < quoteToken) {
            // reserve0 == tokenLiquidity, reserve1 == quoteTokenLiquidity
            price = ((computeWholeUnitAmount(token) * reserve1) / reserve0).toUint112();
        } else {
            // reserve1 == tokenLiquidity, reserve0 == quoteTokenLiquidity
            price = ((computeWholeUnitAmount(token) * reserve0) / reserve1).toUint112();
        }

        if (price == 0) return 1;
    }

    function computeWholeUnitAmount(address token) internal view returns (uint256 amount) {
        amount = uint256(10)**IERC20Metadata(token).decimals();
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2PriceAccumulator: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2PriceAccumulator: ZERO_ADDRESS");
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