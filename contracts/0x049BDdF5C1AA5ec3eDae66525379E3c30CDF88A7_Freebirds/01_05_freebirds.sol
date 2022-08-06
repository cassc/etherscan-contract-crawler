// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//                                                              
//                                                            
//         CCCCCCCCCCCCC       CCCCCCCCCCCCC     OOOOOOOOO     
//       CCC::::::::::::C    CCC::::::::::::C   OO:::::::::OO   
//     CC:::::::::::::::C  CC:::::::::::::::C OO:::::::::::::OO 
//    C:::::CCCCCCCC::::C C:::::CCCCCCCC::::CO:::::::OOO:::::::O
//   C:::::C       CCCCCCC:::::C       CCCCCCO::::::O   O::::::O
//  C:::::C             C:::::C              O:::::O     O:::::O
//  C:::::C             C:::::C              O:::::O     O:::::O
//  C:::::C             C:::::C              O:::::O     O:::::O
//  C:::::C             C:::::C              O:::::O     O:::::O
//  C:::::C             C:::::C              O:::::O     O:::::O
//  C:::::C             C:::::C              O:::::O     O:::::O
//   C:::::C       CCCCCCC:::::C       CCCCCCO::::::O   O::::::O
//    C:::::CCCCCCCC::::C C:::::CCCCCCCC::::CO:::::::OOO:::::::O
//     CC:::::::::::::::C  CC:::::::::::::::C OO:::::::::::::OO 
//       CCC::::::::::::C    CCC::::::::::::C   OO:::::::::OO   
//          CCCCCCCCCCCCC       CCCCCCCCCCCCC     OOOOOOOOO     
                                                            
                                             

contract Freebirds is ERC721A, Ownable {
    constructor() ERC721A("Freebirds", "FREEBIRDS") {
    }

    error AllMinted();
    error Max5PerTx();

    string _baseTokenURI;

    // free mint
    function mint(uint256 quantity) public {
        if (totalSupply() + quantity > 10000) {
            revert AllMinted(); // all 10 000 minted
        }
        if (quantity > 5) {
            revert Max5PerTx(); // Max 5 per transaction
        }
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function DropTime(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; ++i) {
            _mint(_addresses[i], 5);
        }
    }
}