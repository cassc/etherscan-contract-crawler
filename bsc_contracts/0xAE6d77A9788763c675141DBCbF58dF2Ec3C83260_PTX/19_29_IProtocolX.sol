// SPDX-License-Identifier: MIT

// Developed by:
//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

interface IProtocolX {
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountETHToTreasuryAndTIF
    );
    event SetRebaseRate(uint256 indexed rebaseRate);
    event UpdateAutoRebaseStatus(bool status);
    event UpdateAutoAddLiquidityStatus(bool status);
    event UpdateAutoSwapStatus(bool status);
    event UpdateFeeReceivers(
        address liquidityReceiver,
        address treasuryReceiver,
        address xshareFundReceiver,
        address afterburner
    );

    event UpdateExemptFromFees(address account, bool flag);
    event UpdateExemptFromRebase(address account, bool flag);
    event UpdateDefaultOperator(address account, bool flag);
}