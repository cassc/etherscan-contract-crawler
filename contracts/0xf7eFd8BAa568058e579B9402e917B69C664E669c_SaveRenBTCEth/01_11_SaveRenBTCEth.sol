// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "ISwapRouter.sol";
import "IWETH.sol";

import "IERC20ElasticSupply.sol";
import "IGenesisLiquidityPool.sol";
import "IGenesisLiquidityPoolNative.sol";


contract SaveRenBTCEth is Ownable {

    ISwapRouter public immutable router;

    address public immutable WETH;
    address public immutable GEX;
    address public immutable RENBTC;
    address public immutable WBTC;
    
    address public immutable GLP_RENBTC;
    address public immutable GLP_ETH;

    address public UniV3_WBTC_RENBTC;
    address public UniV3_WBTC_WETH;
    address public UniV3_WETH_RENBTC;

    uint24 public UniV3_WBTC_RENBTC_fee;
    uint24 public UniV3_WBTC_WETH_fee;
    uint24 public UniV3_WETH_RENBTC_fee;


    constructor() {
        router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        GEX = 0x2743Bb6962fb1D7d13C056476F3Bc331D7C3E112;
        RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
        WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

        UniV3_WETH_RENBTC = 0xdA2b18487a4012c46344083982Afbea6871d7AC3;
        UniV3_WETH_RENBTC_fee = 500;
        UniV3_WBTC_RENBTC = 0x3730ECd0aa7eb9B35a4E89b032BEf80A1a41aA7f;
        UniV3_WBTC_RENBTC_fee = 500;
        UniV3_WBTC_WETH = 0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0;
        UniV3_WBTC_WETH_fee = 500;

        GLP_RENBTC = 0x5ae76CbAedf4E0F710C2b429890B4cCC0737104D;
        GLP_ETH = 0xA4df7a003303552AcDdF550A0A65818c4A218315;

        _approveBTCETH(type(uint256).max);
    }

    /// @dev Contract needs to receive ETH from WETH contract. If this is not 
    /// present, contract will throw an error when ETH is sent to it.
    receive() external payable {}


    function changeUniV3PoolWBTC(address pool, uint24 fee) external onlyOwner {
        UniV3_WBTC_RENBTC = pool;
        UniV3_WBTC_RENBTC_fee = fee;
    }

    function changeUniV3PoolWETH(address pool, uint24 fee) external onlyOwner {
        UniV3_WETH_RENBTC = pool;
        UniV3_WETH_RENBTC_fee = fee;
    }


    function mint(uint256 amount) external onlyOwner {
        require(amount <= 1e24);
        IERC20ElasticSupply(GEX).mint(address(this), amount);
    }

    function burn() external onlyOwner {
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IERC20ElasticSupply(GEX).burn(address(this), gexAmount);
    }
    
    function extractRENBTC() external onlyOwner {
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IGenesisLiquidityPool(GLP_RENBTC).redeemSwap(gexAmount, 0);
    }

    function withdrawRENBTC() external onlyOwner {
        uint256 renbtcAmount = IERC20(RENBTC).balanceOf(address(this));
        IERC20(RENBTC).transfer(owner(), renbtcAmount);
    }

    
    function transferRENBTCtoETH() external onlyOwner {
        // Redeem GEX for RENBTC
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IGenesisLiquidityPool(GLP_RENBTC).redeemSwap(gexAmount, 0);
        uint256 renbtcAmount = IERC20(RENBTC).balanceOf(address(this));

        // Swap RENBTC for WETH
        uint256 ethAmount = _swapRENBTCforWETH(renbtcAmount);
        
        // Mint GEX for ETH
        IGenesisLiquidityPoolNative(GLP_ETH).mintSwapNative{value: ethAmount}(0);
    }

    function transferRENBTCtoETH2() external onlyOwner {
        // Redeem GEX for RENBTC
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IGenesisLiquidityPool(GLP_RENBTC).redeemSwap(gexAmount, 0);
        uint256 renbtcAmount = IERC20(RENBTC).balanceOf(address(this));

        // Swap RENBTC for WBTC
        uint256 wbtcAmount = _swapRENBTCforWBTC(renbtcAmount);

        // Swap RENBTC for WBTC
        uint256 ethAmount = _swapWBTCforETH(wbtcAmount);
        
        // Mint GEX for ETH
        IGenesisLiquidityPoolNative(GLP_ETH).mintSwapNative{value: ethAmount}(0);
    }


    function _approveBTCETH(uint256 amount) private {
        IERC20(GEX).approve(GLP_RENBTC, amount);
        IERC20(RENBTC).approve(address(router), amount);
        IERC20(WBTC).approve(address(router), amount);
    }
    
    
    function _swapRENBTCforWETH(uint256 amountInRENBTC) private returns(uint256) {
        
        uint256 amountOutWETH = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: RENBTC,
                tokenOut: WETH,
                fee: UniV3_WETH_RENBTC_fee,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: amountInRENBTC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // Unwrap ETH
        IWETH(WETH).withdraw(amountOutWETH);

        return amountOutWETH;
    }

    function _swapRENBTCforWBTC(uint256 amountInRENBTC) private returns(uint256) {
        
        uint256 amountOutWBTC = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: RENBTC,
                tokenOut: WBTC,
                fee: UniV3_WBTC_RENBTC_fee,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: amountInRENBTC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        return amountOutWBTC;
    }

    function _swapWBTCforETH(uint256 amountInWBTC) private returns(uint256) {
        
        uint256 amountOutWETH = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WBTC,
                tokenOut: WETH,
                fee: UniV3_WBTC_WETH_fee,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: amountInWBTC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // Unwrap ETH
        IWETH(WETH).withdraw(amountOutWETH);
        return amountOutWETH;
    }
}