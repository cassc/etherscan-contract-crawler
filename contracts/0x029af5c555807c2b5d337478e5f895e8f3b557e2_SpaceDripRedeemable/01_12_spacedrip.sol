// SPDX-License-Identifier: MIT
//
//          [email protected]@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         Redemption Contract - Space Drip (made by @CardilloSamuel)

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract SpaceDripRedeemable is ERC721A, Ownable {
    mapping (address => bool) public authorizedCollection;
    mapping (address => mapping (uint256 => address)) redeemedToken;
    address redemptionMiddlewareContract;
    string public baseURI = "https://redemptionassets.rtfkt.com/";
 
    event tokenRedeemed(address redeemerAddress, address collectionAddress, uint256 redeemedTokenId, uint256 newTokenId);
    event tokenAirdropped(string artistName, uint256 newTokenId);

    constructor () ERC721A("SpaceDripRedeemable", "SDR") {
        authorizedCollection[0xd3f69F10532457D35188895fEaA4C20B730EDe88] = true; // Space Drip 1
        authorizedCollection[0xc541fC1Aa62384AB7994268883f80Ef92AAc6399] = true; // Space Drip 1.2
    }

    // Making sure we start the token ID at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
 
    // Mint
    function redeem(address owner, address initialCollection, uint256 tokenId) public returns(uint256) {
        require(msg.sender == redemptionMiddlewareContract, "Not authorized");
        require(authorizedCollection[initialCollection], "Collection not authorized");
        require(redeemedToken[initialCollection][tokenId] == 0x0000000000000000000000000000000000000000, "Token has been redeemed already");
        ERC721A collectionRedeem = ERC721A(initialCollection);
        string memory spaceDripUri = collectionRedeem.tokenURI(tokenId);
        require(collectionRedeem.ownerOf(tokenId) == owner, "Don't own that token");
        require(keccak256(bytes(spaceDripUri)) != keccak256(bytes("https://gateway.pinata.cloud/ipfs/QmPCpmaZzCjJyrZTFfK79JHzEFfesHjyscjTcYTM3epVGT/unopened.json")), "Can't redeem a capsule");
        require(keccak256(bytes(spaceDripUri)) != keccak256(bytes("https://gateway.pinata.cloud/ipfs/QmTDJrbrqkQe7pcEqss8JWyRCJBYWo9GXLQga5J3Q8Jxxi/unopened.json")), "Can't redeem a capsule");

        uint256 mintedTokenId = _currentIndex;
        _safeMint(owner, 1); // Minting of the token
        redeemedToken[initialCollection][tokenId] = owner;
        emit tokenRedeemed(owner, initialCollection, tokenId, mintedTokenId);
        return mintedTokenId;
    }

    function airdrop(address to, string calldata artistName) public onlyOwner {
        uint256 mintedTokenId = _currentIndex;
        _safeMint(to, 1); // Minting of the token
        emit tokenAirdropped(artistName, mintedTokenId);
    }

    function hasBeenRedeem(address initialCollection, uint256 tokenId) public view returns(address) {
        return redeemedToken[initialCollection][tokenId];
    }
    
    /** 
        CONTRACT MANAGEMENT FUNCTIONS 
    **/ 

    function changeRedemptionMiddleware(address newContract) public onlyOwner {
        redemptionMiddlewareContract = newContract;
    }

    function toggleAuthorizedCollection(address collectionAddress) public onlyOwner {
        authorizedCollection[collectionAddress] = !authorizedCollection[collectionAddress];
    }

    function toggleRedeemStatus(address collectionAddress, uint256 tokenId, address newAddress) public onlyOwner {
        require(authorizedCollection[collectionAddress], "Collection not authorized");
        redeemedToken[collectionAddress][tokenId] = newAddress;
    }
 
    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }                                                                                                                                                                                                                                                                 
}