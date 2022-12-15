// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "IPancakePair.sol";
import "IUniswapV2Router01.sol";
import "IWETH.sol";

import "IERC20ElasticSupply.sol";
import "IGenesisLiquidityPool.sol";
import "IGenesisLiquidityPoolNative.sol";


contract SaveRenBTCBSC is Ownable {

    IUniswapV2Router01 public immutable router;

    address public immutable WBNB;
    address public immutable GEX;
    address public immutable RENBTC;
    address public immutable BTCB;
    
    address public immutable Pancake_BTCB_RENBTC;
    address public immutable Pancake_BTCB_WBNB;
    address public immutable GLP_RENBTC;
    address public immutable GLP_BNB;


    constructor() {
        router = IUniswapV2Router01(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        GEX = 0x2743Bb6962fb1D7d13C056476F3Bc331D7C3E112;
        RENBTC = 0xfCe146bF3146100cfe5dB4129cf6C82b0eF4Ad8c;
        BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

        Pancake_BTCB_WBNB = 0x61EB789d75A95CAa3fF50ed7E47b96c132fEc082;
        Pancake_BTCB_RENBTC = 0x8c9910c8562e7058561713A2f8Eb6b84cA247e02;

        GLP_RENBTC = 0x5ae76CbAedf4E0F710C2b429890B4cCC0737104D;
        GLP_BNB = 0xA4df7a003303552AcDdF550A0A65818c4A218315;

        _approveBTCBNB(type(uint256).max);
    }

    /// @dev Contract needs to receive BNB from WBNB contract. If this is not 
    /// present, contract will throw an error when BNB is sent to it.
    receive() external payable {}

    function _approveBTCBNB(uint256 amount) internal {
        IERC20(GEX).approve(GLP_RENBTC, amount);
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

    function transferRENBTCtoBNB() external onlyOwner {
        // Redeem GEX for RENBTC
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IGenesisLiquidityPool(GLP_RENBTC).redeemSwap(gexAmount, 0);
        uint256 renbtcAmount = IERC20(RENBTC).balanceOf(address(this));

        // Swap RENBTC for BTCB
        uint256 btcbAmount = _swapRENBTCforBTCB(renbtcAmount);

        // Swap RENBTC for BTCB
        uint256 bnbAmount = _swapBTCBforBNB(btcbAmount);
        
        // Mint GEX for BNB
        IGenesisLiquidityPoolNative(GLP_BNB).mintSwapNative{value: bnbAmount}(0);
    }

    function _swapRENBTCforBTCB(uint256 amountInRENBTC) private returns(uint256) {
        address[] memory tradePath = new address[](2);
        tradePath[0] = RENBTC;
        tradePath[1] = BTCB;
        uint256 amountOutBTCB = router.getAmountsOut(amountInRENBTC, tradePath)[0];

        IERC20(RENBTC).transfer(Pancake_BTCB_RENBTC, amountInRENBTC);
        IPancakePair(Pancake_BTCB_RENBTC).swap(amountOutBTCB, 0, address(this), new bytes(0));
        return amountOutBTCB;
    }

    function _swapBTCBforBNB(uint256 amountInBTCB) private returns(uint256) {
        address[] memory tradePath = new address[](2);
        tradePath[0] = BTCB;
        tradePath[1] = WBNB;
        uint256 amountOutWBNB = router.getAmountsOut(amountInBTCB, tradePath)[0];

        IERC20(BTCB).transfer(Pancake_BTCB_WBNB, amountInBTCB);
        IPancakePair(Pancake_BTCB_WBNB).swap(0, amountOutWBNB, address(this), new bytes(0));

        // Unwrap BNB
        IWETH(WBNB).withdraw(amountOutWBNB);
        return amountOutWBNB;
    }
}