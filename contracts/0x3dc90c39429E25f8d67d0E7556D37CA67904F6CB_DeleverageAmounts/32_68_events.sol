//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../common/helpers.sol";

contract Events is Helpers {
    event collectProfitLog(
        bool isWeth,
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_
    );

    event rebalanceOneLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] vaults_,
        uint256[] amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_,
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_
    );

    event rebalanceTwoLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_
    );
}