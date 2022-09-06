// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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


// import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";

// import "@openzeppelin/contracts/utils/Strings.sol";

// import "@rari-capital/solmate/src/utils/SSTORE2.sol";

import "./Anime2Merger.sol";

///////////////////////
// CUSTOM URI CONTRACT
///////////////////////

contract TokenURICustom_V2 {
    // Merger Interface
    IMergerURI public merger;

    // Hero Data Storage 
    HeroDataStorage public heroStorage;

    // Wrapper Interface
    IWrapper public wrapper;

    // Locker address
    address public locker;

    //base URI for unlocked, locked base tokens
    string public baseURI = "https://leanime.art/heroes/metadata_unlocked/";
    string public baseURI_locked = "https://leanime.art/heroes/metadata_locked/";

    //base URI for heroes
    string public heroURI = "https://api.leanime.art/heroes/metadata/";

    constructor(address wrapperAddress_, address mergerAddress_, address heroStorage_, address locker_) {
        wrapper = IWrapper(wrapperAddress_);
        merger = IMergerURI(mergerAddress_);
        heroStorage = HeroDataStorage(heroStorage_);
        locker = locker_;
    }

    function constructTokenURI(uint256 tokenId) external view returns (string memory) {
        string memory str = "H";

        uint256 heroId = tokenId - 100000;

        // minimal hero parameters
        uint256 score = merger.checkHeroValidity(heroId);
        
        if(score > 0) {
            str = string(abi.encodePacked(Strings.toString(heroId), "S" , Strings.toString(score), str));
            heroParams memory dataHero = heroStorage.getData(heroId);
            
            
            bytes memory params = dataHero.params;

            for (uint256 i = 0; i < params.length; i++){
                str = string(abi.encodePacked(str, itoh8(uint8(params[i]))));
            }
            
            //fixed BG
            str = string(abi.encodePacked(str, "G"));
            str = string(abi.encodePacked(str, itoh8(dataHero.visibleBG)));
            
            
            str = string(abi.encodePacked(heroURI, str));
        }
        else {
            if(wrapper.ownerOf(tokenId) == locker) {
            //return a locked token metadata
                str = string(abi.encodePacked(baseURI_locked, Strings.toString(tokenId)));   
            }
            else {
                //return a unlocked token metadata
                str = string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
            }      
        }
        return str;
    }
    
    // convert uint8 into hex string
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

    

}