//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "./ECNFT.sol";

contract LameloBallNFT is ECNFT {
    
    constructor() ECNFT(
        "LaMelo Ball Collectibles",                 // _name,
        "LBC",                                      // _symbol,
        1622829600,                                 // Fri Jun 04 2021 18:00:00 GMT+0000, _sale_start,
        1624644000,                                 // Fri Jun 25 2021 18:00:00 GMT+0000, _sale_end,
        0x678DaaAdb798AEFC47Ca036858e3B25698b3c24C, // _owner_wallet,
        0x05229d7A6218CE56Ef1386d634f1953A463aA065, // _creator_wallet,
        10,                                         // _creator_fee,
        0x97CA7FE0b0288f5EB85F386FeD876618FB9b8Ab8  //_ec_contract_address
    ) {

        setNewCardType( "Gold Sun"      ,    1,   500, 3,  2.6 ether );
        setNewCardType( "Silver Moon"   ,  501,  1500, 0,    1 ether );
        setNewCardType( "Blue Neptune"  , 1501,  3500, 0,  0.1 ether );
        setNewCardType( "Bronze Saturn" , 3501, 10000, 0, 0.01 ether );

        setDataFolder("https://lameloball.io/metadata/");

        setInitialised();

        setController( 0x5e306D44C9e8eA2d80Fb515FbBC63C9E267dCEA5 );
        
        retrieveSpecialCards( 0x90Dbd11d4842aE3b51cD0AB1ecC32bD8cD756307 );
        transferOwnership( 0x90Dbd11d4842aE3b51cD0AB1ecC32bD8cD756307 );

    }

}