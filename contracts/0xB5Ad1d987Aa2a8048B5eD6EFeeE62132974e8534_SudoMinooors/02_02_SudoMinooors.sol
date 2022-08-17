// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "./ERC721.sol";        

contract SudoMinooors is ERC721 { 

    address owner;
    address wardrobe;

    constructor(address wardrobe_) ERC721("SudoMinooors", "SMN", 1000) {
        owner = msg.sender;
        wardrobe = wardrobe_;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "ONLY_OWNER");
        _safeMint(to, amount, "");
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return ERC721(wardrobe).tokenURI(id);
    }

    function setWardrobe(address newWardrobe_) public {
        require(msg.sender == owner, "ONLY_OWNER");
        wardrobe = newWardrobe_;
    }
    
}


