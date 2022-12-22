// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

interface GameLevel {
    function sortedAttributes(uint256 _tokenId) external view returns (uint16[6] memory);
}
interface GameNFTProxy {
    function level(uint256 _tokenId) external view returns (uint16);
}

contract MockLevel is Ownable {

    GameLevel gameLevel;
    GameNFTProxy nftProxy;

    constructor(GameLevel _gameLevel, GameNFTProxy _nftProxy) {
        gameLevel = _gameLevel;
        nftProxy = _nftProxy;
    }

    function setGameLevel(GameLevel _gameLevel) external onlyOwner {
        gameLevel = _gameLevel;
    }

    function setNftProxy(GameNFTProxy _nftProxy) external onlyOwner {
        nftProxy = _nftProxy;
    }

    event UpgradeLevel(uint256 indexed tokenId, uint16 newLevel, uint16[6] attributes);

    function updateLevel(uint[] memory tokenId, uint16[] memory newLevel, uint16[] memory attributes) external onlyOwner {
        require(tokenId.length == newLevel.length, "illegal length");
        require(tokenId.length * 6 == attributes.length, "illegal attributes length");
        uint attributeIndex = 0;
        for (uint i = 0; i < tokenId.length; i ++) {
            uint16[6] memory currentAttributes = [attributes[attributeIndex + 0], attributes[attributeIndex + 1], attributes[attributeIndex + 2], attributes[attributeIndex + 3], attributes[attributeIndex + 4], attributes[attributeIndex + 5]];
            emit UpgradeLevel(tokenId[i], newLevel[i], currentAttributes);
            attributeIndex = attributeIndex + 6;
        }
    }

    function syncLevel(uint[] memory tokenIds) external onlyOwner {
        for (uint i = 0; i < tokenIds.length; i ++) {
            uint tokenId = tokenIds[i];
            uint16 level = nftProxy.level(tokenId);
            uint16[6] memory attributes = gameLevel.sortedAttributes(tokenId);
            emit UpgradeLevel(tokenId, level, attributes);
        }
    }

}