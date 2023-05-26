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
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract MigrateTokenContract {
    function mintTransfer(address to) public virtual returns(uint256);
}

contract MNLTHBIS is ERC1155, Ownable, ERC1155Burnable {    
    constructor() ERC1155("") {}

    uint256 tokenId = 1;
    string tokenUri = "";
    address dunkAddress = 0xcED4e174BC3319f5e9EfD4e99E36A70830F2b98B;
    bool migrationActive = false;
    
    function mint(address receiver) public returns (uint256) {
        require(msg.sender == dunkAddress, "Not authorized");

        _mint(receiver, 1, 1, "");

        return 1;
    }

    function setTokenUri(string calldata newUri) public onlyOwner {
        tokenUri = newUri;
    }

    function changeDunkAddress(address newAddress) public onlyOwner {
        dunkAddress = newAddress;
    }

    function toggleMigration() public onlyOwner {
        migrationActive = !migrationActive;
    }

    function migrateToken() public {
        require(migrationActive, "Migration is not possible at this time");
        require(balanceOf(msg.sender, tokenId) > 0, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, tokenId, 1); // Burn one the ERC-1155 token
        MigrateTokenContract migrationContract = MigrateTokenContract(dunkAddress);
        migrationContract.mintTransfer(msg.sender); // Mint the ERC-721 token
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }
}