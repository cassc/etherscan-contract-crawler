// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;
import "./variables.sol";

contract Helpers is Variables {
    // todo: check
    function convertWstethRateForSteth(
        uint256 wstEthSupplyRate,
        uint256 stEthPerWsteth_
    ) public pure returns (uint256) {
        return (wstEthSupplyRate * 1e18) / stEthPerWsteth_;
    }

    function getAaveV2Rates()
        public
        view
        returns (uint256 stETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // These values are returned in Ray. i.e. 100% => 1e27.
        // Steth supply rate = 0. Add Lido APR.
        (, , , stETHSupplyRate_, , , , , , ) = AAVE_V2_DATA.getReserveData(
            STETH_ADDRESS
        );

        // These values are returned in Ray. i.e. 100% => 1e27.
        (, , , , wethBorrowRate_, , , , , ) = AAVE_V2_DATA.getReserveData(
            WETH_ADDRESS
        );

        stETHSupplyRate_ = ((stETHSupplyRate_ * 1e6) / 1e27);
        wethBorrowRate_ = ((wethBorrowRate_ * 1e6) / 1e27);
    }

    function getAaveV3Rates()
        public
        view
        returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // These values are returned in Ray. i.e. 100% => 1e27.
        // Add staking apr to the supply rate.
        (, , , , , wstETHSupplyRate_, , , , , , ) = AAVE_V3_DATA.getReserveData(
            WSTETH_ADDRESS
        );

        // These values are returned in Ray. i.e. 100% => 1e27.
        (, , , , , , wethBorrowRate_, , , , , ) = AAVE_V3_DATA.getReserveData(
            WETH_ADDRESS
        );

        wstETHSupplyRate_ = ((wstETHSupplyRate_ * 1e6) / 1e27);
        wethBorrowRate_ = ((wethBorrowRate_ * 1e6) / 1e27);
    }

    function getCompoundV3Rates()
        public
        view
        returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        uint256 utilization_ = COMPOUND_V3_DATA.getUtilization();

        // Only base token has a supply rate. Add Lido staking APR.
        wstETHSupplyRate_ = 0;

        // The per-second borrow rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
        wethBorrowRate_ = COMPOUND_V3_DATA.getBorrowRate(utilization_);

        // The per-year borrow rate scaled up by 10 ^ 18
        wethBorrowRate_ = wethBorrowRate_ * 60 * 60 * 24 * 365;

        wethBorrowRate_ = ((wethBorrowRate_ * 1e6) / 1e18);
    }

    function getEulerRates()
        public
        view
        returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // This is the base supply rate (IN RAY). Add Lido APR
        (, , wstETHSupplyRate_) = EULER_SIMPLE_VIEW.interestRates(
            WSTETH_ADDRESS
        );

        // This is the base borrow rate (IN RAY).
        (, wethBorrowRate_, ) = EULER_SIMPLE_VIEW.interestRates(WETH_ADDRESS);

        // https://etherscan.io/address/0x5077B7642abF198b4a5b7C4BdCE4f03016C7089C#readContract
        wstETHSupplyRate_ = (wstETHSupplyRate_ * 1e6) / 1e27;

        wethBorrowRate_ = (wethBorrowRate_ * 1e6) / 1e27;
    }

    function getMorphoAaveV2Rates()
        public
        view
        returns (
            uint256 stETHSupplyPoolRate_,
            uint256 stETHSupplyP2PRate_,
            uint256 wethBorrowPoolRate_,
            uint256 wethBorrowP2PRate_
        )
    {
        /// stETHSupplyP2PRate_ => market's peer-to-peer supply rate per year (in RAY).
        /// stETHSupplyPoolRate_ => market's pool supply rate per year (in RAY).
        (stETHSupplyP2PRate_, , stETHSupplyPoolRate_, ) = MORPHO_AAVE_LENS
            .getRatesPerYear(A_STETH_ADDRESS);

        /// wethBorrowP2PRate_ => market's peer-to-peer borrow rate per year (in RAY).
        /// wethBorrowPoolRate_ => market's pool borrow rate per year (in RAY).
        (, wethBorrowP2PRate_, , wethBorrowPoolRate_) = MORPHO_AAVE_LENS
            .getRatesPerYear(A_WETH_ADDRESS);

        stETHSupplyP2PRate_ = ((stETHSupplyP2PRate_ * 1e6) / 1e27);
        stETHSupplyPoolRate_ = ((stETHSupplyPoolRate_ * 1e6) / 1e27);
        wethBorrowP2PRate_ = ((wethBorrowP2PRate_ * 1e6) / 1e27);
        wethBorrowPoolRate_ = ((wethBorrowPoolRate_ * 1e6) / 1e27);
    }
}