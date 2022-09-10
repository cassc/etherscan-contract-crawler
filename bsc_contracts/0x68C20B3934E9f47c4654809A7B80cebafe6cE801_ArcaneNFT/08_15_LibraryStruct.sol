// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library NFTStruct {
    /*=== Structs ===*/
    struct CreateNFT {
        address payable userAdmin; // Dono da NFT
        uint256 idNFT; // ID da NFT
        uint256 initialValue; // Valor Inicial Aportado na NFT
        uint256 percentBoost; // Porcentagem de Boost da NFT
        uint256 valueBoost; // Valor Inicial + Boost
        uint256 startVesting; // Bloco Inicial do Periodo de Vesting
        uint256 endVesting; // Bloco Final do Periodo de Vesting
        uint256 startBlock; // Bloco Inicial do Stake
        string nameNFT; // Define o Nome da NFT
        bool isUser; // Verifica se é Dono dessa NFT
        bool isStaking; // Verifica se está em Staking
        bool isPrivateSale; // Verifica se está na Private-Sale
        bool isPreSale; // Verifica se está na Pre-Venda
        bool isShareholder; // Verifica se é Cotista
    }
    struct CountNFT {
        uint256 counter; 
    }
    


}
