// SPDX-License-Identifier: MIT

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity 0.8.11;

import {AaveV2Ethereum} from "aave-address-book/AaveV2Ethereum.sol";

interface IProposalGenericExecutor {
    function execute() external;
}

interface IEcosystemReserveController {
    /**
     * @notice Proxy function for ERC20's approve(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Allowance's recipient
     * @param amount Allowance to approve
     *
     */
    function approve(address collector, address token, address recipient, uint256 amount) external;
}

interface ISwapper {
    function swapAllAvailable() external;
}

/**
 * @author Llama
 * @dev This proposal setups the permissions for a Swapper contract to swap all the available aFEI to aDAI in the AAVE_MAINNET_RESERVE_FACTOR. It also immediatly tries to swap all the available aFEI to aDAI using the swapper.
 * Governance Forum Post: https://governance.aave.com/t/arc-ethereum-v2-reserve-factor-afei-holding-update/9401
 * Parameter snapshot: https://snapshot.org/#/aave.eth/proposal/0x519f6ecb17b00eb9c2c175c586173b15cfa5199247903cda9ddab48763ddb035
 */
contract RedeemFei is IProposalGenericExecutor {
    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    ISwapper public immutable SWAPPER;

    constructor(address swapper) {
        SWAPPER = ISwapper(swapper);
    }

    function execute() external override {
        IEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).approve(
            AaveV2Ethereum.COLLECTOR, A_FEI, address(SWAPPER), type(uint256).max
        );
        SWAPPER.swapAllAvailable();
    }
}