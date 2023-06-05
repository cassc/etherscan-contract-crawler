// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract fng {
    function tokensOfOwner(address addr) public virtual view returns(uint256[] memory);
}

contract PxlFangs is ERC721Enumerable, Ownable {  
    using Address for address;

    // Fang Gang contract
    fng private fg;
    
    // Contract deactivated right after deploy
    bool public active = false;

    // The base link that points to the metadata of the token
    string public baseTokenURI;

    // Keep track of tokens that have already been claimed
    mapping (uint256 => bool) public claimed;

    constructor (string memory newBaseURI, address fngAddress) ERC721 ("PxlFangs", "PXF") {
        setBaseURI(newBaseURI);
        
        // Deploy with the Fang Gang contract address
        fg = fng(fngAddress);

        // Reserve 4 special PxlFangsters as a prize
        for (uint256 i; i < 4; i++) {
            claimed[i] = true;
            _safeMint(msg.sender, i);
        }
    }

    // Override to make the openzeppelin tokenURI() method use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Input an address to get a list of the owned tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Claim function
    function claimToken(uint256[] memory requestTokenIds) public {
        require(active, "Contract isn't active");
        uint256 supply = totalSupply();

        // Returns array of Fangster token IDs owned by the sender
        uint256[] memory ownedTokens = fg.tokensOfOwner(msg.sender);
        // Create empty array with the length ownedTokens 
        uint256[] memory unclaimedTokens = new uint256[](ownedTokens.length);
        // Need a counter to track array size
        uint256 unclaimedTokensLastIndex = 0;

        // Verify the tokens given
        for(uint i = 0; i < requestTokenIds.length; i++) {
            // If current token on the list was not already claimed -- check here to save gas
            if (!claimed[requestTokenIds[i]]) {
                // Loop through all tokens owned by the sender
                for (uint256 k = 0; k < ownedTokens.length; k++) { 
                    // Check if owendTokens contains requestTokenId
                    if (ownedTokens[k] == requestTokenIds[i]) { 
                        // Add unclaimed token to the array
                        unclaimedTokens[unclaimedTokensLastIndex] = ownedTokens[k];
                        // Track array size
                        unclaimedTokensLastIndex++;
                        // break out of k-loop and continue i-loop when we found our match to save gas
                        break;
                    } 
                }
            }
        }

        // Stop tx if there is nothing to claim
        require(unclaimedTokensLastIndex > 0, "No tokens to claim");

        // Set loop limit to max 50 per tx - otherwise we could reach the max gas limit per tx
        if (unclaimedTokensLastIndex > 50) {
            unclaimedTokensLastIndex = 50;
        }

        // Loop through up to 50 of the unclaimed tokens
        for (uint256 i = 0; i < unclaimedTokensLastIndex; i++) {
            // Doublecheck that the ID wasn't already claimed
            if(!claimed[unclaimedTokens[i]]) { 
                // First add it to the list of claimed Tokens
                claimed[unclaimedTokens[i]] = true;
                // Then mint it
                _safeMint( msg.sender, supply + i );
            }
        }
    }

    // Activate and deactivate contract
    function setActive(bool val) public onlyOwner {
        active = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
}