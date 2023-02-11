//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc721a/ERC721A.sol";
import "./openzeppelin/access/Ownable.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";

/*                                                                         
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@*!:     [email protected]@@@@@@@@@-    !#@@@@#!     @@@@@*  [email protected]@@@@[email protected]@@@@@@@@@@#   
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@$.   [email protected]@@@@@@@@@-   [email protected]@@@@@@@*    @@@@@*  [email protected]@@@@[email protected]@@@@@@@@@@#   
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@@@   [email protected]@@@@@@@@@-  [email protected]@@@@@@@@@$   @@@@@*  [email protected]@@@@[email protected]@@@@@@@@@@#   
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@@@#  [email protected]@@@@@@@@@- [email protected]@@@@@@@@@@@.  @@@@@*  [email protected]@@@@[email protected]@@@@@@@@@@#   
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@@@@! [email protected]@@@@@####- @@@@@@@@@@@@@@  @@@@@*  [email protected]@@@@[email protected]@@@@@@@@@@#   
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@ *@@@@@@ [email protected]@@@@=     [email protected]@@@@#  #@@@@@- @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@  ;@@@@@:[email protected]@@@@=     [email protected]@@@@;  ;@@@@@: @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@=**@@@@@. @@@@@@ @@@@@@  :@@@@@;[email protected]@@@@=     #@@@@@   ,@@@@@: @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@@@@@@@@@. @@@@@@ @@@@@@   @@@@@[email protected]@@@@@@@@@ @@@@@@    @@@@@$ @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@@@@@@@@@. @@@@@@ @@@@@@   @@@@@#[email protected]@@@@@@@@@ @@@@@@    @@@@@@ @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@@@@@@@@@. @@@@@@ @@@@@@   @@@@@#[email protected]@@@@@@@@@ @@@@@@    @@@@@@ @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@@@@@@@@@. @@@@@@ @@@@@@   @@@@@[email protected]@@@@@@@@@ @@@@@@    @@@@@@ @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@  [email protected]@@@@;[email protected]@@@@#**** @@@@@@    @@@@@! @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@  ;@@@@@;[email protected]@@@@=     ;@@@@@   ;@@@@@: @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@  #@@@@@[email protected]@@@@=     [email protected]@@@@;  [email protected]@@@@: @@@@@*  [email protected]@@@@    @@@@@:      
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@;#@@@@@@ [email protected]@@@@#;;;;,,@@@@@@;;@@@@@@  @@@@@@;;@@@@@@    @@@@@:      
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@@@@, [email protected]@@@@@@@@@- [email protected]@@@@@@@@@@@*  [email protected]@@@@@@@@@@@@    @@@@@:      
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@@@$  [email protected]@@@@@@@@@-  @@@@@@@@@@@#    @@@@@@@@@@@@-    @@@@@: ;#   
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@@*   [email protected]@@@@@@@@@-  ,@@@@@@@@@@,    *@@@@@@@@@@@     @@@@@:,=!~  
   [email protected]@@@@-  @@@@@. @@@@@@ @@@@@@@@@@!    [email protected]@@@@@@@@@-   [email protected]@@@@@@#-      ;@@@@@@@@!      @@@@@:-*::  
   -=====,  =====. ====== ======;        .==========,     ~$$$$:          !$$$$$        =====~ ,!   
*/

contract Hideout is ERC721A, Ownable, DefaultOperatorFilterer {

    string public baseURI = "ipfs://QmagUeAx45Pjt69XS3sKuTAE2kidvW3VPGsN1LX7azMESS/";

    constructor() ERC721A("HIDEOUT", "HDOT") {}

    function mint(address to, uint256 quantity) onlyOwner public {
        _mint(to, quantity);
    }

    

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public {
        baseURI = newBaseURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) payable  {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from) payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }




}