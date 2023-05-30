// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract clg {
    function tokensOfOwner(address addr) public virtual view returns(uint256[] memory);
}

contract RaptorCityRascals is ERC721Enumerable, Ownable {  
    using Address for address;
    clg private cg;

    // Starting and stopping sale and presale
    bool public active = false;
    bool public presaleActive = false;

    // Reserved for the team, customs, giveaways, collabs and so on.
    uint256 public reserved = 100;

    // Price of each token
    uint256 public price = 0.05 ether;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 10000;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    // List of tokens that have already been claimed
    mapping (uint256 => bool) public claimed;

    // Team addresses for withdrawals
    address public a1;
    address public a2;

    constructor (string memory newBaseURI, address clgAddress) ERC721 ("Raptor City Rascals", "RCR") {
        setBaseURI(newBaseURI);
        // Deploy with Clever Girls contract address
        cg = clg(clgAddress);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Standard mint function
    function mintToken(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( active,                         "Sale isn't active" );
        require( _amount > 0 && _amount < 21,    "Can only mint between 1 and 20 tokens at once" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(uint256 _amount) public onlyOwner {
        // Limited to a publicly set amount
        require( _amount <= reserved, "Can't reserve more than set amount" );
        reserved -= _amount;
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // Claim function
    function claimToken(uint256[] memory requestTokenIds) public {
        require(presaleActive, "Presale isn't active");
        uint256 supply = totalSupply();

        // Returns array of Clever Girl token IDs owned by the sender
        uint256[] memory ownedTokens = cg.tokensOfOwner(msg.sender);
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

    // Start and stop presale
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Start and stop sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Set team addresses
    function setAddresses(address[] memory _a) public onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
    }

    // Withdraw funds from contract for the team
    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(a1).send(percent * 70)); // 70% to Raptor City
        require(payable(a2).send(percent * 30)); // 30% to NFT Forge
    }
}