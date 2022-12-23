// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "src/interfaces/IERC20.sol";
import "src/interfaces/curve/IMetaPool.sol";
import "src/interfaces/curve/IZapDepositor3pool.sol";

abstract contract CurvePoolAdapter {

    IERC20 public dola;
    IMetaPool public crvMetapool;
    uint public constant PRECISION = 10_000;
    uint public immutable CRVPRECISION = 10**18;

    constructor(address dola_, address crvMetapool_){
        dola = IERC20(dola_);
        crvMetapool = IMetaPool(crvMetapool_);
        //Approve max uint256 spend for crvMetapool, from this address
        dola.approve(crvMetapool_, type(uint256).max);
        IERC20(crvMetapool_).approve(crvMetapool_, type(uint256).max);
    }
    /**
    @notice Function for depositing into curve metapool.

    @param amountDola Amount of dola to be deposited into metapool

    @param allowedSlippage Max allowed slippage. 1 = 0.01%

    @return Amount of Dola-3CRV tokens bought
    */
    function metapoolDeposit(uint256 amountDola, uint allowedSlippage) internal returns(uint256){
        //TODO: Should this be corrected for 3CRV virtual price?
        uint[2] memory amounts = [amountDola, 0];
        uint minCrvLPOut = amountDola * CRVPRECISION / crvMetapool.get_virtual_price() * (PRECISION - allowedSlippage) / PRECISION;
        return crvMetapool.add_liquidity(amounts, minCrvLPOut);
    }

    /**
    @notice Function for depositing into curve metapool.

    @param amountDola Amount of dola to be withdrawn from the metapool

    @param allowedSlippage Max allowed slippage. 1 = 0.01%

    @return Amount of Dola tokens received
    */
    function metapoolWithdraw(uint amountDola, uint allowedSlippage) internal returns(uint256){
        uint[2] memory amounts = [amountDola, 0];
        uint amountCrvLp = crvMetapool.calc_token_amount( amounts, false);
        uint expectedCrvLp = amountDola * CRVPRECISION / crvMetapool.get_virtual_price();
        //The expectedCrvLp must be higher or equal than the crvLp amount we supply - the allowed slippage
        require(expectedCrvLp >= applySlippage(amountCrvLp, allowedSlippage), "LOSS EXCEED WITHDRAW MAX LOSS");
        uint dolaMinOut = applySlippage(amountDola, allowedSlippage);
        return crvMetapool.remove_liquidity_one_coin(amountCrvLp, 0, dolaMinOut);
    }

    function applySlippage(uint amount, uint allowedSlippage) internal pure returns(uint256){
        return amount * (PRECISION - allowedSlippage) / PRECISION;
    }

    function lpForDola(uint amountDola) internal view returns(uint256){
        uint[2] memory amounts = [amountDola, 0];
        return crvMetapool.calc_token_amount(amounts, false);
    }
}