//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

library PriceLib {

    address internal constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address internal constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address internal constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    /// @return the price in USD of 8 decimals in precision.
    function getAssetPrice(address asset) internal view returns (uint) {
        if (asset == USDT) {
            return uint(IChainlink(0xB97Ad0E74fa7d920791E90258A6E2085088b4320).latestAnswer());
        } else if (asset == USDC) {
            return uint(IChainlink(0x51597f405303C4377E36123cBc172b13269EA163).latestAnswer());
        } else if (asset == BUSD) {
            return uint(IChainlink(0xcBb98864Ef56E9042e7d2efef76141f15731B82f).latestAnswer());
        }
        return 0;
    }

    function getBNBPriceInUSD() internal view returns (uint, uint) {
        uint BNBPriceInUSD = uint(IChainlink(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE).latestAnswer()); // 8 decimals
        return (BNBPriceInUSD, 1e8);
    }

    function getCAKEPriceInUSD() internal view returns (uint, uint) {
        uint CAKEPriceInUSD = uint(IChainlink(0xB6064eD41d4f67e353768aA239cA86f4F73665a1).latestAnswer()); // 8 decimals
        return (CAKEPriceInUSD, 1e8);
    }

    function getUSDTPriceInUSD() internal view returns (uint, uint) {
        uint USDTPriceInUSD = uint(IChainlink(0xB97Ad0E74fa7d920791E90258A6E2085088b4320).latestAnswer()); // 8 decimals
        return (USDTPriceInUSD, 1e8);
    }
}