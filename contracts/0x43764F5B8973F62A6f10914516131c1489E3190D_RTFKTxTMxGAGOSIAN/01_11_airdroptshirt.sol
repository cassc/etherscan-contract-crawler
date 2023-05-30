// SPDX-License-Identifier: MIT

/*
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
*/

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

abstract contract ForgeTokenContract {
    function forgeToken(uint256 amount, uint256 tokenId, address owner) public virtual;
}

contract RTFKTxTMxGAGOSIAN is ERC1155, Ownable, ERC1155Burnable {    
    constructor() ERC1155("") {}

    mapping (address => mapping (uint256 => address)) redeemedToken;
    address forgingContractAddress;
    address redemptionMiddlewareContract;
    address authorizedCollection;
    mapping (uint256 => string) tokenURIs;

    // Mint function
    function redeem(address owner, address initialCollection, uint256 tokenId) public payable returns(uint256) {
        require(msg.sender == redemptionMiddlewareContract, "Not authorized");
        require(authorizedCollection == initialCollection, "Collection not authorized");
        ERC721 collectionRedeem = ERC721(initialCollection);
        require(collectionRedeem.ownerOf(tokenId) == owner, "Don't own that token");
        
        _mint(owner, tokenId, 1, "");

        redeemedToken[initialCollection][tokenId] = owner;

        return 1;
    }

    // Forge function
    function forgeToken(uint256 tokenId, uint256 amount) public {
        require(balanceOf(msg.sender, tokenId) >= amount, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, tokenId, amount); // Burn one the ERC-1155 token
        ForgeTokenContract forgingContract = ForgeTokenContract(forgingContractAddress);
        forgingContract.forgeToken(amount, tokenId, msg.sender); // Mint the ERC-721 token
    }

    // Airdrop token
    function airdrop(uint256 tokenId, address[] calldata receivers) public onlyOwner {
        for(uint256 i = 0; i < receivers.length; ++i) {
            _mint(receivers[i], tokenId, 1, "");
        }
    }

    // URI overried
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }

    function hasBeenRedeem(address initialCollection, uint256 tokenId) public view returns(address) {
        return redeemedToken[initialCollection][tokenId];
    }

    // Contract management functions 
    function setURI(uint256 tokenId, string calldata newURI) public onlyOwner {
        tokenURIs[tokenId] = newURI;
    }

    function setMiddleware(address newAddress) public onlyOwner {
        redemptionMiddlewareContract = newAddress;
    }

    function setForgingContract(address newAddress) public onlyOwner {
        forgingContractAddress = newAddress;
    }

    function setAuthorizedCollection(address newAddress) public onlyOwner {
        authorizedCollection = newAddress;
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}