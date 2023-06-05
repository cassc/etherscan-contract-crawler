//
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   _________   _____      _____ _____________________    _____     __      __________ __________.____     ________    //
// /    _____/  /     \    /  _  \\______   \__    ___/   /  _  \   /  \    /  \_____  \\______   \    |    \______ \   //
//  \_____  \  /  \ /  \  /  /_\  \|       _/ |    |     /  /_\  \  \   \/\/   //   |   \|       _/    |     |    |  \  //
//  /        \/    Y    \/    |    \    |   \ |    |    /    |    \  \        //    |    \    |   \    |___  |    `   \ //
// /_______  /\____|__  /\____|__  /____|_  / |____|    \____|__  /   \__/\  / \_______  /____|_  /_______ \/_______  / //
//         \/         \/         \/       \/                    \/         \/          \/       \/        \/        \/  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract SmartAworld is ERC1155PresetMinterPauser, Ownable {

    string public name = "SmartAWorld";
    string public symbol = "SMARTAWORLD"; 
    
    string public contractUri = "https://nft.smart-a.world/contract"; 

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

    

    function mintMass(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length, "SmartAworld: to and id length mismatch");
        require(to.length == amount.length, "SmartAworld: to and amount length mismatch");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }

    }
}