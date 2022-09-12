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

abstract contract GettersController {
    function getCirculatingSupply() external view returns (uint256) {
        return LibProtocolX.getCirculatingSupply();
    }

    function balanceForGons(uint256 gons) external view returns (uint256) {
        return LibProtocolX.balanceForGons(gons);
    }

    function gonsForBalance(uint256 amount) external view returns (uint256) {
        return LibProtocolX.gonsForBalance(amount);
    }

    function index() external view returns (uint256) {
        return LibProtocolX.index();
    }

    function getRebaseRate() external view returns (uint256) {
        return LibProtocolX.getRebaseRate();
    }

    function getLastRebasedTime() external view returns (uint256) {
        return LibProtocolX.getLastRebasedTime();
    }

    function getReceivers()
        external
        view
        returns (
            address autoLiquidityReceiver,
            address treasuryReceiver,
            address xshareFundReceiver,
            address afterburner
        )
    {
        return LibProtocolX.getReceivers();
    }
}