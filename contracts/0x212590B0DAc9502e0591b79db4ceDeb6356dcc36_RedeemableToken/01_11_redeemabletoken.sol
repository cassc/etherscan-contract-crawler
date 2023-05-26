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

contract RedeemableToken is ERC1155, Ownable, ERC1155Burnable {    
    constructor() ERC1155("") {
        tokenURIs[1] = "https://rtfkt.mypinata.cloud/ipfs/QmRbUSDAFLf5iEuU9v49Vt7YppyCjGsJQMxqrt6PWF5RF6/1";
    }

    address redemptionMiddlewareContract = 0x8E5474cA17499626EE88E2A533bD369EBe72099A;

    mapping (uint256 => uint256) public currentSupply;
    mapping (uint256 => uint256) public supplyLimit;
    mapping (uint256 => mapping (address => mapping(uint256 => address))) redeemedToken;
    mapping (uint256 => address) public forgingContractAddresses;
    mapping (address => uint256) public authorizedCollections; // Set the tokenID of minting associated with collection
    mapping (uint256 => string) public tokenURIs;

    // Mint function
    function redeem(address owner, address initialCollection, uint256 tokenId) public payable returns(uint256) {
        require(msg.sender == redemptionMiddlewareContract, "Not authorized");
        require(authorizedCollections[initialCollection] != 0, "Collection not authorized");
        require(currentSupply[authorizedCollections[initialCollection]] + 1 <= supplyLimit[authorizedCollections[initialCollection]], "Limit reached");
        ERC721 collectionRedeem = ERC721(initialCollection);
        require(collectionRedeem.ownerOf(tokenId) == owner, "Don't own that token");
        require(redeemedToken[authorizedCollections[initialCollection]][initialCollection][tokenId] == 0x0000000000000000000000000000000000000000, "Token redeemd already");
        
        currentSupply[authorizedCollections[initialCollection]] = currentSupply[authorizedCollections[initialCollection]] + 1;
        redeemedToken[authorizedCollections[initialCollection]][initialCollection][tokenId] = owner;

        _mint(owner, authorizedCollections[initialCollection], 1, "");

        return 1;
    }

    // Only from the same colleciton
    function redeemBatch(address owner, address initialCollection, uint256[] calldata tokenIds) public payable {
        require(msg.sender == redemptionMiddlewareContract, "Not authorized");
        require(tokenIds.length > 0, "Mismatch of length");
        require(authorizedCollections[initialCollection] != 0, "Collection not authorized");
        require(currentSupply[authorizedCollections[initialCollection]] + tokenIds.length <= supplyLimit[authorizedCollections[initialCollection]], "Limit reached");
        ERC721 collectionRedeem = ERC721(initialCollection);

        for(uint256 i = 0; i < tokenIds.length; ++i) {
            require(redeemedToken[authorizedCollections[initialCollection]][initialCollection][tokenIds[i]] == 0x0000000000000000000000000000000000000000, "Token redeemd already");
            require(collectionRedeem.ownerOf(tokenIds[i]) == owner, "Don't own that token");
            redeemedToken[authorizedCollections[initialCollection]][initialCollection][tokenIds[i]] = owner;
        }

        currentSupply[authorizedCollections[initialCollection]] = currentSupply[authorizedCollections[initialCollection]] + tokenIds.length;

        _mint(owner, authorizedCollections[initialCollection], tokenIds.length, "");
    }

    // Forge function
    function forgeToken(uint256 tokenId, uint256 amount) public {
        require(forgingContractAddresses[tokenId] != 0x0000000000000000000000000000000000000000, "No forging address set for this token");
        require(balanceOf(msg.sender, tokenId) >= amount, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        
        burn(msg.sender, tokenId, amount); // Burn one the ERC-1155 token
        
        ForgeTokenContract forgingContract = ForgeTokenContract(forgingContractAddresses[tokenId]);
        forgingContract.forgeToken(amount, tokenId, msg.sender); // Mint the ERC-721 token
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
    function hasBeenRedeem(address initialCollection, uint256 tokenId) public view returns(address) {
        return redeemedToken[authorizedCollections[initialCollection]][initialCollection][tokenId];
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }

    // --------
    // Setter
    // --------

    function setTokenURIs(uint256 tokenId, string calldata newUri) public onlyOwner {
        tokenURIs[tokenId] = newUri;
    }

    function setSupply(uint256 tokenId, uint256 newSupply) public onlyOwner {
        supplyLimit[tokenId] = newSupply;
    }

    function setForgingAddress(uint256 tokenId, address forgingAddress) public onlyOwner {
        forgingContractAddresses[tokenId] = forgingAddress;
    }

    function setAuthorizedCollection(address authorizedCollection, uint256 tokenId) public onlyOwner {
        authorizedCollections[authorizedCollection] = tokenId; // token id 0 will unauthorize the collection
    }

    function setMiddleware(address newContractAddress) public onlyOwner {
        redemptionMiddlewareContract = newContractAddress;
    }

    // In case someone send money to the contract by mistake
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}