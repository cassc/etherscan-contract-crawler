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
//         Pods Contract (made by @CardilloSamuel, co-paired with @Maximonee_)

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
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract Pods is DefaultOperatorFilterer, ERC1155, Ownable, ERC1155Burnable {
    constructor() ERC1155("") {
        requireBurning[1] = true;
        requireBurning[2] = true;

        ownerApproved[0x1ae6A4d3078b951438d1aa64DE6C1E4e033913D6] = true;
    }

    modifier isOwnerApproved() {
        require(msg.sender == owner() || ownerApproved[msg.sender], "You are not authorized to perform this action");
        _;
    }

    mapping (address => bool)       public authorizedContract;
    mapping (address => bool)       public ownerApproved;
    mapping (uint256 => string)     public tokenURIs;
    mapping (uint256 => uint256)    public tokenPrice;
    mapping (uint256 => bool)       public requireBurning;

    mapping (uint256 => uint256)    public maxSupplyLimits;
    mapping (uint256 => uint256)    public individualSupplyLimits;
    mapping (uint256 => uint256)    public mintedByTokenId;
    mapping (uint256 => mapping (address => uint256)) public mintedByWalletByTokenId;

    address withdrawAddress;

    function mintThroughBurn(address newOwner, uint256 tokenId, uint256 amount) payable public {
        require(requireBurning[tokenId], "Don't require burning");
        require(authorizedContract[msg.sender], "Not authorized");
        require(msg.value == tokenPrice[tokenId] * amount, "Not enough ETH");
        require(bytes(tokenURIs[tokenId]).length > 0, "Not authorized - URI not defined");

        _mint(newOwner, tokenId, amount, "");
    }

    function mint(uint256 tokenId, uint256 amount) payable public {
        require(!requireBurning[tokenId], "Require burning");
        require(bytes(tokenURIs[tokenId]).length > 0, "Not authorized - URI not defined");
        require(msg.value == tokenPrice[tokenId] * amount, "Not enough ETH");
        require(mintedByTokenId[tokenId] + amount <= maxSupplyLimits[tokenId], "Max supply reached");
        require(mintedByWalletByTokenId[tokenId][msg.sender] + amount <= individualSupplyLimits[tokenId], "Individual supply reached");
        
        mintedByWalletByTokenId[tokenId][msg.sender] = mintedByWalletByTokenId[tokenId][msg.sender] + amount;
        mintedByTokenId[tokenId] = mintedByTokenId[tokenId] + amount;
        _mint(msg.sender, tokenId, amount, "");
    }



    function airdropToken(uint256[] calldata tokenIds, uint256[] calldata amounts, address[] calldata receivers) public isOwnerApproved {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(bytes(tokenURIs[tokenIds[i]]).length > 0, "Not authorized - URI not defined");

            _mint(receivers[i], tokenIds[i], amounts[i], "");
        }
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }

    /////////////////////////////
    // CONTRACT MANAGEMENT 
    /////////////////////////////

    function toggleRequireBurning(uint256 tokenId) public onlyOwner {
        requireBurning[tokenId] = !requireBurning[tokenId];
    }

    function setTokenPrice(uint256 newPrice, uint256 tokenId) public onlyOwner {
        tokenPrice[tokenId] = newPrice;
    }

    function setTokenUri(string calldata newUri, uint256 tokenId) public onlyOwner {
        tokenURIs[tokenId] = newUri;
    }

    function toggleContractApproval(address contractToApprove) public onlyOwner {
        authorizedContract[contractToApprove] = !authorizedContract[contractToApprove];
    }

    function changeWithdrawAddress(address newAddress) public onlyOwner {
        withdrawAddress = newAddress;
    }

    function toggleApprovedOwner(address addressToToggle) public onlyOwner {
        ownerApproved[addressToToggle] = !ownerApproved[addressToToggle];
    }

    function setTokenMaxSupply(uint256 supply, uint256 tokenId) public onlyOwner {
        maxSupplyLimits[tokenId] = supply;
    }

    function setTokenIndividualSupply(uint256 supply, uint256 tokenId) public onlyOwner {
        individualSupplyLimits[tokenId] = supply;
    }

    function withdrawFunds() public isOwnerApproved {
		payable(withdrawAddress).transfer(address(this).balance);
	}

    /////////////////////////////////
    // OPENSEA ROYALTIES MANAGEMENT
    /////////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}