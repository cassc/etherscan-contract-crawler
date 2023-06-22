//
//
//
////////////////////////////////////////////////////////////////////////////////////////
// __________        .__                        ___ ___                     .__       //
// \______   \_____  |__| ____   ___________   /   |   \  ____  ______ ____ |  |__    //
//  |       _/\__  \ |  |/    \_/ __ \_  __ \ /    ~    \/  _ \/  ___// ___\|  |  \   //
//  |    |   \ / __ \|  |   |  \  ___/|  | \/ \    Y    (  <_> )___ \\  \___|   Y  \  //
//  |____|_  /(____  /__|___|  /\___  >__|     \___|_  / \____/____  >\___  >___|  /  //
//         \/      \/        \/     \/               \/            \/     \/     \/   //
////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract RainerHosch is ERC1155PresetMinterPauser, Ownable {

    string public name = "52icons - Rainer Hosch Genesis";
    string public symbol = "52i";
    
    string public contractUri = "https://nft.rainerhosch.com/contract"; 

    constructor() ERC1155PresetMinterPauser("https://nft.rainerhosch.com/{id}") {
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
        require(to.length == id.length, "Contract Info: to and id length mismatch");
        require(to.length == amount.length, "Contract Info: to and amount length mismatch");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }

    }
}