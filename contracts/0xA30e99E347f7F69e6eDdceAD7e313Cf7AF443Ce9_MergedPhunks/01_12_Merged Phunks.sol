// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract MergedPhunks is ERC721URIStorage, Ownable{
    

    uint256 public maxMintAmount = 12;
    uint256 public maxSupply = 10000;
    uint256 public costPerNft = 0.0025 * 1e18;
    string private metadataFolderIpfsLink;
    string constant baseExtension = ".json";
    uint256 public publicmintActiveTime =1663115737;
    mapping(uint256 => uint256) public tokenIdIndex; 
    mapping(uint256 => uint256 ) public usedTokenId;
    mapping(address => uint256) public indivisualcounter;
    uint256 public totalSupply=0;

    // event

    event MintNFT(uint id);

    /// @notice constructor function will pass collection name and symbol to the parent contract that we have inherited from openzeppelin
    constructor() ERC721("MergedPhunks", "Phunks") {
    }

    ///@notice this is a support interface! we must need this
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ///@notice this function will generate a random number
    function random(uint randNonce) private view returns (uint256) {
        for(uint256 i = 0;i<maxSupply;i++){
            uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % maxSupply;
            if(usedTokenId[randomNum]==0){
                return randomNum;
            }
        }
        return 0;
    } 

    ///@notice user can mint more then one NFT using this minting function
    function mint(uint256 _mintNumber) public payable{
        require(indivisualcounter[msg.sender]+_mintNumber <= maxMintAmount,"This person has reached his limit");
        if(indivisualcounter[msg.sender]==0){

        require((_mintNumber-1)*costPerNft <= msg.value,"NOT ENOUGH MONEY SENT");

        }
        else{

            require(_mintNumber*costPerNft <= msg.value,"NOT ENOUGH MONEY SENT");
        }
        for(uint i=0; i<_mintNumber ; i++){
            mintNFT();
        }
    }

    ///@notice this private function is a helper function for bulk mint
    function mintNFT() private {
        require(totalSupply<maxSupply,"Total number of NFT reached");
        uint256 newTokenId = random(totalSupply);
        usedTokenId[newTokenId] = 1;
        _safeMint(msg.sender, newTokenId);

        _setTokenURI(newTokenId, getTokenURI(newTokenId));
        totalSupply+=1;
        indivisualcounter[msg.sender]+=1;
        tokenIdIndex[totalSupply] = newTokenId;
        emit MintNFT(newTokenId);
    }

    function getTokenURI( uint256 _id) public view returns (string memory) {

        return string(abi.encodePacked(metadataFolderIpfsLink, Strings.toString(_id), baseExtension));
    }



  
    // only Owner
     function withdrawFunds() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setTheCostPerNft(uint256 _newCostPerNft) public onlyOwner {
        costPerNft = _newCostPerNft;
    }

    function setMaxMintAmountForUser(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMetadataFolderIpfsLink(string memory _newMetadataFolderIpfsLink) public onlyOwner {
        metadataFolderIpfsLink = _newMetadataFolderIpfsLink;
    }

    function setSaleActiveTime(uint256 _publicmintActiveTime) public onlyOwner {
        publicmintActiveTime = _publicmintActiveTime;
    }
}