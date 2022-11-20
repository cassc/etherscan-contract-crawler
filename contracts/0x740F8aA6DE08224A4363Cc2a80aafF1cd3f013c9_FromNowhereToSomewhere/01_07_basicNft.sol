// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./auctionNft.sol";

contract FromNowhereToSomewhere is ERC721A, Ownable {
    string public BASE_URI = "https://epolabs.io/api/somewherefromnowhere/";
    NTSAuction auctionContract;

    struct tokenInfo {
        string imageId;
        string name;
    }
    
    mapping(uint => tokenInfo) public tokensInfo;
    mapping(string => bool) public imageIds;

    constructor(address auctionContractAddress) ERC721A("FromNowhereToSomewhere", "FNTS") {
        auctionContract = NTSAuction(auctionContractAddress);
    }

    function mint(string memory imageId, string memory name) external payable {
        require(imageIds[imageId] == false, "Image already minted");

        (string memory bidImageName, address bidder) = auctionContract.bidStorage(imageId);

        require(keccak256(bytes(bidImageName)) == keccak256(bytes(name)), 'Not a valid image+name pair');
        require(bidder == msg.sender, 'This is not your image to mint');

        uint256 _newTokenId = totalSupply();
        tokensInfo[_newTokenId] = tokenInfo(imageId, name);
        imageIds[imageId] = true;

        _mint(msg.sender, 1);
    }

    function adminMint(string memory imageId, string memory name) external payable onlyOwner {
        require(imageIds[imageId] == false, "Image already minted");

        uint256 _newTokenId = totalSupply();
        tokensInfo[_newTokenId] = tokenInfo(imageId, name);
        imageIds[imageId] = true;

        _mint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string.concat(BASE_URI, Strings.toString(tokenId));
    }

    function setBaseTokenURI(string memory _tokenURI) public onlyOwner {
        BASE_URI = _tokenURI;
    }

    function setAuctionContract(address newAuctionContractAddress) public onlyOwner {
        auctionContract = NTSAuction(newAuctionContractAddress);
    }
}