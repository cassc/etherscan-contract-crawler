// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../strategies/IBonfireStrategicCalls.sol";
import "../swap/IBonfireFactory.sol";
import "../swap/IBonfirePair.sol";
import "../swap/ISwapFactoryRegistry.sol";
import "../swap/BonfireSwapHelper.sol";

contract SkimmingCall is IBonfireStrategicCalls, Ownable {
    address public constant factoryRegistry =
        address(0xBF57511A971278FCb1f8D376D68078762Ae957C4);

    address public override token;
    address[] public pools;

    event Skim(uint256 totalAmountOut, address to);

    event PoolUpdate(address indexed pool, bool enabled);

    error BadValues(uint256 location, address a1, address a2);

    constructor(address gainToken, address admin) Ownable() {
        transferOwnership(admin);
        token = gainToken;
    }

    function sortPools() external {
        pools = _sortPools(pools);
    }

    function skimOnly(address to) external {
        for (uint256 i = 0; i < pools.length; i++) {
            IBonfirePair(pools[i]).skim(to);
        }
    }

    function execute(uint256 threshold, address to)
        external
        override
        returns (uint256 amountOut)
    {
        for (uint256 i = 0; i < pools.length; i++) {
            uint256 gains = _skim(pools[i], to, threshold);
            if (gains > 0) {
                amountOut += gains;
                emit Skim(amountOut, to);
            }
        }
    }

    function quote() external view override returns (uint256 amountOut) {
        for (uint256 i = 0; i < pools.length; i++) {
            (uint256 reserveA, uint256 reserveB, ) = IBonfirePair(pools[i])
                .getReserves();
            (reserveA, reserveB) = IBonfirePair(pools[i]).token1() == token
                ? (reserveA, reserveB)
                : (reserveB, reserveA);
            amountOut += IERC20(token).balanceOf(pools[i]) - reserveB;
        }
    }

    function addPool(address pool) external {
        address factory = IBonfirePair(pool).factory();
        address otherToken = IBonfirePair(pool).token0();
        if (otherToken == token) {
            otherToken = IBonfirePair(pool).token1();
        } else {
            if (IBonfirePair(pool).token1() != token) {
                revert BadValues(0, pool, token); //bad pool
            }
        }
        SkimmingCall(this).addPoolViaFactory(otherToken, factory);
    }

    function addPoolViaFactory(address otherToken, address uniswapFactory)
        external
    {
        bool included = false;
        if (!ISwapFactoryRegistry(factoryRegistry).enabled(uniswapFactory)) {
            revert BadValues(1, factoryRegistry, uniswapFactory); //factory not allowed
        }
        address pool = IBonfireFactory(uniswapFactory).getPair(
            otherToken,
            token
        );
        if (pool == address(0)) {
            revert BadValues(2, token, otherToken); //pool not found
        }
        included = false;
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i] == pool) {
                included = true;
                break;
            }
        }
        if (included) {
            revert BadValues(3, pool, token); //pool already present
        }
        pools.push(pool);
        SkimmingCall(this).sortPools();
        emit PoolUpdate(pool, true);
    }

    function _sortPools(address[] memory tokenPools)
        internal
        view
        returns (address[] memory _pools)
    {
        if (tokenPools.length <= 1) return tokenPools;
        _pools = new address[](tokenPools.length);
        uint256[] memory balances = new uint256[](tokenPools.length);
        _pools[0] = tokenPools[0];
        balances[0] = IERC20(token).balanceOf(_pools[0]);
        for (uint256 i = 1; i < _pools.length; i++) {
            address pool = tokenPools[i];
            uint256 balance = IERC20(token).balanceOf(pool);
            uint256 index;
            for (index = i; index > 0; index--) {
                if (balances[index - 1] > balance) {
                    balances[index] = balances[index - 1];
                    _pools[index] = _pools[index - 1];
                } else {
                    break;
                }
            }
            _pools[index] = pool;
            balances[index] = balance;
        }
        return _pools;
    }

    function _skim(
        address pool,
        address to,
        uint256 threshold
    ) internal returns (uint256) {
        (uint256 reserveA, uint256 reserveB, ) = IBonfirePair(pool)
            .getReserves();
        (reserveA, reserveB) = IBonfirePair(pool).token1() == token
            ? (reserveA, reserveB)
            : (reserveB, reserveA);
        uint256 balance = IERC20(token).balanceOf(pool);
        uint256 surplus = balance - reserveB;
        if (surplus < threshold) {
            return 0;
        }
        uint256 amount = (surplus *
            ISwapFactoryRegistry(factoryRegistry).factoryRemainder(
                IBonfirePair(pool).factory()
            )) /
            ISwapFactoryRegistry(factoryRegistry).factoryDenominator(
                IBonfirePair(pool).factory()
            );
        if (amount < threshold) {
            return 0;
        }
        if (amount > reserveB) {
            IBonfirePair(pool).skim(to);
            return amount;
        }
        amount = BonfireSwapHelper.reflectionAdjustment(
            token,
            pool,
            amount,
            balance - amount
        );
        if (IBonfirePair(pool).token1() == token) {
            IBonfirePair(pool).swap(uint256(0), amount, to, new bytes(0));
        } else {
            IBonfirePair(pool).swap(amount, uint256(0), to, new bytes(0));
        }
        return amount;
    }
}