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
//         RTFKT x Murakami Event Contract (made by @CardilloSamuel, co-paired with @Maximonee_)

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

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract RTFKTxMurakamiEvent is ERC1155, ERC1155Burnable, Ownable, DefaultOperatorFilterer {
    constructor() ERC1155("") {
        authorizedAdmins[msg.sender] = true;

        supplyLimits[1] = 5;
        supplyLimits[2] = 100;
        supplyLimits[3] = 250;
        supplyLimits[4] = 2500;
    }

    modifier isAuthorizedAdmin() {
        require(msg.sender == owner() || authorizedAdmins[msg.sender], "Unauthorized");
        _;
    }

    bool tokenSupplyLocked;
    mapping (address => bool) public authorizedAdmins;
    mapping (uint256 => string) public tokenURIs;
    mapping (uint256 => uint256) public supplyLimits;
    mapping (uint256 => uint256) public mintedByTokenId;

    function mint(uint256 tokenId, uint256 amount, address recipient) public isAuthorizedAdmin {
        require(mintedByTokenId[tokenId] + amount <= supplyLimits[tokenId], "Max supply reached");
        
        mintedByTokenId[tokenId] += amount;
        _mint(recipient, tokenId, amount, "");
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }

    /////////////////////////////
    // CONTRACT MANAGEMENT 
    /////////////////////////////

    function setTokenUri(uint256 tokenId, string calldata uri_) public isAuthorizedAdmin {
        tokenURIs[tokenId] = uri_;
    }

    function toggleApprovedAdmin(address admin) public onlyOwner {
        authorizedAdmins[admin] = !authorizedAdmins[admin];
    }

    function setTokenSupply(uint256 supply, uint256 tokenId) public isAuthorizedAdmin {
        require(!tokenSupplyLocked, "Token supply is locked");
        supplyLimits[tokenId] = supply;
    }

    function withdrawFunds(address to) public isAuthorizedAdmin {
        payable(to).transfer(address(this).balance);
    }

    function lockTokenSupply() public isAuthorizedAdmin {
        tokenSupplyLocked = true;
    }

    /////////////////////////////////
    // OPENSEA ROYALTIES MANAGEMENT
    /////////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}