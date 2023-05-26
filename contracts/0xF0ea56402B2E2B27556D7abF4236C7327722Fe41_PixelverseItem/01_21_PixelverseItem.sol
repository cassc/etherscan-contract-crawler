// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

/**
* Pixelverse in-game items with a fixed supply, minted in bulk by an admin 
* via the ERC1155 standard. Primary Sale of these tokens will happen on the
* PixelMarketplace which is approved for the management of all minted items.
* 
* Added custom uri logic such that it actually shows up properly in OpenSea.
* 
* ERC1155PresetMinterPauser is an ERC1155 base token that includes:
* - Ability for holders to burn (destroy) their tokens
* - A minter role that allows for token minting (creation)
* - A pauser role that allows to stop all token transfers
* 
* Roles are managed via, only updatable via the contract owner:
*  grantRole(role, account)
*  revokeRole(role, account)
*  renounceRole(role, account)
*/
contract PixelverseItem is ERC1155PresetMinterPauser, Ownable {

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    address public pixelMarketplaceAddress;

    // Metadata URI for IPFS hosted assets 
    // NOTE: we are not using the standard {id} interface cuz opensea doesn't recognize it lol
    string public baseMetadataUri;
    
    constructor(
        string memory _baseMetadataUri,
        address marketplaceAddress) 
        ERC1155PresetMinterPauser("") 
    {
        name = "Pixelverse Item";
        symbol = "PVIT";
        baseMetadataUri = _baseMetadataUri;
        pixelMarketplaceAddress = marketplaceAddress;
        
        mintToMarketplace(1, 1000); // Pixel Pass

        mintToMarketplace(2, 300); // Arcade - Flappy Seal
        mintToMarketplace(3, 500); // Arcade - Sappy Jump
        mintToMarketplace(4, 500); // Arcade - Sap Man

        mintToMarketplace(5, 1000); // Starter Pack - Sappy Seals
        mintToMarketplace(6, 1000); // Starter Pack - Winter Bears
        mintToMarketplace(7, 1000); // Starter Pack - 24px
    }

    /*
    * Owner and addresses with MINTER_ROLE will be able to `mint` new collections of NFTs.
    * Allows for Primary sale of newly minted ERC1155 NFTs via the PixelMarketplace contract.
    * Minted NFTs will live here on the Smart Contract until sold from the Marketplace.
    * 
    * When minting post-launch, ensure that ALL assets are re-pushed to the initial IPFS project
    * OR that the baseUri is updated to a project that contains all appropriate art.
    */
    function mintToMarketplace(
        uint256 id,
        uint256 amount
    ) public {
        super.mint(pixelMarketplaceAddress, id, amount, "");
    }

    // Override ERC1155 standard so it can properly be seen on OpenSea
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(
          abi.encodePacked(
            baseMetadataUri,
            Strings.toString(_tokenId)
          )
        );
    }

    // NOTE: needs to be similsr ERC721 uri in which an id is simply appended at the end.
    // i.e. "https://ipfs.io/ipfs/QmXUUXRSAJeb4u8p4yKHmXN1iAKtAV7jwLHjw35TNm5jN7/"
    function setURI(string memory _newuri) public onlyOwner {
        baseMetadataUri = _newuri;
    }

    // NOTE: you will also need to manually transfer and re-approve
    // all existing ERC1155's to the new MP contract 
    function setMarketplaceAddress(address mpContractAddress) public onlyOwner {
        pixelMarketplaceAddress = mpContractAddress;
    }

}