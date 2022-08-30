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

abstract contract CloneXMetadata {
    function getDNA(uint256 tokenId) public view virtual returns(bytes1);
    function isMurakami(uint256 tokenId) public view virtual returns(bool);
}

contract RedeemableToken is ERC1155, Ownable, ERC1155Burnable {    
    constructor() ERC1155("") {
        // Will predefine the 72 IDs over here in the future
        tokenURIs[1] = "";

        cloneWearableIds[0x31] = [6, 12];
        cloneWearableIds[0x32] = [13, 20];
        cloneWearableIds[0x33] = [21, 28];
        cloneWearableIds[0x34] = [29, 36];
        cloneWearableIds[0x35] = [37, 44];
        cloneWearableIds[0x36] = [45, 52];
        cloneWearableIds[0x37] = [53, 60];
        cloneWearableIds[0x38] = [61, 68];

        cantForge[5] = true;
        cantForge[12] = true;
        cantForge[20] = true;
        cantForge[28] = true;
        cantForge[36] = true;
        cantForge[44] = true;
        cantForge[52] = true;
        cantForge[60] = true;
        cantForge[68] = true;
        cantForge[74] = true;
    }

    address redemptionMiddlewareContract = 0xEf3cF123a094Fffa3422b5e016eDaAe01FD550C8;
    address cloneXContractAddress = 0x32dAa83a8e69Fd4A007b41B66D01389F9E9b6BCe;
    address cloneXMetadataAddress = 0x7B8fB12136C1E50FB6f01FcB17F4005F3Fd3F7C6;
    address forgingContractAddress;

    mapping (uint256 => mapping(uint256 => uint256)) public wearableSupply; // ref : CLoneX_Supply_Territory.xls (no + 1)
    mapping (uint256 => uint256) public generalSupply;
    mapping (uint256 => string) public tokenURIs;
    mapping (bytes1 => uint256[2]) cloneWearableIds;
    mapping (uint256 => bool) public cantForge;

    struct Remaining {
        uint256 WearableId;
        uint256 RemainingMints;
    }

    event newRedeemBatch(address owner, address initialCollection, uint256[] cloneXIds, uint256[] wearablesIds, uint256[] amounts);
    event newForge(uint256[] tokenIds, uint256[] amounts, address owner);

    function redeemBatch(address owner, address initialCollection, uint256[] calldata cloneXIds, uint256[] calldata wearableIds, uint256[] calldata amounts) public payable {
        require(msg.sender == redemptionMiddlewareContract, "Not authorized");
        require(initialCollection == cloneXContractAddress, "Not authorized");
        require(cloneXIds.length == wearableIds.length, "Mismatch of length");
        require(cloneXIds.length == amounts.length, "Mismatch of length");

        // Setting up interfaces
        ERC721 CloneXCollection = ERC721(cloneXContractAddress);
        CloneXMetadata cloneMetadata = CloneXMetadata(cloneXMetadataAddress);

        for(uint256 i = 0; i < cloneXIds.length; ++i) {
            require(CloneXCollection.ownerOf(cloneXIds[i]) == owner, "Don't own that token");
            bytes1 dna = cloneMetadata.getDNA(cloneXIds[i]);
            require(dna != 0x00, "Clone metadata not set");
            bool isMurakamiDrip = cloneMetadata.isMurakami(cloneXIds[i]);

            // Check if DNA and/or drip is matching
            require(
                (wearableIds[i] >= cloneWearableIds[dna][0] && wearableIds[i] <= cloneWearableIds[dna][1]) ||
                (isMurakamiDrip && (wearableIds[i] >= (cloneWearableIds[0x38][1] + 1) && wearableIds[i] <= (cloneWearableIds[0x38][1] + 6) )) ||
                (wearableIds[i] >= 1 && wearableIds[i] <= (cloneWearableIds[0x31][0] - 1) ),
                "Mismatch of wearable ID"
            );

            // Check avail quantity 
            if(wearableIds[i] >= 1 && wearableIds[i] <= 5) 
                require(wearableSupply[cloneXIds[i]][wearableIds[i]] + amounts[i] <= 1, "Can't redeem more");
            else 
                require(wearableSupply[cloneXIds[i]][wearableIds[i]] + amounts[i] <= 2, "Can't redeem more");

            // Updating supplyinh
            wearableSupply[cloneXIds[i]][wearableIds[i]] = wearableSupply[cloneXIds[i]][wearableIds[i]] + amounts[i];
            generalSupply[wearableIds[i]] = generalSupply[wearableIds[i]] + amounts[i];

            // Minting batch
            _mint(owner, wearableIds[i], amounts[i], "");
        }

        emit newRedeemBatch(owner, initialCollection, cloneXIds, wearableIds, amounts);
    }

    // Forge function
    function forgeToken(uint256[] calldata tokenIds, uint256[] calldata amounts) public {
        require(forgingContractAddress != 0x0000000000000000000000000000000000000000, "No forging address set for this token");

        for(uint256 i = 0; i < tokenIds.length; ++i) {
            require(balanceOf(msg.sender, tokenIds[i]) >= amounts[i], "Doesn't own the token"); // Check if the user own one of the ERC-1155
            require(!cantForge[tokenIds[i]], "Can't forge such token");

            burn(msg.sender, tokenIds[i], amounts[i]); // Burn one the ERC-1155 token
            
            ForgeTokenContract forgingContract = ForgeTokenContract(forgingContractAddress);
            forgingContract.forgeToken(amounts[i], tokenIds[i], msg.sender); // Mint the ERC-721 token
        }

        emit newForge(tokenIds, amounts, msg.sender);
    }

    // Airdrop function
    function airdropTokens(uint256[] calldata tokenIds, uint256[] calldata amount, address[] calldata owners) public onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            _mint(owners[i], tokenIds[i], amount[i], "");
        }
    }

    // --------
    // Getter
    // --------
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }

    // To be called off-chain
    // Returns array of Remaining struct which contains the wearable ID and remaining mints for a given token ID
    function remainingMints(uint256 tokenId) external view returns (Remaining[] memory) {
        CloneXMetadata cloneMetadata = CloneXMetadata(cloneXMetadataAddress);
        bytes1 dna = cloneMetadata.getDNA(tokenId);
        bool isMurakamiDrip = cloneMetadata.isMurakami(tokenId);

        (uint256 start, uint256 finish) = (cloneWearableIds[dna][0], cloneWearableIds[dna][1]);

        // Starting with 5 clonex genesis items
        uint256 totalWearables = 5;
        totalWearables = totalWearables + (finish - start);
        if (isMurakamiDrip) {
            totalWearables += 6;
        }

        Remaining[] memory remaining = new Remaining[](totalWearables+1);
        uint256 count = 0;

        // CloneX DNA check
        for (uint256 i = start; i <= finish; i++) {
            remaining[count] = Remaining(i, 2 - wearableSupply[tokenId][i]);
            count++;
        }

        // Murakami drip check
        if (isMurakamiDrip) {
            for (uint256 i = (cloneWearableIds[0x38][1] + 1); i <= (cloneWearableIds[0x38][1] + 6); i++) {
                remaining[count] = Remaining(i, 2 - wearableSupply[tokenId][i]);
                count++;
            }
        }

        // CloneX Genesis check
        for (uint256 i = 1; i <= (cloneWearableIds[0x31][0] - 1); i++) {
            remaining[count] = Remaining(i, 1 - wearableSupply[tokenId][i]);
            count++;
        }

        return remaining;
    }

    // --------
    // Setter
    // --------

    function setTokenURIs(uint256 tokenId, string calldata newUri) public onlyOwner {
        tokenURIs[tokenId] = newUri;
    }

    function setCloneX(address newAddress) public onlyOwner {
        cloneXContractAddress = newAddress;
    }

    function setCloneXMetadata(address newAddress) public onlyOwner {
        cloneXMetadataAddress = newAddress;
    }

    function setForgingAddress(address newAddress) public onlyOwner {
        forgingContractAddress = newAddress;
    }

    function setMiddleware(address newContractAddress) public onlyOwner {
        redemptionMiddlewareContract = newContractAddress;
    }

    function setWearableRange(bytes1 dna, uint256[2] calldata range) public onlyOwner {
        cloneWearableIds[dna][0] = range[0];
        cloneWearableIds[dna][1] = range[1];
    }

    function toggleForgeable(uint256 tokenId) public onlyOwner {
        cantForge[tokenId] = !cantForge[tokenId];
    }

    // In case someone send money to the contract by mistake
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}