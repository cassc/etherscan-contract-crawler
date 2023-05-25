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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";


abstract contract externalContract {
    function equipSkin(uint256 vialId, uint256 dunkId) public virtual;
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function getEquippedSkin(uint256 dunkId) public view virtual returns(uint256);
}

contract MNLTHSKIN is ERC1155, Ownable, ERC1155Burnable {  
    using Strings for uint256;

    constructor() ERC1155("") {}

    event newVial(uint256 tokenId);
    uint256 tokenId = 1;
    mapping (uint256 => string) tokenUri;
    mapping (address => bool) public authorizedContract;

    function mint(address receiver) public returns (uint256) {
        require(authorizedContract[msg.sender] == true, "Not authorized - vial mint");

        _mint(receiver, tokenId, 1, "");
        emit newVial(tokenId);
        tokenUri[tokenId] = string(abi.encodePacked("https://mnlthassets.rtfkt.com/", tokenId.toString()));
        uint256 currentId = tokenId;
        tokenId++;

        return currentId;
    }

    function equipSkin(address contractAdress, uint256 dunkId, uint256 vialId) public {
        require(authorizedContract[contractAdress] == true, "Not authorized - vial equipSkin");
        require(balanceOf(msg.sender, vialId) == 1, "This vial doesn't belong to you");
        externalContract externalToken = externalContract(contractAdress);
        require(externalToken.ownerOf(dunkId) == msg.sender, "You don't own that NFT");
        require(externalToken.getEquippedSkin(dunkId) == 0, "A skin is already equipped");
        burn(msg.sender, vialId, 1);
        externalToken.equipSkin(dunkId, vialId); 
    }

    function skinUnequipped(uint256 id, address owner) public {
        require(authorizedContract[msg.sender] == true, "Not authorized - vial skinUnequipped");
        require(balanceOf(owner, id) == 0, "This vial weirdly already exist");
        _mint(owner, id, 1, "");
    }

    function toggleAuthorizedContract(address contractAddress) public onlyOwner {
        authorizedContract[contractAddress] = !authorizedContract[contractAddress];
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return tokenUri[id];
    }
}