// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './NoobPunksBase.sol';
import './NoobPunksSplits.sol';

/**
 * @title NOOBPUNKS wrapper contract
 *          __________
 *   _   _ / ___   ___\  ____  _____  _    _ _   _ _  __ _____ 
 *  | \ | |/ __ \ / __ \|  _ \|  __ \| |  | | \ | | |/ // ____|
 *  |  \| | | *| | | *| | |_) | |__) | |  | |  \| | ' /| (___  
 *  | . ` | |__| | |__| |  _ <|  ___/| |  | | . ` |  <  \___ \ 
 *  | |\  |      |      | |_) | |    | |__| | |\  | . \ ____) |
 *  |_| \_|\____/ \____/|____/|_|     \____/|_| \_|_|\_\_____/ 
 *         \__________/                                        
 *
 * Credit to https://patorjk.com/ for text generator.
 */
contract NoobPunks is NoobPunksSplits, NoobPunksBase {
    constructor()
        NoobPunksBase(
            'NOOBPUNKS',
            'NBPKS',
            'https://gateway.pinata.cloud/ipfs/Qmc9Ut3DUNhybDFWrGhrSfPttVH15HNCKErzhew8BkKL8V/', //pre-reveal v2
            addresses,
            splits
        )
    {
        // Implementation version: 1
    }
}