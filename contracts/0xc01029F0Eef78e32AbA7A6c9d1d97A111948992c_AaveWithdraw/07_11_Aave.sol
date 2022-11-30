// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant AAVE_LENDING_POOL = "AaveLendingPool";
string constant AAVE_WETH_GATEWAY = "AaveWethGateway";

/**
 * @dev We do not include patch versions in contract names to allow
 * for hotfixes of Action contracts
 * and to limit updates to TheGraph
 * if the types encoded in emitted events change then use a minor version and
 * update the ServiceRegistry with a new entry
 * and update TheGraph decoding accordingly
 */
string constant BORROW_ACTION = "AaveBorrow_2";
string constant DEPOSIT_ACTION = "AaveDeposit_2";
string constant WITHDRAW_ACTION = "AaveWithdraw_2";
string constant PAYBACK_ACTION = "AavePayback_2";