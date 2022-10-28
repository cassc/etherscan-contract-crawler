//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import './interfaces/IErc20.sol';
import './interfaces/IUniswapV3Router.sol';
import './interfaces/IWBnb.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IERC3156FlashBorrower.sol';
import './interfaces/IFlashLoan.sol';
import 'forge-std/console.sol';

interface IPool {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}
struct ArbitrageData {
    address pool;
    uint256 amount0Out;
    address tokenOut;
    uint256 amount1Out;
    address transferTo;
}

interface IArbitrageExecutorCheap {
    function swap(ArbitrageData[] calldata _paths, uint256 _gasPrice) external payable;

    function getReservesData(address _pool) external view returns (Balance memory);
}
struct Balance {
    address pool;
    uint112 Balance01;
    uint112 Balance02;
}

contract ArbitrageExecutorCheap {
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function swap(
        ArbitrageData[] calldata _paths,
        uint256 _value,
        uint256 _gasPrice
    ) external {
        uint256 startGas = gasleft();

        IErc20(WETH).transfer(_paths[0].pool, _value);

        ArbitrageData calldata data;
        for (uint256 i = 0; i < _paths.length; i++) {
            data = _paths[i];

            IPool(data.pool).swap(data.amount0Out, data.amount1Out, data.transferTo, '');
        }

        uint256 endBalance = IErc20(_paths[_paths.length - 1].tokenOut).balanceOf(address(this));
        unchecked {
            require(endBalance > _value, 'Less Balance');
            uint256 earned = endBalance - _value;
            uint256 gasUsed = ((startGas - gasleft()) * _gasPrice);
            require(gasUsed < earned, 'No Earned');
        }
    }

    function deposit() external payable {
        IWBnb(WETH).deposit{value: msg.value}();
    }

    function getAmount(address _token) external {
        uint256 endBalance = IErc20(_token).balanceOf(address(this));
        payable(msg.sender).transfer(payable(address(this)).balance);
        IErc20(_token).transfer(msg.sender, endBalance);
    }

    function version() external pure returns (uint256) {
        return 997;
    }

    function getReservesData(address _pool) public view returns (Balance memory) {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPool(_pool)
            .getReserves();
        return Balance(_pool, reserve0, reserve1);
    }

    receive() external payable {}

    fallback() external payable {}
}