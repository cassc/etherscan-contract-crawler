// SPDX-License-Identifier: MIT

//░██████╗██╗███╗░░██╗░██████╗░██╗░░░██╗██╗░░░░░░█████╗░██████╗░██╗████████╗██╗░░░██╗
//██╔════╝██║████╗░██║██╔════╝░██║░░░██║██║░░░░░██╔══██╗██╔══██╗██║╚══██╔══╝╚██╗░██╔╝
//╚█████╗░██║██╔██╗██║██║░░██╗░██║░░░██║██║░░░░░███████║██████╔╝██║░░░██║░░░░╚████╔╝░
//░╚═══██╗██║██║╚████║██║░░╚██╗██║░░░██║██║░░░░░██╔══██║██╔══██╗██║░░░██║░░░░░╚██╔╝░░
//██████╔╝██║██║░╚███║╚██████╔╝╚██████╔╝███████╗██║░░██║██║░░██║██║░░░██║░░░░░░██║░░░
//╚═════╝░╚═╝╚═╝░░╚══╝░╚═════╝░░╚═════╝░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░╚═╝░░░░░░╚═╝░░░


pragma solidity ^0.8.4;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Singularity is ERC721A, Ownable {

    constructor(string memory URI) ERC721A("Singularity", "SNGLR") {
      baseURI = URI;
    }
  
    string baseURI;
    
    function airdrop(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
        for(uint i = 0; i<addresses.length; i++) {
          _mint(addresses[uint256(i)], quantities[uint256(i)]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
      baseURI = URI;
    }

    function viewBaseURI() public view returns(string memory) {
      return _baseURI();
    }

}