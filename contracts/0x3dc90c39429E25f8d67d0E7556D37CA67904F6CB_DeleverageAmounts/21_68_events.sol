//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {
    event updateAuthLog(address auth_);

    event updateRebalancerLog(address auth_, bool isAuth_);

    event updateRatiosLog(
        uint16 maxLimit,
        uint16 minLimit,
        uint16 gap,
        uint128 maxBorrowRate
    );

    event updateFeesLog(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    );

    event changeStatusLog(uint256 status_);

    event supplyLog(address token_, uint256 amount_, address to_);

    event withdrawLog(uint256 amount_, address to_);

    event leverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageAndWithdrawLog(
        uint256 deleverageAmt_,
        uint256 transferAmt_,
        uint256 vtokenAmount_,
        address to_
    );

    event importLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address to_,
        uint256 stEthAmt_,
        uint256 wethAmt_
    );

    event rebalanceOneLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] vaults_,
        uint256[] amts_,
        uint256 excessDebt_,
        uint256 paybackDebt_,
        uint256 totalAmountToSwap_,
        uint256 extraWithdraw_,
        uint256 unitAmt_
    );

    event rebalanceTwoLog(
        uint256 withdrawAmt_,
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_
    );

    event collectRevenueLog(
        uint256 amount_,
        uint256 stethAmt_,
        uint256 wethAmt_,
        address to_
    );
}