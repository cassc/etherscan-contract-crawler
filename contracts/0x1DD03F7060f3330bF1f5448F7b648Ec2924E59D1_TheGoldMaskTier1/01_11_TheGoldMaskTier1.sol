// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheGoldMaskTier1 is ERC1155, Ownable {
    
    string private _uri;
    string private _baseUri;
    bool private baseUriSet = false;
    
    uint256 public tokenCount = 200; // To ensure the target users that only 200 NFTs will exist!
    mapping(uint256=>bool) mintedTokens;
    uint8 public maxMintPerRound = 20; // how many NFSs are minted per round
    uint8 public maxAirdropPerRound = 20; // how many NFSs are airdropped per round
    
    constructor() ERC1155("") {}
    
    
    function setMaxMintPerRound(uint8 mpr) external onlyOwner {
        maxMintPerRound = mpr;
    }
    
    function setMaxAirdropPerRound(uint8 apr) external onlyOwner {
        maxAirdropPerRound = apr;
    }
    
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(ids.length <= maxMintPerRound, "The maximum number of NFTs which can be minted in one round is exceeded!");        
        
        for (uint256 i = 0; i < ids.length; ++i) {
            require(ids[i]<=tokenCount, "ID must be lower than or equal to tokenCount!");
            require(amounts[i] == 1, "It is not permitted to mint more than one NFT for the same ID!");
            require(mintedTokens[ids[i]] == false, "ID is already minted!");
            mintedTokens[ids[i]] = true;
        }
        
        _mintBatch(to, ids, amounts, "");          
    }

    function airdrop(address[] memory to, uint256[] memory ids) external onlyOwner {
        
        require(to.length == ids.length, "address and ids length mismatch");
        require(to.length <= maxAirdropPerRound, "The maximum number of NFTs which can be airdropped in one round is exceeded!");
        
        for (uint256 i = 0; i < ids.length; ++i) {
            require(mintedTokens[ids[i]], "ID is not minted yet!");
            require(to[i] != address(0), "ERC1155: transfer to the zero address");
        }

        for (uint256 i = 0; i < to.length; ++i) {
         
            uint256 id = ids[i];
                        
            uint256 fromBalance = balanceOf(msg.sender,id);            
            require(fromBalance == 1, "Airdrop: fromBalance must be 1 for every tokenID");
            
            safeTransferFrom(msg.sender, to[i], id , fromBalance, "");
        }
    }    

    function setBaseUri(string memory newBaseUri) external onlyOwner {
        _baseUri = newBaseUri;
        _uri = string(abi.encodePacked(_baseUri,"/{id}.json"));
        baseUriSet = true;
    }

    function uri(uint256 _tokenid) override public view returns (string memory) {
        require(baseUriSet,"baseUri has not been set yet");
        return string(
            abi.encodePacked(
                _baseUri,"/",Strings.toString(_tokenid),".json"
            )
        );
    }
}