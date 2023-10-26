/*
 /$$$$$$$$                     /$$$$$$$$                                          /$$          
| $$_____/                    | $$_____/                                         |__/          
| $$        /$$$$$$   /$$$$$$$| $$     /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$      /$$  /$$$$$$ 
| $$$$$    /$$__  $$ /$$_____/| $$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$    | $$ /$$__  $$
| $$__/   | $$  \__/| $$      | $$__/| $$  \ $$| $$  \__/| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
| $$      | $$      | $$      | $$   | $$  | $$| $$      | $$  | $$| $$_____/    | $$| $$  | $$
| $$$$$$$$| $$      |  $$$$$$$| $$   |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$ /$$| $$|  $$$$$$/
|________/|__/       \_______/|__/    \______/ |__/       \____  $$ \_______/|__/|__/ \______/ 
                                                          /$$  \ $$                            
                                                         |  $$$$$$/                            
                                                          \______/                             
*/
//SPDX-License-Identifier: CC-BY-NC-ND

pragma solidity ^0.8.0;

interface IErcForgeInitiable {
    function init(
            address newOwner, 
            string memory newName, 
            string memory newSymbol, 
            string memory newBaseTokenURI, 
            string memory newContractUri) external;
}