//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Presale
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        bytes32 initCodeHash,
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            initCodeHash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        bytes32 initCodeHash,
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(
            pairFor(initCodeHash, factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }
}

enum Currency {
    USDT,
    BUSD,
    WBNB,
    BTCB,
    ETH
}

contract Presale is Ownable {
    using SafeERC20 for IERC20;
    event Bought(
        address indexed buyer,
        address indexed token,
        uint256 amountIn,
        uint256 amountOut
    );

    struct Buyer {
        address buyer;
        uint256 amount;
    }

    address public immutable USDT;
    address public immutable BUSD;
    address public immutable WBNB;
    address public immutable BTCB;
    address public immutable ETH;
    address public immutable DEX_FACTORY;
    bytes32 public immutable INIT_CODE_HASH;
    mapping(address => uint256) public bought;
    address[] public buyers;
    uint256 public priceInUsd;

    function buy(Currency currency, uint256 amountIn) external returns (uint256) {
        require(priceInUsd != 0, 'presale stopped');
        require(amountIn != 0, 'bad amount');

        address token = currency == Currency.USDT ? USDT : currency == Currency.BUSD
            ? BUSD
            : currency == Currency.WBNB
            ? WBNB
            : currency == Currency.BTCB
            ? BTCB
            : ETH;

        uint256 amountOut = convert(currency, amountIn);
        if (bought[msg.sender] == 0) buyers.push(msg.sender);
        bought[msg.sender] += amountOut;
        emit Bought(msg.sender, token, amountIn, amountOut);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        return amountOut;
    }

    function convert(Currency currency, uint256 amountIn) public view returns (uint256) {
        if (priceInUsd == 0 || amountIn == 0) return 0;

        address token = currency == Currency.USDT ? USDT : currency == Currency.BUSD
            ? BUSD
            : currency == Currency.WBNB
            ? WBNB
            : currency == Currency.BTCB
            ? BTCB
            : ETH;

        uint256 amountOut;
        if (currency != Currency.USDT && currency != Currency.BUSD) {
            (uint256 reserveToken, uint256 reserveBusd) = UniswapV2Library.getReserves(
                INIT_CODE_HASH,
                DEX_FACTORY,
                token,
                BUSD
            );
            amountOut = (amountIn * reserveBusd * 10 ** 18) / reserveToken / priceInUsd;
        } else {
            amountOut = (amountIn * 10 ** 18) / priceInUsd;
        }

        return amountOut;
    }

    function getBuyers(
        uint256 pivot,
        uint256 amount
    ) external view returns (Buyer[] memory) {
        uint256 length = buyers.length;
        if (pivot >= length) return new Buyer[](0);
        if (pivot + amount > length) amount = length - pivot;
        Buyer[] memory result = new Buyer[](amount);
        for (uint256 i = 0; i < amount; i++) {
            result[i] = Buyer(buyers[pivot + i], bought[buyers[pivot + i]]);
        }
        return result;
    }

    function getBuyersLength() external view returns (uint256) {
        return buyers.length;
    }

    function setPriceInUsd(uint256 priceInUsd_) external onlyOwner {
        require(priceInUsd_ != 0, 'bad price');
        priceInUsd = priceInUsd_;
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function stopPresale() external onlyOwner {
        priceInUsd = 0;
    }

    constructor(
        address USDT_,
        address BUSD_,
        address WBNB_,
        address BTCB_,
        address ETH_,
        address DEX_FACTORY_,
        uint256 priceInUsd_,
        bytes32 initCodeHash_
    ) {
        require(
            USDT_ != address(0) &&
                BUSD_ != address(0) &&
                WBNB_ != address(0) &&
                BTCB_ != address(0) &&
                ETH_ != address(0),
            'bad tokens'
        );
        require(DEX_FACTORY_ != address(0), 'bad factory');

        USDT = USDT_;
        BUSD = BUSD_;
        WBNB = WBNB_;
        BTCB = BTCB_;
        ETH = ETH_;
        DEX_FACTORY = DEX_FACTORY_;
        priceInUsd = priceInUsd_;
        INIT_CODE_HASH = initCodeHash_;
    }
}