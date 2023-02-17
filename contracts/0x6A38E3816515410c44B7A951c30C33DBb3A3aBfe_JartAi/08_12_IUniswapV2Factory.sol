/*
     ____.  _____ _____________________    _____  .___ 
    |    | /  _  \\______   \__    ___/   /  _  \ |   |
    |    |/  /_\  \|       _/ |    |     /  /_\  \|   |
/\__|    /    |    \    |   \ |    |    /    |    \   |
\________\____|__  /____|_  / |____| /\ \____|__  /___|
                 \/       \/         \/         \/     


Transform words into stunning art 

Website: https://jart.ai/
Twitter: https://twitter.com/jart_ai
Telegram: https://t.me/jart_ai

Total supply: 420,690,000 tokens
Tax: 4% (1% - LP, 1% - operational costs, 2% marketing)
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IUniswapV2Factory {
    function createPair(address, address) external returns (address);

    function getPair(address, address) external view returns (address);
}