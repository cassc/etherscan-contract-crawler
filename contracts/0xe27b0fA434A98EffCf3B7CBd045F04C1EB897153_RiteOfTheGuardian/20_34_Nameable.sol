// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


abstract contract Nameable is IERC721Metadata {   
    string named;
    string symbolic;

    constructor(string memory _name, string memory _symbol) {
        named = _name;
        symbolic = _symbol;
    }

    function name() public virtual override view returns (string memory) {
        return named;
    }  

    function symbol() public virtual override view returns (string memory) {
        return symbolic;
    }          
      
}