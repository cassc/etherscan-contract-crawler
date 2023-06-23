// SPDX-License-Identifier: MIT
//
//          [email protected]@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         RTFKT x FaZe (made with love by @CardilloSamuel)

/**
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    D. Digital Collectible Terms [Document #2-D, https://rtfkt.com/legal-2D]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
**/

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RTFKTxFaze is ERC721A, Ownable, DefaultOperatorFilterer {
    constructor() ERC721A("RTFKTxFaze", "RF") {
    }

    bool public contractLocked;
    string baseURI = "ipfs://QmPLmkgpXvMG75xDnNu4tosTCaDrmFeo93vVvhXEeVZKUV";

    // Making sure we start the token ID at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function airdropToken(uint256[] calldata amount, address[] calldata owners) public onlyOwner {
        require(!contractLocked, "Contract is locked");

        for (uint256 i = 0; i < owners.length; i++) {
            _safeMint(owners[i], amount[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return baseURI;
    }

    /////////////////////////////
    // CONTRACT MANAGEMENT 
    /////////////////////////////

    function withdrawFunds(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        require(!contractLocked, "Contract is locked");
        baseURI = uri;
    }

    function lockContract() public onlyOwner {
        contractLocked = true;
    }

    /////////////////////////////////
    // OPENSEA ROYALTIES MANAGEMENT
    /////////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}