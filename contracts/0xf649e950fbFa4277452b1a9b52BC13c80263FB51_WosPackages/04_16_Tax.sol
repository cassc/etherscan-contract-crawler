// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CollateralWrapper.sol";
import "./../ISimpleStaking.sol";

contract Tax is CollateralWrapper {
    uint256 constant tax = 5;
    address private WosStakingAddress;
    address private DG;
    address private JS;
    address private OpWallet;
    address private Agregadores;
    address private SLWallet;

    //Wallets of presales
    address private PreSalesOP;
    address private PreSalesMk;

    constructor(
        address _wosStakingAddress,
        address _collateral,
        address _aggAddress,
        address _signatureCollateral
    ) CollateralWrapper(_collateral, _signatureCollateral) {
        WosStakingAddress = _wosStakingAddress; //Smart Contract
        Agregadores = _aggAddress; //Contract
        DG = 0x9Fe30a5c5424BC3E461AD13B4947465e6460113d; //wallet
        JS = 0x491f38D5ae8Dc0C1fB7Ad7AB3A122393F758937F; //wallet
        OpWallet = 0x8A1078E9C93D98E724b54841fbb60E7Ea28d1654; //wallet
        SLWallet = 0xC3353c719b7D987123b248d5Fe4b35cbC05e5fa7; //wallet
        PreSalesOP = 0x788B366fbb3C57dA08749c0253C175B51f04C6c5;
        PreSalesMk = 0x65d03f96B46701790Ba5E169423d4bE042016B01;
    }

    function _getPriceWithoutTax(uint256 price)
        internal
        pure
        returns (uint256)
    {
        return price - (tax * price) / 100;
    }

    function _taxDistributionPreSales(uint256 price) internal {
        uint256 amountDistribute = price / 2;

        _ctSign("TXPS_T_STEP_1");
        _collateralTransfer(PreSalesOP, amountDistribute);

        _ctSign("TXPS_T_STEP_2");
        _collateralTransfer(PreSalesMk, amountDistribute);
    }

    function _taxDistribution(uint256 price) internal {
        uint256 taxAmount = (tax * price) / 100;

        uint256 amountDistribute = taxAmount / 5;

        uint256 amountHalf = amountDistribute / 2;
        uint256 amountHalf2 = (amountDistribute / 4) * 3;

        _ctSign("TX_T_STEP_1");
        _collateralTransfer(WosStakingAddress, amountDistribute); //1%

        _ctSign("TX_T_STEP_2.1");
        _collateralTransfer(OpWallet, amountHalf2); //0.75%

        _ctSign("TX_T_STEP_2.2");
        _collateralTransfer(SLWallet, amountHalf2); //0.75%

        _ctSign("TX_T_STEP_3");
        _collateralTransfer(Agregadores, amountHalf); //0.5%

        _ctSign("TX_T_STEP_4");
        _collateralTransfer(DG, amountDistribute); //1%

        _ctSign("TX_T_STEP_5");
        _collateralTransfer(JS, amountDistribute); //1%
    }
}