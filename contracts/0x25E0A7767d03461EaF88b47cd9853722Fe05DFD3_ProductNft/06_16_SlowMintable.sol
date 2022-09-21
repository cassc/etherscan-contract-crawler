//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract SlowMintable {

    mapping(string => uint16) public tokensLeftToMintPerRarityPerBatch; 

    event NewBatchAllowed(string rarity, uint256 batchAmount);

    modifier slowMintStatus(string memory rarity) {
        require(tokensLeftToMintPerRarityPerBatch[rarity] > 0, "Batch sold out");
        _;
    }
    
    function _setTokensToMintPerRarity(uint16 amount, string memory rarity) internal returns (uint16) {
        tokensLeftToMintPerRarityPerBatch[rarity] = amount;
        emit NewBatchAllowed(rarity, amount);
        return amount;
    }

}