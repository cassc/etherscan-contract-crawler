// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//        ___       ___                    ___           ___                       ___           ___     
//       /\__\     /\  \                  /\  \         /\__\          ___        /\__\         /\  \    
//      /:/  /    /::\  \                /::\  \       /::|  |        /\  \      /::|  |       /::\  \   
//     /:/  /    /:/\:\  \              /:/\:\  \     /:|:|  |        \:\  \    /:|:|  |      /:/\:\  \  
//    /:/  /    /::\~\:\  \            /::\~\:\  \   /:/|:|  |__      /::\__\  /:/|:|__|__   /::\~\:\  \ 
//   /:/__/    /:/\:\ \:\__\          /:/\:\ \:\__\ /:/ |:| /\__\  __/:/\/__/ /:/ |::::\__\ /:/\:\ \:\__\
//   \:\  \    \:\~\:\ \/__/          \/__\:\/:/  / \/__|:|/:/  / /\/:/  /    \/__/~~/:/  / \:\~\:\ \/__/
//    \:\  \    \:\ \:\__\                 \::/  /      |:/:/  /  \::/__/           /:/  /   \:\ \:\__\  
//     \:\  \    \:\ \/__/                 /:/  /       |::/  /    \:\__\          /:/  /     \:\ \/__/  
//      \:\__\    \:\__\                  /:/  /        /:/  /      \/__/         /:/  /       \:\__\    
//       \/__/     \/__/                  \/__/         \/__/                     \/__/         \/__/    


import "./../merge/Anime2Merger.sol";

interface IAddLayers {
    function isLayerInHeroOrSouls(uint256 heroId, uint256 layer, uint256 layerId) external view returns (bool);
}

interface ISoulsLocker {
    function getSoulsInHero(uint256 heroId) external view returns (uint16[] memory);
}

interface IMergerURIV4 {
    function checkHeroValidity(uint256 heroId) external view returns (uint256);
    function getRankThresholds() external view returns (uint256[] memory);
}

struct Addlayer {
    uint128 layer;
    uint128 id;
}

///////////////////////
// CUSTOM URI CONTRACT
///////////////////////

contract TokenURICustomV4 {
    //base URI for unlocked, locked base tokens
    string public constant BASE_URI = "https://leanime.art/heroes/metadata_unlocked/";
    string public constant BASE_URI_LOCKED = "https://leanime.art/heroes/metadata_locked/";

    //base URI for heroes
    string public constant HERO_URI = "https://api.leanime.art/heroes/metadata/";
    
    // Merger Interface
    IMergerURIV4 public immutable merger;

    // Hero Data Storage 
    HeroDataStorage public immutable heroStorage;

    // Wrapper Interface
    IWrapper public immutable wrapper;

    // AddLayers Interface
    IAddLayers public immutable additionalLayers;

    // Locker address
    ISoulsLocker public immutable locker; 


    constructor(address wrapperAddress_, address mergerAddress_, address heroStorage_, address locker_, address additionalLayers_) {
        wrapper = IWrapper(wrapperAddress_); 
        merger = IMergerURIV4(mergerAddress_); 
        heroStorage = HeroDataStorage(heroStorage_); 
        locker = ISoulsLocker(locker_); 
        additionalLayers = IAddLayers(additionalLayers_);       
    }

    //////
    // URI Functions
    //////

    // Constructs the URI - called by tokenURI(tokenId) in the main ERC721 contract
    function constructTokenURI(uint256 tokenId) external view returns (string memory) {
        string memory str = "H";

        uint256 heroId = tokenId - 100000;

        // Minimal hero parameters
        uint256 score = merger.checkHeroValidity(heroId);
        
        if(score > 0) {
            str = string(abi.encodePacked(Strings.toString(heroId), "S" , Strings.toString(score), str));
            heroParams memory dataHero = heroStorage.getData(heroId);
            
            
            bytes memory params = dataHero.params;

            for (uint256 i = 0; i < params.length; i++){
                str = string(abi.encodePacked(str, itoh8(uint8(params[i]))));
            }
            
            // Fixed BG encoding
            str = string(abi.encodePacked(str, "G"));
            str = string(abi.encodePacked(str, itoh8(dataHero.visibleBG)));

            // Handle Additional layers encoding
            if(dataHero.extraLayers.length > 0) {
                (string memory addLayerStr, bool addLayerValid) = additionalLayersURI(heroId, dataHero.extraLayers);
                if(!addLayerValid) {
                    return spiritsURI(tokenId);
                }
                str = string(abi.encodePacked(str, addLayerStr));
            }
            
            str = string(abi.encodePacked(HERO_URI, str));
        }
        else {
            str = spiritsURI(tokenId);      
        }
        return str;
    }

    // URI for single spirits, anime and fallback static URI
    function spiritsURI(uint256 tokenId) internal view returns (string memory) {
        if(wrapper.ownerOf(tokenId) == address(locker)) {
                //return a locked token metadata
                return string(abi.encodePacked(BASE_URI_LOCKED, Strings.toString(tokenId)));   
            }
        else {
                //return an unlocked token metadata
                return string(abi.encodePacked(BASE_URI, Strings.toString(tokenId)));
            }  
    }

    // Constructs the AdditionalLayers URI string part
    function additionalLayersURI(uint256 heroId, bytes memory addParams) public view returns (string memory, bool valid) {
        if(addParams.length % 4 != 0) {
            return ("", false); //returns "" when invalid encoding
        }

        string memory tempStr = ""; //
        for (uint256 i = 0; i < addParams.length; i += 4){
            // check if additional layer is in hero or hero souls
            if(!additionalLayers.isLayerInHeroOrSouls(
                heroId, 
                bytes2ToUint(addParams[i], addParams[i + 1]),  // layer
                bytes2ToUint(addParams[i + 2], addParams[i + 3]) // layerId
                )) {
                return ("", false); // "" when invalid layer
            }

            // if checks passed, encodes additional layers
            tempStr = string(abi.encodePacked(tempStr, "X"));
            if(uint8(addParams[i]) != 0) {
                tempStr = string(abi.encodePacked(tempStr, itoh8(uint8(addParams[i]))));
            }
            tempStr = string(abi.encodePacked(tempStr, itoh8(uint8(addParams[i + 1]))));

            tempStr = string(abi.encodePacked(tempStr, "L"));
            if(uint8(addParams[i + 2]) != 0) {
                tempStr = string(abi.encodePacked(tempStr, itoh8(uint8(addParams[i + 2]))));
            }
            tempStr = string(abi.encodePacked(tempStr, itoh8(uint8(addParams[i + 3]))));

        }

        return (tempStr, true);

    }

    //////
    // UTILS 
    //////
    
    // Converts uint8 into hex string
    function itoh8(uint8 x) private pure returns (string memory) {
        if (x > 0) {
            string memory str;
            uint8 temp = x;
            
            str = string(abi.encodePacked(uint8(temp % 16 + (temp % 16 < 10 ? 48 : 87)), str));
            temp /= 16;
            str = string(abi.encodePacked(uint8(temp % 16 + (temp % 16 < 10 ? 48 : 87)), str));
            
            return str;
        }
        return "00";
    }

    // Converts 2 bytes into uint16
    function bytes2ToUint(bytes1 b0, bytes1 b1) private pure returns (uint256){
        uint256 num = uint8(b0) * 256 + uint8(b1);
        return num;
    }

}