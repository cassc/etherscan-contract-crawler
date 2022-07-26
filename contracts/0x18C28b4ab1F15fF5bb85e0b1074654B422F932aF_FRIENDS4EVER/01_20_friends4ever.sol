//
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  /$$$$$$$$ /$$$$$$$  /$$$$$$ /$$$$$$$$ /$$   /$$ /$$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$$ /$$    /$$ /$$$$$$$$ /$$$$$$$   //
// | $$_____/| $$__  $$|_  $$_/| $$_____/| $$$ | $$| $$__  $$ /$$__  $$| $$  | $$| $$_____/| $$   | $$| $$_____/| $$__  $$  //
// | $$      | $$  \ $$  | $$  | $$      | $$$$| $$| $$  \ $$| $$  \__/| $$  | $$| $$      | $$   | $$| $$      | $$  \ $$  //
// | $$$$$   | $$$$$$$/  | $$  | $$$$$   | $$ $$ $$| $$  | $$|  $$$$$$ | $$$$$$$$| $$$$$   |  $$ / $$/| $$$$$   | $$$$$$$/  //
// | $$__/   | $$__  $$  | $$  | $$__/   | $$  $$$$| $$  | $$ \____  $$|_____  $$| $$__/    \  $$ $$/ | $$__/   | $$__  $$  //
// | $$      | $$  \ $$  | $$  | $$      | $$\  $$$| $$  | $$ /$$  \ $$      | $$| $$        \  $$$/  | $$      | $$  \ $$  //
// | $$      | $$  | $$ /$$$$$$| $$$$$$$$| $$ \  $$| $$$$$$$/|  $$$$$$/      | $$| $$$$$$$$   \  $/   | $$$$$$$$| $$  | $$  //
// |__/      |__/  |__/|______/|________/|__/  \__/|_______/  \______/       |__/|________/    \_/    |________/|__/  |__/  //                                                                                                                
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//
// From Sarina and Marcel
// To Johanna and Bent
// By Djamila Fierek

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract FRIENDS4EVER is ERC1155PresetMinterPauser, Ownable {

    string public name = "FRIENDS4EVER";
    string public symbol = "FRIENDS4EVER";
    
    string public contractUri = "https://nft.smart-a.world/hamburg"; 

    constructor() ERC1155PresetMinterPauser("https://nft.smart-a.world/{id}") {
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

     function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    

    function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length, "Contract Info: to and id length mismatch");
        require(to.length == amount.length, "Contract Info: to and amount length mismatch");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }

    }
}