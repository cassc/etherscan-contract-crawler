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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract MigrateTokenContract {
    function mintTransfer(address to) public virtual returns(uint256);
}

contract MNLTHX is DefaultOperatorFilterer, ERC1155, Ownable, ERC1155Burnable {    
    constructor() ERC1155("") {}

    uint256 mnlthId = 1;
    string tokenUri = "ipfs://QmUqNvadJda8xJpcFSJXX8rxzvG7Qhsiswr2TNnLYHXAYH";
    address authorizedContract;
    bool migrationActive = false;
    

    // Mint function
    function airdrop(uint256[] calldata amount, address[] calldata receiver) public onlyOwner {
        for(uint256 i = 0; i < receiver.length; i++) {
            _mint(receiver[i], mnlthId, amount[i], "");
        }
    }

    function setTokenUri(string calldata newUri) public onlyOwner {
        tokenUri = newUri;
    }

    function changeAuthorizedContract(address contractAddress) public onlyOwner {
        authorizedContract = contractAddress;
    }

    function toggleMigration() public onlyOwner {
        migrationActive = !migrationActive;
    }

    function migrateToken() public {
        require(migrationActive, "Migration is not possible at this time");
        require(balanceOf(msg.sender, mnlthId) > 0, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, mnlthId, 1); // Burn one the ERC-1155 token
        MigrateTokenContract migrationContract = MigrateTokenContract(authorizedContract);
        migrationContract.mintTransfer(msg.sender); // Mint the ERC-721 token
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }

    // OpenSea Royalties Support

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
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