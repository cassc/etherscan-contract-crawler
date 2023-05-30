// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './SolidarityBase.sol';
import './SolidaritySplits.sol';

/**
 * @title JR - Can Art Change the War?
 *
 * A Solidarity NFT Project for Ukraine
 * Companion to the TIME 'Resilience of Ukraine' Cover
 * Created by JR, Executed by Digital Practice
 * Smart Contract and Front End by NFT Culture Labs
 *
 *      ██████╗ █████╗ ███╗   ██╗     █████╗ ██████╗ ████████╗    
 *     ██╔════╝██╔══██╗████╗  ██║    ██╔══██╗██╔══██╗╚══██╔══╝    
 *     ██║     ███████║██╔██╗ ██║    ███████║██████╔╝   ██║       
 *     ██║     ██╔══██║██║╚██╗██║    ██╔══██║██╔══██╗   ██║       
 *     ╚██████╗██║  ██║██║ ╚████║    ██║  ██║██║  ██║   ██║       
 *      ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       
 *                                                                
 *          ██████╗██╗  ██╗ █████╗ ███╗   ██╗ ██████╗ ███████╗    
 *         ██╔════╝██║  ██║██╔══██╗████╗  ██║██╔════╝ ██╔════╝    
 *         ██║     ███████║███████║██╔██╗ ██║██║  ███╗█████╗      
 *         ██║     ██╔══██║██╔══██║██║╚██╗██║██║   ██║██╔══╝      
 *         ╚██████╗██║  ██║██║  ██║██║ ╚████║╚██████╔╝███████╗    
 *          ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝    
 *                                                                
 * ████████╗██╗  ██╗███████╗    ██╗    ██╗ █████╗ ██████╗ ██████╗ 
 * ╚══██╔══╝██║  ██║██╔════╝    ██║    ██║██╔══██╗██╔══██╗╚════██╗
 *    ██║   ███████║█████╗      ██║ █╗ ██║███████║██████╔╝  ▄███╔╝
 *    ██║   ██╔══██║██╔══╝      ██║███╗██║██╔══██║██╔══██╗  ▀▀══╝ 
 *    ██║   ██║  ██║███████╗    ╚███╔███╔╝██║  ██║██║  ██║  ██╗   
 *    ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═╝   
 *
 * Credit to https://patorjk.com/ for text generator.
 */
contract SolidarityNFTProjectForUkraine is SolidaritySplits, SolidarityBase {
    constructor()
        SolidarityBase(
            "SolidarityNFTForUkraine",
            "Sol4U",
            0x7397f20B4B2eBcd385860718082f6D3e59c1654d, // SolidarityMetadata Mainnet Address.
            addresses,
            splits
        )
    {
        // Implementation version: 1
    }
}