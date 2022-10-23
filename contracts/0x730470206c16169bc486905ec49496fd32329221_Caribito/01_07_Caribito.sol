// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*                                                                                                         
    #######  (######      @@@@@@@@@,       #########  .########*       &@@@@@@@@#         ,@@@@@@@@@.   
    @@@@@@@  @@@@@@@    @@@@@@@@@@@@@@     @@@@@@@@@  %@@@@@@@@(     @@@@@@@@@@@@@@     &@@@@@@@@@@@@@* 
    [email protected]@@@@@  @@@@@@@   @@@@@@@@@@@@@@@     @@@@@@@@@. @@@@@@@@@(    &@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@ 
     @@@@@@  @@@@@@#   @@@@@@@ @@@@@@@     @@@@@@@@@@ @@@@@@@@@(    &@@@@@@  @@@@@@     @@@@@@@ @@@@@@@ 
     @@@@@@. @@@@@@    @@@@@@@ @@@@@@@     @@@@@@@@@@ @@@@@@@@@(    &@@@@@@  @@@@@@     @@@@@@@ @@@@@@@ 
     @@@@@@, @@@@@@    @@@@@@@ @@@@@@@     @@@@@,@@@@ @@@@@@@@@(    &@@@@@@  @@@@@@     @@@@@@@@@*      
     #@@@@@@,@@@@@@    @@@@@@@ @@@@@@@     @@@@@ @@@@(@@@@@@@@@(    &@@@@@@  @@@@@@      [email protected]@@@@@@@@@@   
      @@@@@@(@@@@@,    @@@@@@@ @@@@@@@     @@@@@ @@@@&@@@%@@@@@(    &@@@@@@  @@@@@@          #@@@@@@@@@ 
      @@@@@@@@@@@@     @@@@@@@ @@@@@@@     @@@@@ @@@@@@@@ @@@@@(    &@@@@@@  @@@@@@     @@@@@@@ @@@@@@@ 
      @@@@@@@@@@@@     @@@@@@@@@@@@@@@     @@@@@ [email protected]@@@@@@ @@@@@(    &@@@@@@  @@@@@@     @@@@@@@ @@@@@@@ 
      %@@@@@@@@@@@     @@@@@@@@@@@@@@@     @@@@@  @@@@@@@ @@@@@(    &@@@@@@  @@@@@@     @@@@@@@ @@@@@@@ 
       @@@@@@@@@@      @@@@@@@ @@@@@@@     @@@@@  @@@@@@% @@@@@(    &@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@ 
       @@@@@@@@@@      @@@@@@@ @@@@@@@     @@@@@  @@@@@@  @@@@@(     @@@@@@@@@@@@@@     ,@@@@@@@@@@@@@@ 
        @@@@@@@@       @@@@@@@ @@@@@@@     @@@@@  @@@@@@  @@@@@(       ,@@@@@@@@           /@@@@@@@#    
                                                                                                        
                                                                                                              
           (@@@@@@@@@@@@&   [email protected]@@@@@@@@@@@@       @@@@@@.     @@@@@@@@@@@@@       @@@@@@  @@@@@@         
           (@@@@@@@@@@@@&   [email protected]@@@@@@@@@@@@@.     @@@@@@.     @@@@@@@@@@@@@@#     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@,,@@@@@@@     @@@@@@.     @@@@@@%,@@@@@@@     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@  @@@@@@@     @@@@@@.     @@@@@@# @@@@@@@     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@  @@@@@@&     @@@@@@.     @@@@@@%[email protected]@@@@@@     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@@@@@@@@@      @@@@@@.     @@@@@@@@@@@@/       @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@@@@@@@@@      @@@@@@.     @@@@@@@@@@@@@@.     @@@@@@  @@@@@@         
               @@@@@@,       @@@@@@  @@@@@@#     @@@@@@.     @@@@@@# @@@@@@@     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@  @@@@@@@     @@@@@@.     @@@@@@# @@@@@@@     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@  @@@@@@@     @@@@@@.     @@@@@@# @@@@@@@     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@  @@@@@@@     @@@@@@.     @@@@@@# @@@@@@@     @@@@@@  @@@@@@         
               @@@@@@,      [email protected]@@@@@  @@@@@@@     @@@@@@.     @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@         
               @@@@@@,      [email protected]@@@@@  @@@@@@@     @@@@@@.     @@@@@@@@@@@@@@      @@@@@@@@@@@@@#             
*/

contract Caribito is ERC721A, Ownable, ERC721AQueryable {
    uint256 public maxSupply = 100;

    string public storedBaseURI = "";

    constructor(string memory newBaseURI) ERC721A("Caribito", "CANZ") {
        setBaseURI(newBaseURI);
    }

    // Only the operator can mint.
    function operatorMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Max supply reached");

        _mint(to, quantity);
    }

    function setBaseURI(string memory _storedBaseURI) public onlyOwner {
        storedBaseURI = _storedBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return storedBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}