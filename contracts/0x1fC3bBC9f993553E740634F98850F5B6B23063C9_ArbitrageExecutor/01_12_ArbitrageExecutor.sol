//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IFlashLoan.sol";
import "forge-std/console.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWBnb.sol";

interface IPool {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external returns (address);

    function token1() external returns (address);
}

interface IArbitrageExecutor {
    function startSwapPayable(
        uint256 _amountIn,
        ArbitrageData[] memory paths,
        uint256 _gasPrice,
        SwapConfiguration memory _config
    ) external payable;
}

contract ArbitrageExecutor is IArbitrageExecutor {
    using SafeERC20 for IERC20;

    event Swap(
        address tokenIn,
        uint256 tokenInAmount,
        address tokenOut,
        uint256 tokenOutAmount,
        uint256 gasUsed,
        uint256 gasPriceSend,
        uint256 gasPrice
    );

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event TransferProfit(uint256 _amount);
    event Logs(uint256[] _amounts);
    event Balances(Balance[] _amounts);

    function startSwap(
        uint256 _amountIn,
        ArbitrageData[] memory paths,
        uint256 _gasPrice,
        SwapConfiguration memory _config
    ) external payable {
        _startSwap(_amountIn, paths, _gasPrice, _config);
    }

    function startSwapPayable(
        uint256 _amountIn,
        ArbitrageData[] memory paths,
        uint256 _gasPrice,
        SwapConfiguration memory _config
    ) external payable {
        require(msg.value == _amountIn, "You have to check the value");
        require(
            paths[0].TokenIn == WETH,
            "If you execute payable, the first token in should be WETH"
        );
        IWBnb(WETH).deposit{value: msg.value}();
        _startSwap(_amountIn, paths, _gasPrice, _config);
    }

    function getReservesUniSwapV2(address _pool)
        public
        view
        returns (Balance memory)
    {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPool(
            _pool
        ).getReserves();
        return Balance(_pool, reserve0, reserve1);
    }

    IUniswapV3Router constant uniswapRouter =
        IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    event AmountOut(uint256 amountOut);

    function swapUniSwapV3(
        address _pool,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) public payable {
        IERC20(WETH).safeApprove(address(uniswapRouter), amountIn);
        address token00 = IUniswapV3Pool(_pool).token0();
        address token01 = IUniswapV3Pool(_pool).token1();

        _swapUniSwapV3(token00, token01, amountIn, sqrtPriceLimitX96);
    }

    function swapUniSwapV3Payable(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external payable {
        require(msg.value > 0, "You have to send eth");
        IWBnb(WETH).deposit{value: msg.value}();
        IERC20(WETH).safeApprove(address(uniswapRouter), msg.value);
        _swapUniSwapV3(tokenIn, tokenOut, amountIn, sqrtPriceLimitX96);
    }

    function _swapUniSwapV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) internal {
        IUniswapV3Router.ExactInputSingleParams
            memory parameter = IUniswapV3Router.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                3000,
                address(this),
                block.timestamp,
                amountIn,
                0,
                sqrtPriceLimitX96
            );
        uint256 amountOut = uniswapRouter.exactInputSingle(parameter);
        emit AmountOut(amountOut);
    }

    function swapPoolUniSwapV3(
        address poolAddress,
        int256 amount,
        uint160 sqrtPriceLimitX96
    ) public payable {
        require(msg.value > 0, "You have to send eth");
        IWBnb(WETH).deposit{value: msg.value}();
        IERC20(WETH).safeApprove(address(poolAddress), msg.value);
        amount = int256(msg.value);
        (int256 amount0, int256 amount1) = IUniswapV3Pool(poolAddress).swap(
            address(this),
            true,
            amount,
            sqrtPriceLimitX96,
            ""
        );
    }

    function _getToSend(bool isLast, SwapConfiguration memory _config)
        internal
        view
        returns (address)
    {
        if (isLast) {
            return _config.toSendEarning;
        }
        return address(this);
    }

    function _swapUniSwapV2(
        ArbitrageData memory data,
        uint256 _amountIn,
        address _addressToSend
    ) internal returns (uint256[] memory) {
        address[] memory path;
        path = new address[](2);
        path[0] = data.TokenIn;
        path[1] = data.TokenOut;

        IERC20(data.TokenIn).safeApprove(data.Router, _amountIn);

        return
            IUniswapV2Router02(data.Router).swapExactTokensForTokens(
                _amountIn,
                0,
                path,
                _addressToSend,
                block.timestamp
            );
    }

    function _startSwap(
        uint256 _amountIn,
        ArbitrageData[] memory paths,
        uint256 _gasPrice,
        SwapConfiguration memory _config
    ) public {
        uint256 initialAmount = _amountIn;
        bool firstTime = true;
        uint256 startGas = gasleft();
        Balance[] memory balances = new Balance[](paths.length);

        for (uint256 i = 0; i < paths.length; i++) {
            bool isLast = (paths.length - 1) == i;
            ArbitrageData memory data = paths[i];

            if (firstTime) {
                firstTime = false;
            } else {
                _amountIn = IERC20(data.TokenIn).balanceOf(address(this));
            }
            uint256 lastAmount = 0;
            if (data.KindOfPool == 0) {
                balances[i] = getReservesUniSwapV2(data.Pool);

                uint256[] memory amounts = _swapUniSwapV2(
                    data,
                    _amountIn,
                    _getToSend(isLast, _config)
                );
                lastAmount = amounts[amounts.length - 1];
            } else if (data.KindOfPool == 1) {
                swapUniSwapV3(data.Pool, _amountIn, 1000000000000);
            }

            if (isLast) {
                emit Balances(balances);
                console.log("Ammoun in", initialAmount);
                console.log("Ammoun Out", lastAmount);
                _checkEndingConstraints(
                    balances,
                    initialAmount,
                    lastAmount,
                    startGas,
                    _gasPrice,
                    _config
                );
                // emit Logs(amounts);
                // _emitSwap(data, _amountIn, amounts, gasUsed, _gasPrice);
            }
        }
    }

    function _emitSwap(
        ArbitrageData memory data,
        uint256 _amountIn,
        uint256[] memory amounts,
        uint256 gasUsed,
        uint256 _gasPrice
    ) private {
        emit Swap(
            data.TokenIn,
            _amountIn,
            data.TokenIn,
            amounts[amounts.length - 1],
            gasUsed,
            _gasPrice,
            tx.gasprice
        );
    }

    function getBalances(ArbitrageData[] memory paths)
        public
        view
        returns (Balance[] memory)
    {
        Balance[] memory balances = new Balance[](paths.length);

        for (uint256 i = 0; i < paths.length; i++) {
            ArbitrageData memory data = paths[i];
            balances[i] = getReservesUniSwapV2(data.Pool);
        }
        return balances;
    }

    receive() external payable {}

    fallback() external payable {}

    function _checkEndingConstraints(
        Balance[] memory _balances,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _startGas,
        uint256 _gasPrice,
        SwapConfiguration memory _config
    ) internal view returns (uint256) {
        if (_config.Simulate) {
            string memory strBalances = getBalances(_balances);
            revert(
                string(
                    abi.encodePacked(
                        "Output: ",
                        _uint2str(_amountOut),
                        " Balances: ",
                        strBalances
                    )
                )
            );
        }
        require(_startGas >= gasleft(), "Gas left is more than start gas");
        uint256 gasUsed = _startGas - gasleft();

        if (_config.IgnoreProfit) {
            if (_config.AcceptWaste) {
                if (_amountIn > _amountOut) {
                    uint256 gasProcess = gasUsed * _gasPrice;
                    require(
                        _amountOut >= gasProcess,
                        "Gas Process is less than amount out"
                    );
                    uint256 out = _amountOut - gasProcess;
                    require(
                        _amountIn >= out,
                        "Amount out is gretter than amount in"
                    );

                    uint256 wasteAmount = uint256(_amountIn - out);
                    require(
                        wasteAmount < _config.MaxOfWaste,
                        string(
                            abi.encodePacked(
                                "This tx is wasting money. Wasting : ",
                                _uint2str(wasteAmount)
                            )
                        )
                    );
                }
            } else {
                revert("If you ignore the profit, you have to AcceptWaste");
            }
        } else {
            uint256 gasProcess = gasUsed * _gasPrice;
            require(
                _amountOut >= gasProcess,
                "Gas Process is less than amount out"
            );
            require(
                _amountOut - gasProcess > _amountIn,
                string(
                    abi.encodePacked(
                        "This tx does not generate profit. GasUsed : ",
                        _uint2str(gasUsed),
                        ", GasPrice: ",
                        _uint2str(_gasPrice),
                        ", GasProcess: ",
                        _uint2str(gasProcess)
                    )
                )
            );
        }
        return gasUsed;
    }

    function getBalances(Balance[] memory _balances)
        public
        pure
        returns (string memory str)
    {
        string memory toReturn = "";
        for (uint256 i = 0; i < _balances.length; i++) {
            Balance memory data = _balances[i];
            string memory strBalance01 = _uint2str(data.Balance01);
            string memory strBalance02 = _uint2str(data.Balance02);
            string memory concatBalances = string(
                abi.encodePacked("[", strBalance01, ",", strBalance02, "]")
            );
            toReturn = string(abi.encodePacked(toReturn, concatBalances));
        }
        return toReturn;
    }

    function _uint2str(uint256 _i) private pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }
}

struct SwapConfiguration {
    bool Simulate;
    bool IgnoreProfit;
    bool AcceptWaste;
    uint256 MaxOfWaste;
    address toSendEarning;
}
struct Balance {
    address pool;
    uint112 Balance01;
    uint112 Balance02;
}

struct ArbitrageData {
    address Router;
    address Pool;
    address TokenIn;
    address TokenOut;
    uint256 KindOfPool;
}