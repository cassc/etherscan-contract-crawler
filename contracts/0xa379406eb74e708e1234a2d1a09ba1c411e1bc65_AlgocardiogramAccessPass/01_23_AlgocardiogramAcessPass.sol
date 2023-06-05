// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


import "hardhat/console.sol";

contract AlgocardiogramAccessPass is ERC721URIStorage, IERC721Enumerable, ERC721Enumerable, ERC2981, PaymentSplitter, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;
    address syntContractAddress;
    uint public constant mintPrice = (1 ether/20); // 0.05 ETH
    uint public constant maxSupply = 500; // total number of mintable tokens
    uint public constant userLimit = 2; // max number of NFTs per wallet

    constructor(address marketplaceAddress, 
                address deployedSyntContractAddress,
                address[] memory _payees,
                uint256[] memory _shares) ERC721("Algocardiogram Access Pass", "ACGP") PaymentSplitter(_payees, _shares) {
        contractAddress = marketplaceAddress;
        syntContractAddress = deployedSyntContractAddress;
    }
    
    function contractURI() public view returns (string memory) {
        return "https://api.stage.adiem.com/synerative/algocardiogramaccess";
    }
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

        function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981, IERC165, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

        function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    

    /* funtion to get all _owner nft tokens id */
    function getTokenIds(address _owner) public view returns (uint[] memory) {
        uint[] memory _tokensOfOwner = new uint[](ERC721.balanceOf(_owner));
        uint i;

        for (i=0;i<ERC721.balanceOf(_owner);i++){
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }
    
    function checkIfAddressOwnsAnyNFT(address _nftAddress, address _owner) public view returns (bool) {
        ERC721Enumerable nftContract = ERC721Enumerable(_nftAddress);
        
        if (nftContract.balanceOf(_owner) > 0) {
            return true;
        }

        return false;
    }

    function createToken(string memory IPFStokenURI) public payable returns (uint) {
        if (checkIfAddressOwnsAnyNFT(syntContractAddress, msg.sender) != true){
            require(msg.value >= mintPrice, "Mint price is 0.05 ETH."); 
        }
        // add the actual price set at the business logic
        require(_tokenIds.current() <= maxSupply, "All tokens have been minted.");
        require(ERC721.balanceOf(msg.sender) < userLimit, "You can only mint 2 tokens per wallet");
        
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, IPFStokenURI);
        _setTokenRoyalty(newItemId, address(this), 1000); // 10% royalties enforced on-chain
        setApprovalForAll(contractAddress, true);

        return newItemId;
    }

}