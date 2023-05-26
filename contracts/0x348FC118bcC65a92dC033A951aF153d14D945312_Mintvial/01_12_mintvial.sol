// SPDX-License-Identifier: MIT

/*
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
*/

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract ClonexCharacterInterface {
    function mintTransfer(address to) public virtual returns(uint256);
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract Mintvial is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;

    uint256 tokenId = 0;
    uint256 amountMinted = 0;
    uint256 limitAmount = 20000;
    uint256 private tokenPrice = 50000000000000000; // 0.05 ETH

    address clonexContractAddress;

    mapping (address => mapping (uint256 => bool)) usedToken;
    mapping (address => uint256) authorizedContract;

    event priceChanged(uint256 newPrice);
                                
    bool privateSales = true;
    bool publicSales = false;
    bool salesStarted = false;
    bool migrationStarted = false;
    
    constructor() ERC1155("ipfs://QmQqMF7izNAaU9CY3qV9ZGs4Aksv6ywjx8261khgzQbReW") {
        // ERC-721
        authorizedContract[0x20fd8d8076538B0b365f2ddd77C8F4339f22B970] = 721; // Mintdisc 1 - 721
        authorizedContract[0x25708f5621Ac41171F3AD6D269e422c634b1E96A] = 721; // Mintdisc 3 - 721
        authorizedContract[0x50B8740D6a5CD985e2B8119Ca28B481AFa8351d9] = 721; // RTFKT Easter Eggs - 721
        authorizedContract[0xc541fC1Aa62384AB7994268883f80Ef92AAc6399] = 721; // Space Drip 1.2 - 721
        authorizedContract[0xd3f69F10532457D35188895fEaA4C20B730EDe88] = 721; // Space Drip 1 - 721
        authorizedContract[0x2250D7c238392f4B575Bb26c672aFe45F0ADcb75] = 721; // FewoShoes - 721
        authorizedContract[0xAE3d8D68B4F6c3Ee784b2b0669885a315BA77C08] = 721; // Punk sneakers - 721
        authorizedContract[0xDE8350B34b2e6FC79aABCc7030fD9a862562E821] = 721; // Metagrails -> 721

        // ERC-1155
        authorizedContract[0xCD1DBc840E1222A445be7C1D8ecB900F9D930695] = 1155; // Jeff Staples - 1155
    }
    
    // Set authorized contract address for minting the ERC-721 token
    function setClonexContract(address contractAddress) public onlyOwner {
        clonexContractAddress = contractAddress;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleSales() public onlyOwner {
        salesStarted = !salesStarted;
    }

    // Toggle the private sales system
    function togglePrivateSales() public onlyOwner {
        privateSales = !privateSales;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleMigration() public onlyOwner {
        migrationStarted = !migrationStarted;
    }
    
    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleContractAuthorization(address contractAddress, uint256 typeOfContract) public onlyOwner {
        authorizedContract[contractAddress] = typeOfContract;
    }

    // Check if a specific address is an authorized mintpass
    function isContractAuthorized(address contractAddress) view public returns(uint256) {
        return authorizedContract[contractAddress];
    }

    // Mint function
    function mint(address[] calldata contractIds, uint256[] calldata tokenIds, uint256 amountToMint) public payable returns(uint256) {
        // By calling this function, you agreed that you have read and accepted the terms & conditions available at this link: https://rtfkt.com/legaloverview
        require(salesStarted == true, "Sales have not started");
        uint256 amount = amountToMint;

        // Note: For public sales to be active, the bool publicSales need to be true and the bool privateSales need to be false

        // If public sales is active
        if(publicSales == true) {
            require(!privateSales, "Public sales has not started");
            require(amount <= 3 && amount >= 1, "You have to mint between 1 to 3 at a time");
        } else { // Else if the public sales is not active
            require(privateSales, "Public sales has not started");
            require(contractIds.length > 0, "No contract detected");
            require(tokenIds.length == contractIds.length, "tokenIds must match contractIds length");

            amount = 0;
            for(uint256 i = 0; i < contractIds.length; i++) {
                // Verify token ownership and if already redeemed
                if(authorizedContract[contractIds[i]] == 721) {
                    // If token is ERC-721
                    ERC721 contractAddress = ERC721(contractIds[i]);
                    require(contractAddress.ownerOf(tokenIds[i]) == msg.sender, "Doesn't own the token");
                } else if(authorizedContract[contractIds[i]] == 1155) {
                    // If token is ERC-1155
                    ERC1155 contractAddress = ERC1155(contractIds[i]);
                    require(contractAddress.balanceOf(msg.sender, tokenIds[i]) > 0, "Doesn't own the token");
                } else {
                    revert("Contract is not authorized"); // If the contract is neither flagged as 721 or 1155
                }
                
                require(checkIfRedeemed(contractIds[i], tokenIds[i]) == false, "Token already redeemed");
				usedToken[contractIds[i]][tokenIds[i]] = true;
                
                // Verify if token is mintpass or not (influence the amount to mint)
                if(contractIds[i] == 0x20fd8d8076538B0b365f2ddd77C8F4339f22B970) amount += 1; 
                else amount += 3;
            }
        }

        // Add verification on ether required to pay
        require(msg.value >= tokenPrice.mul(amount), "Not enough money");
        
        uint256 prevTokenId = tokenId;
        tokenId++;
        require(amount + amountMinted <= limitAmount, "Limit reached");
        amountMinted = amountMinted + amount;
        _mint(msg.sender, tokenId, amount, "");
        return prevTokenId;
    }
    
    // Allowing direct drop for gievaway
    function airdropGiveaway(address[] calldata to, uint256[] calldata amountToMint) public onlyOwner {
        for(uint256 i = 0; i < to.length; i++) {
            tokenId++;
            require(amountToMint[i] + amountMinted <= limitAmount, "Limit reached");
            amountMinted = amountMinted + amountToMint[i];
            _mint(to[i], tokenId, amountToMint[i], "");
        }
    }
    
    // Allow to use the ERC-1155 to get the CLoneX ERC-721 final token
    function migrateToken(uint256 id) public returns(uint256) {
        require(migrationStarted == true, "Migration has not started");
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        ClonexCharacterInterface clonexContract = ClonexCharacterInterface(clonexContractAddress);
        uint256 mintedId = clonexContract.mintTransfer(msg.sender); // Mint the ERC-721 token
        return mintedId; // Return the minted ID
    }

    // Allow to use the ERC-1155 to get the CLoneX ERC-721 final token (Forced)
    function forceMigrateToken(uint256 id) public onlyOwner {
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token"); // Kept so no one can't force someone else to open a CloneX
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        ClonexCharacterInterface clonexContract = ClonexCharacterInterface(clonexContractAddress);
        clonexContract.mintTransfer(msg.sender); // Mint the ERC-721 token
    }
    
    // Check if the mintpass has been used to mint an ERC-1155
    function checkIfRedeemed(address _contractAddress, uint256 _tokenId) view public returns(bool) {
        return usedToken[_contractAddress][_tokenId];
    }
    
    // Allow toggling of public sales
    function togglePublicSales() public onlyOwner {
        publicSales = !publicSales;
    }
    
    // Get the price of the token (as changing during presale and public sale)
    function getPrice() view public returns(uint256) { 
        return tokenPrice;
    }
    
    // Get amount of 1155 minted
    function getAmountMinted() view public returns(uint256) {
        return amountMinted;
    }
    
    // Used for manual activation on dutch auction
    function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
        emit priceChanged(tokenPrice);
    }
    
    // Basic withdrawal of funds function in order to transfert ETH out of the smart contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}