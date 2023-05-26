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

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

abstract contract ERC1155 {
    function balanceOf(address account, uint256 id) public view virtual returns (uint256);
}

contract ForgedToken is ERC721A, Ownable {
    address redeemCollectionAddress;
    mapping (uint256 => uint256) public tokenMetadataLink;
    mapping (uint256 => string) public tokenMetadataUri;

    constructor () ERC721A("ForgedToken", "FT") {
        tokenMetadataUri[1] = "https://opensea.mypinata.cloud/ipfs/QmeNFdcKW6McnrT5MhVrTah4MTcoybZLKTyDQpovjXApyg/652";
    }

    // Making sure we start the token ID at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
 
    // Mint
    function forgeToken(uint256 amount, uint256 tokenId, address owner) public {
        require(msg.sender == redeemCollectionAddress, "Not authorized");
        uint256 mintedTokenId = _currentIndex;

        // Setting the metadata
        for(uint256 i = 0; i <= amount; ++i) {
            tokenMetadataLink[mintedTokenId] = tokenId;
            mintedTokenId = mintedTokenId + 1;
        }

        _safeMint(owner, amount); // Minting of the token
    }

    function airdropToken(uint256[] calldata amount, uint256[] calldata tokenIds, address[] calldata owners) public onlyOwner {
        uint256 mintedTokenId = _currentIndex;

        for(uint256 i = 0; i < owners.length; ++i) {
            for(uint256 i2 = 0; i2 <= amount[i]; ++i2) {
                tokenMetadataLink[mintedTokenId] = tokenIds[i];
                mintedTokenId = mintedTokenId + 1;
            }
            
            _safeMint(owners[i], amount[i]); // Minting of the token
        }
    }

    function setMetadataUri(uint256 redeemedTokenId, string calldata tokenUri) public onlyOwner {
        tokenMetadataUri[redeemedTokenId] = tokenUri;
    }

    function setTokenMetadataLink(uint256 tokenId, uint256 redeemedTokenId) public onlyOwner {
        tokenMetadataLink[tokenId] = redeemedTokenId;
    }
    
    /** 
        CONTRACT MANAGEMENT FUNCTIONS 
    **/ 

    function changeRedeemCollection(address newContract) public onlyOwner {
        redeemCollectionAddress = newContract;
    }
 
    // Withdraw funds from the contract

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenMetadataUri[tokenMetadataLink[tokenId]];
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}                                                                                                                                                                                                                                                    
}