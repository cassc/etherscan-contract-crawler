//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Presale
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

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

    struct Round {
        uint32 start;
        uint32 period;
        uint96 priceInUsd;
        uint96 amount;
    }

    struct CurrentRound {
        uint256 id;
        Round data;
    }

    address public immutable USDT;
    address public immutable BUSD;
    address public immutable WBNB;
    address public immutable BTCB;
    address public immutable ETH;
    address public immutable DEX_FACTORY;
    bytes32 public immutable INIT_CODE_HASH;

    Round[3] public rounds;
    mapping(address => uint256) public bought;
    address[] public buyers;

    function buy(
        uint256 round,
        Currency currency,
        uint256 amountIn
    ) external returns (uint256) {
        require(round < rounds.length, 'bad round');
        require(block.timestamp > rounds[round].start, 'not started');
        require(block.timestamp < rounds[round].start + rounds[round].period, 'ended');
        require(amountIn != 0, 'bad amount');

        address token = currency == Currency.USDT ? USDT : currency == Currency.BUSD
            ? BUSD
            : currency == Currency.WBNB
            ? WBNB
            : currency == Currency.BTCB
            ? BTCB
            : ETH;

        uint256 amountOut = convert(round, currency, amountIn);
        require(amountOut <= rounds[round].amount, 'not enough tokens');

        emit Bought(msg.sender, token, amountIn, amountOut);
        if (bought[msg.sender] == 0) buyers.push(msg.sender);
        bought[msg.sender] += amountOut;
        rounds[round].amount -= uint96(amountOut);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        return amountOut;
    }

    function convert(
        uint256 round,
        Currency currency,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        if (round >= rounds.length) return 0;
        if (block.timestamp < rounds[round].start) return 0;
        if (block.timestamp > rounds[round].start + rounds[round].period) return 0;
        if (rounds[round].priceInUsd == 0 || amountIn == 0) return 0;

        address token = currency == Currency.USDT ? USDT : currency == Currency.BUSD
            ? BUSD
            : currency == Currency.WBNB
            ? WBNB
            : currency == Currency.BTCB
            ? BTCB
            : ETH;

        if (currency != Currency.USDT && currency != Currency.BUSD) {
            (uint256 reserveToken, uint256 reserveBusd) = UniswapV2Library.getReserves(
                INIT_CODE_HASH,
                DEX_FACTORY,
                token,
                BUSD
            );
            amountOut =
                (amountIn * reserveBusd * 10 ** 18) /
                reserveToken /
                rounds[round].priceInUsd;
        } else {
            amountOut = (amountIn * 10 ** 18) / rounds[round].priceInUsd;
        }
    }

    function getMaxAmountIn(Currency currency) external view returns (uint256 amountIn) {
        CurrentRound memory currentRound = getCurrentRound();
        if (currentRound.id == uint256(int256(-1))) return 0;
        if (currentRound.data.amount == 0) return 0;

        address token = currency == Currency.USDT ? USDT : currency == Currency.BUSD
            ? BUSD
            : currency == Currency.WBNB
            ? WBNB
            : currency == Currency.BTCB
            ? BTCB
            : ETH;

        if (currency != Currency.USDT && currency != Currency.BUSD) {
            (uint256 reserveToken, uint256 reserveBusd) = UniswapV2Library.getReserves(
                INIT_CODE_HASH,
                DEX_FACTORY,
                token,
                BUSD
            );
            amountIn =
                (uint256(currentRound.data.amount) *
                    currentRound.data.priceInUsd *
                    reserveToken) /
                reserveBusd /
                10 ** 18;
        } else {
            amountIn =
                (uint256(currentRound.data.amount) * currentRound.data.priceInUsd) /
                10 ** 18;
        }
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

    function getCurrentRound() public view returns (CurrentRound memory) {
        for (uint256 i = 0; i < rounds.length; i++) {
            if (
                block.timestamp > rounds[i].start &&
                block.timestamp < rounds[i].start + rounds[i].period
            ) return CurrentRound(i, rounds[i]);
        }
        return CurrentRound(uint256(int256(-1)), Round(0, 0, 0, 0));
    }

    function setRound(
        uint256 id,
        uint32 start,
        uint32 period,
        uint96 priceInUsd,
        uint96 amount
    ) external onlyOwner {
        require(id < rounds.length, 'bad round');
        require(start > block.timestamp, 'bad start');
        require(period > 0, 'bad period');
        require(priceInUsd > 0, 'bad price');
        require(rounds[id].start > block.timestamp, 'round started');

        rounds[id] = Round(start, period, priceInUsd, amount);
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    constructor(
        address USDT_,
        address BUSD_,
        address WBNB_,
        address BTCB_,
        address ETH_,
        address DEX_FACTORY_,
        bytes32 initCodeHash_,
        Round[3] memory rounds_
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
        INIT_CODE_HASH = initCodeHash_;
        rounds[0] = rounds_[0];
        rounds[1] = rounds_[1];
        rounds[2] = rounds_[2];
    }
}