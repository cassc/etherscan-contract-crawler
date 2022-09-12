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

import {ERC20Controller} from "./controllers/ERC20Controller.sol";
import {GettersController} from "./controllers/GettersController.sol";
import {AdminController} from "./controllers/AdminController.sol";
import {SimpleBlacklistController} from "./blacklist/SimpleBlacklistController.sol";
import {PausableController} from "./pausable/PausableController.sol";
import {LibProtocolX} from "./libraries/LibProtocolX.sol";
import {LibPausable} from "./pausable/LibPausable.sol";
import {LibUtils} from "./libraries/LibUtils.sol";

import {IProtocolX} from "./interfaces/IProtocolX.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Main contract assembling all the controllers.
 *
 * Attention: Initializable is the only contract that does not use the
 * Diamond Storage pattern and MUST be on first possition ALLWAYS!!!
 */
contract PTX is
    Initializable,
    ERC20Controller,
    SimpleBlacklistController,
    PausableController,
    AdminController,
    GettersController,
    IProtocolX
{
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 startTime,
        address autoLiquidityReceiver,
        address treasuryReceiver,
        address xshareFundReceiver,
        address afterburner,
        IUniswapV2Router02 router,
        address[] memory exemptFromRebase
    ) public initializer {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.init(
            name_,
            symbol_,
            startTime,
            autoLiquidityReceiver,
            treasuryReceiver,
            xshareFundReceiver,
            afterburner,
            router,
            exemptFromRebase
        );
    }

    function upgradeToPrepareForLaunch(
        IUniswapV2Router02 router,
        address[] calldata exemptFromPause
    ) public reinitializer(2) {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.updateRouterAndCreatePair(router);

        (
            address autoLiquidityReceiver,
            address treasuryReceiver,
            address xshareFundReceiver,
            address afterburner
        ) = LibProtocolX.getReceivers();

        LibPausable.setExemptFromPause(autoLiquidityReceiver, true);
        LibPausable.setExemptFromPause(treasuryReceiver, true);
        LibPausable.setExemptFromPause(xshareFundReceiver, true);
        LibPausable.setExemptFromPause(afterburner, true);

        for (uint256 index = 0; index < exemptFromPause.length; ++index) {
            LibPausable.setExemptFromPause(exemptFromPause[index], true);
        }
    }

    function upgradeToAddDefaultOperator(address operator)
        public
        reinitializer(3)
    {
        LibUtils.enforceIsContractOwner();

        LibProtocolX.setDefaultOperator(operator, true);
    }

    function upgradeLaunchTheProject() public reinitializer(4) {
        LibUtils.enforceIsContractOwner();

        (address autoLiquidityReceiver, , , ) = LibProtocolX.getReceivers();
        LibProtocolX.setExemptFromFees(autoLiquidityReceiver, true);

        LibProtocolX.setSwapEnabled(true);
        LibProtocolX.setAutoAddLiquidity(true);
        LibProtocolX.setAutoRebase(true);

        LibPausable.unpause();
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}