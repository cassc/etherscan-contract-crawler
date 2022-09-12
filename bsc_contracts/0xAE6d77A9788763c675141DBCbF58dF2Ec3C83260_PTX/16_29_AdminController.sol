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

import {LibProtocolX} from "../libraries/LibProtocolX.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

abstract contract AdminController {
    function setAutoRebase(bool flag) external {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setAutoRebase(flag);
    }

    function setSwapEnabled(bool flag) external {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setSwapEnabled(flag);
    }

    function setAutoAddLiquidity(bool flag) external {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setAutoAddLiquidity(flag);
    }

    function setRebaseRate(uint256 rebaseRate) external {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setRebaseRate(rebaseRate);
    }

    function setFeeReceivers(
        address autoLiquidityReceiver,
        address treasuryReceiver,
        address insuranceFundReceiver,
        address afterburner
    ) external {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setFeeReceivers(
            autoLiquidityReceiver,
            treasuryReceiver,
            insuranceFundReceiver,
            afterburner
        );
    }

    function setExemptFromFees(address account, bool flag) external {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setExemptFromFees(account, flag);
    }

    function setExemptFromRebase(address account, bool flag) external {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setExemptFromRebase(account, flag);
    }
}