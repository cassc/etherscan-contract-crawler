// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./INmbBreeder.sol";

struct Parents {
    uint256 parent1;
    uint256 parent2;
}

contract BabyCamels is Ownable, ERC721Enumerable, INmbBreeder {
    using SafeMath for uint256;

    bool public breedingActive = false;

    mapping(uint256 => uint256) private _parentToBabyCamel;
    mapping(uint256 => Parents) private _babyCamelToParents;
    IERC721 private ArabianCamelsContract;

    string public baseURI;

    constructor(address camelsContractAddress) ERC721("Baby Camels Season 1", "BC1") {
        ArabianCamelsContract = IERC721(camelsContractAddress);
    }

    function toggleBreedingActive() external onlyOwner {
        breedingActive = !breedingActive;
    }

    function breed(uint256 parentTokenId1, uint256 parentTokenId2) public {
        require(breedingActive, "Breeding season is not active");
        require(msg.sender == ArabianCamelsContract.ownerOf(parentTokenId1) && msg.sender == ArabianCamelsContract.ownerOf(parentTokenId2), "Must own both camels to breed");
        require(_parentToBabyCamel[parentTokenId1] == 0 && _parentToBabyCamel[parentTokenId2] == 0, "Camel has already mated this season");

        _breed(parentTokenId1, parentTokenId2);
    }

    function _breed(uint256 parentTokenId1, uint256 parentTokenId2) private {
        uint256 babyCamelId = totalSupply()+1;
        
        _parentToBabyCamel[parentTokenId1] = babyCamelId;
        _parentToBabyCamel[parentTokenId2] = babyCamelId;
        _babyCamelToParents[babyCamelId] = Parents({parent1: parentTokenId1, parent2: parentTokenId2});

        _safeMint(msg.sender, babyCamelId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function getWalletOf(address wallet) external view returns(uint256[] memory) {
      uint tokenCount = balanceOf(wallet);

      uint256[] memory ownedTokenIds = new uint256[](tokenCount);
      for(uint i = 0; i < tokenCount; i++){
        ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
      }

      return ownedTokenIds;
    }

    function getHasMated(
        address parentTokenContractAddress, 
        uint256[] memory tokenIds
    ) external view override returns(bool[] memory) {
        require(parentTokenContractAddress == address(ArabianCamelsContract), "Invalid contract address");

        bool[] memory hasMated = new bool[](tokenIds.length);

        for(uint i = 0; i < tokenIds.length; i++) {
            hasMated[i] = (_parentToBabyCamel[tokenIds[i]] != 0);
        }

        return hasMated;
    }

    function getChildOf(address parentTokenContractAddress, uint256 tokenId) external view override returns (uint256) {
        require(parentTokenContractAddress == address(ArabianCamelsContract), "Invalid contract address");

        return _parentToBabyCamel[tokenId];
    }
    
    function getParentsOf(uint256 tokenId) external view override returns (address, uint256, address, uint256) {
        return (
            address(ArabianCamelsContract), 
            _babyCamelToParents[tokenId].parent1,
            address(ArabianCamelsContract),
            _babyCamelToParents[tokenId].parent2
        );
    }
}