// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";


interface FeiSwapper {
    function swapAllAvailable() external;
}

/**
 * @title Aave FEI Reserve Factor Update
 * @author Llama
 * @notice This payload sets the reserve factor to 99% for FEI in Aave v2 pool on mainnet
 * Reference: https://wheat-guardian-dfc.notion.site/Problem-with-FEI-Reserve-Factor-100b6413e359494a9ecb59a528035ff2
 * Governance Forum Post: https://governance.aave.com/t/bgd-aave-v2-ethereum-fei-security-report/10251
 */
contract ProposalPayload {
    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    address public constant A_FEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

    FeiSwapper public constant FEI_SWAPPER = FeiSwapper(0x9A953AC1090C7014D00FD205D89c6BA1C219Af8b);

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveFactor(FEI, 9_900);
        
        // claim available liquidity and update index
        if (IERC20(FEI).balanceOf(A_FEI) > 0) {
            FEI_SWAPPER.swapAllAvailable();
        }
    }
}