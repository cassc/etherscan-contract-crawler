//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IPair.sol";
import "./interfaces/IAgent.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IFactory.sol";
import "./uniswap/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Agent is Ownable, IAgent {
    IRouter public immutable ROUTER;
    IFactory public immutable FACTORY;

    address public token;
    address public WETH;
    address public pair;
    uint256 public liquidityStock;
    uint256 public threshold;

    constructor(address _router, uint256 _threshold) {
        require(_threshold >= 100, "Low threshold");
        ROUTER = IRouter(_router);
        FACTORY = IFactory(IRouter(_router).factory());
        threshold = _threshold;
    }

    function initialize(address _token, address _WETH) external onlyOwner {
        require(_token != address(0) && token == address(0));
        require(_WETH != address(0) && WETH == address(0));
        token = _token;
        WETH = _WETH;
        if (FACTORY.getPair(token, WETH) == address(0)) {
            FACTORY.createPair(token, WETH);
        }
        pair = FACTORY.getPair(token, WETH);
    }

    function changeThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 100, "Low threshold");
        threshold = _threshold;
    }

    function withdrawTokens(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (token == _token) balance -= liquidityStock;
        if (balance > 0) TransferHelper.safeTransfer(token, owner(), balance);
    }

    function increaseStock(uint256 amount) external override {
        require(_msgSender() == token, "Only Token");
        liquidityStock += amount;
    }

    function autoLiquidity() external override {
        if (_msgSender() != token)
            require(liquidityStock >= threshold, "Low liquidity stock");
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        if (_pairExisting(path)) {
            IERC20(token).approve(address(ROUTER), liquidityStock);
            (uint256 reserve0, uint256 reserve1, ) = IPair(pair).getReserves();
            uint256 half = getOptimalAmountToSell(
                int256(token == IPair(pair).token0() ? reserve0 : reserve1),
                int256(liquidityStock)
            );
            uint256 anotherHalf = liquidityStock - half;
            uint256 WETHAmount = _swapTokensForTokens(half);
            if (WETHAmount != 0) {
                IERC20(WETH).approve(address(ROUTER), WETHAmount);
                anotherHalf = _addLiquidity(anotherHalf, WETHAmount);
                liquidityStock -= (anotherHalf + half);
            }
        }
    }

    function getStock() external view override returns (uint256) {
        return liquidityStock;
    }

    function getThreshold() external view override returns (uint256) {
        return threshold;
    }

    function _addLiquidity(uint256 amount0, uint256 amount1)
        internal
        returns (uint256 amount)
    {
        (amount, , ) = ROUTER.addLiquidity(
            token,
            WETH,
            amount0,
            amount1,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _swapTokensForTokens(uint256 tokenAmount)
        internal
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        try
            ROUTER.swapExactTokensForTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        returns (uint256[] memory amounts) {
            return amounts[1];
        } catch {
            return 0;
        }
        // uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
        //     tokenAmount,
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp
        // );
        // return amounts[1];
    }

    function _pairExisting(address[] memory path) internal view returns (bool) {
        uint8 len = uint8(path.length);

        address _pair;
        uint256 reserve0;
        uint256 reserve1;

        for (uint8 i; i < len - 1; i++) {
            _pair = FACTORY.getPair(path[i], path[i + 1]);
            if (_pair != address(0)) {
                (reserve0, reserve1, ) = IPair(_pair).getReserves();
                if ((reserve0 == 0 || reserve1 == 0)) return false;
            } else {
                return false;
            }
        }

        return true;
    }

    function getOptimalAmountToSell(int256 X, int256 dX)
        private
        pure
        returns (uint256)
    {
        int256 feeDenom = 1000000;
        int256 f = 997000; // 1 - fee
        unchecked {
            int256 T1 = X * (X * (feeDenom + f)**2 + 4 * feeDenom * dX * f);

            // square root
            int256 z = (T1 + 1) / 2;
            int256 sqrtT1 = T1;
            while (z < sqrtT1) {
                sqrtT1 = z;
                z = (T1 / z + z) / 2;
            }

            return
                uint256(
                    (2 * feeDenom * dX * X) / (sqrtT1 + X * (feeDenom + f))
                );
        }
    }
}