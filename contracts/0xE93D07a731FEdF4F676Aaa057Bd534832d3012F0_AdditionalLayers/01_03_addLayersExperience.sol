// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISoulsLocker {
    function getSoulsInHero(uint256 heroId) external view returns (uint16[] memory);
}

struct AddLayer {
    uint128 layer;
    uint128 id;
}

contract AdditionalLayers is Ownable {

    event NewAddLayer(uint256 indexed heroId, AddLayer newLayer);
    event TransferLayer(uint256 indexed from, uint256 indexed to, uint256 index);
    event TransferAllLayers(uint256 indexed from, uint256 indexed to);

    ISoulsLocker public immutable locker; 

    // optional, not active by default
    bool public transfersActive;

    // addLayers storage
    mapping(uint256 => AddLayer[]) public heroToAddLayers;

    // contracts allowed to mint layers
    // we keep on adding them and do not re-use indexes
    // we can close the minter contracts once the job is done or set that index to address(0)
    // minters[0] is the owner, minters[1] the first exp spender contract
    address[] public minters;

    // mainnet = 0xe93d07a731fedf4f676aaa057bd534832d3012f0 // testnet = 0xB7996CC6532f3Faa63e7CEA16Ee6DcD97D1EF6fD 
    constructor(address locker_) { 
        //mainnet = 0x1eb4490091bd0fFF6c3973623C014D082936EA03, testnet = 0xb8B7136036805111dfc27437F121aFB75E21df69
        locker = ISoulsLocker(locker_);
        // set owner as a minter for aidrops
        minters.push(msg.sender); 
    }

    //////
    // ADMIN FUNCTIONS
    //////

    // Activates addLayers transfers - optional for future needs
    function activateTransfers(bool flag) external onlyOwner {
        transfersActive = flag;
    }

    function addMinter(address minterAddress) external onlyOwner {
        minters.push(minterAddress);
    }

    function updateMinter(address minterAddress, uint256 minterIdx) external onlyOwner {
        minters[minterIdx] = minterAddress;
    }

    //////
    // MINT LAYERS
    //////

    function mintAddLayer(uint256 heroId, AddLayer calldata newLayer, uint256 minterIdx) external {
        require(msg.sender == minters[minterIdx], "Minter not valid");

        heroToAddLayers[heroId].push(newLayer);
        emit NewAddLayer(heroId, newLayer);
    }

    function mintAddLayerBatch(uint256[] memory heroId, AddLayer calldata newLayer, uint256 minterIdx) external {
        require(msg.sender == minters[minterIdx], "Minter not valid");

        for(uint256 i = 0; i < heroId.length; ) {
            heroToAddLayers[heroId[i]].push(newLayer);
            emit NewAddLayer(heroId[i], newLayer);

            unchecked {
                ++i;
            }
        }
    }

    //////
    // TRANSFER ALL LAYERS (Default Not active)
    //////

    function transferAllLayers(uint256 heroFromId, uint256 heroToId, uint256 minterIdx) external  {
        require(transfersActive, "Not Active");
        require(msg.sender == minters[minterIdx], "Minter not valid"); 

        heroToAddLayers[heroToId] = heroToAddLayers[heroFromId];
        delete heroToAddLayers[heroFromId];

        emit TransferAllLayers(heroFromId, heroToId);
    }

    //////
    // TRANSFER ONE LAYER (Default Not active)
    //////

    function transferOneLayer(uint256 heroFromId, uint256 heroToId, uint256 index, uint256 minterIdx) external {
        require(transfersActive, "Not Active");
        require(msg.sender == minters[minterIdx], "Minter not valid"); 

        AddLayer[] storage from = heroToAddLayers[heroFromId]; //pointer
        AddLayer[] storage to = heroToAddLayers[heroToId]; //pointer

        to.push(from[index]); // add element at index to heroTo
        from[index] = from[from.length - 1]; // swap element to delete with last
        from.pop(); // delete last element that was moved

        emit TransferLayer(heroFromId, heroToId, index);
    }

    //////
    // READ LAYERS
    //////

    function getHeroLayers(uint256 heroId) external view returns (AddLayer[] memory) {
        return heroToAddLayers[heroId];
    }

    // check layer is in Hero
    function isLayerInHero(uint256 heroId, uint256 layer, uint256 layerId) public view returns (bool) {
        AddLayer[] memory layersInHero = heroToAddLayers[heroId];

        for(uint256 i = 0; i < layersInHero.length; i++) {
            if(layersInHero[i].layer == layer && layersInHero[i].id == layerId) {
                return true;
            }
        }

        return false;
    }

    // this one checks all the internal souls NOT the main token, 
    function isLayerInSouls(uint256 heroId, uint256 layer, uint256 layerId) public view returns (bool) {
        uint16[] memory souls = locker.getSoulsInHero(heroId);

        AddLayer[] memory layersInHero;

        for(uint256 j = 0; j < souls.length; j++) {
            layersInHero = heroToAddLayers[souls[j]];

            for(uint256 i = 0; i < layersInHero.length; i++) {
                if(layersInHero[i].layer == layer && layersInHero[i].id == layerId) {
                    return true;
                }
            }
        }
        return false;
    }

    // this one checks all the internal souls AND the main token
    function isLayerInHeroOrSouls(uint256 heroId, uint256 layer, uint256 layerId) public view returns (bool) {
        //checks if addLayer is in main hero
        if(isLayerInHero(heroId, layer, layerId)){
            return true;
        }

        // checks internal souls
        uint16[] memory souls = locker.getSoulsInHero(heroId);

        for(uint256 i = 0; i < souls.length; i++) {
            if(isLayerInHero(souls[i], layer, layerId)){
                return true;
            }      
        }
        
        return false;
    }

}