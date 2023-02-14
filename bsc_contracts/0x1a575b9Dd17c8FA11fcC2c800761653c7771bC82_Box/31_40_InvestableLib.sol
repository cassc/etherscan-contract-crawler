// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Math.sol";
import "../../dependencies/venus/IVBNB.sol";
import "../../dependencies/venus/IVBep20.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

struct TokenDesc {
    uint256 total;
    uint256 acquired;
}

library InvestableLib {
    // Avalanche adresses
    IERC20Upgradeable public constant AVALANCHE_NATIVE =
        IERC20Upgradeable(0x0000000000000000000000000000000000000001);
    IERC20Upgradeable public constant AVALANCHE_WAVAX =
        IERC20Upgradeable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20Upgradeable public constant AVALANCHE_USDT =
        IERC20Upgradeable(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);
    IERC20Upgradeable public constant AVALANCHE_USDC =
        IERC20Upgradeable(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);

    // Binance addresses
    IERC20Upgradeable public constant BINANCE_NATIVE =
        IERC20Upgradeable(0x0000000000000000000000000000000000000002);
    IERC20Upgradeable public constant BINANCE_BUSD =
        IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20Upgradeable public constant BINANCE_WBNB =
        IERC20Upgradeable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    IERC20Upgradeable public constant BINANCE_CAKE =
        IERC20Upgradeable(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IVBep20 public constant BINANCE_VENUS_BUSD_MARKET =
        IVBep20(0x95c78222B3D6e262426483D42CfA53685A67Ab9D);
    IVBNB public constant BINANCE_VENUS_BNB_MARKET =
        IVBNB(0xA07c5b74C9B40447a954e1466938b865b6BBea36);

    uint8 public constant PRICE_PRECISION_DIGITS = 6;
    uint256 public constant PRICE_PRECISION_FACTOR = 10**PRICE_PRECISION_DIGITS;

    function convertPricePrecision(
        uint256 price,
        uint256 currentPrecision,
        uint256 desiredPrecision
    ) internal pure returns (uint256) {
        if (currentPrecision > desiredPrecision)
            return (price / (currentPrecision / desiredPrecision));
        else if (currentPrecision < desiredPrecision)
            return price * (desiredPrecision / currentPrecision);
        else return price;
    }

    function calculateMintAmount(
        uint256 equitySoFar,
        uint256 amountInvestedNow,
        uint256 investmentTokenSupplySoFar,
        uint8 depositTokenDecimalCount
    ) internal pure returns (uint256) {
        if (investmentTokenSupplySoFar == 0) {
            return
                convertPricePrecision(
                    amountInvestedNow,
                    10**depositTokenDecimalCount,
                    PRICE_PRECISION_FACTOR
                );
        } else
            return
                (amountInvestedNow * investmentTokenSupplySoFar) / equitySoFar;
    }
}