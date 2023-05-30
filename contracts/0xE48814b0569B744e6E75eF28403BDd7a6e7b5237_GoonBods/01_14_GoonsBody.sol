// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

/*
* @title ERC721 token for Goon bods
*/
contract GoonBods is ERC721Enumerable, ERC721Burnable, Ownable {
    string private baseTokenURI;

    AvatarContract goonContract;

    mapping(uint256 => uint256) mintedTraitAmount;

    mapping(uint256 => bool) usedGoons;
    mapping(uint256 => Body) bodies;

    // array length is total number of traits
    uint256[158] public scarcities = [
       250,  100, 1500,  600,  250,  250,  600,   10, 600,   75, 1500, 1500,
       100,  400,  400,  400,  400,   50,   75,   75, 150,  800, 1000,  100,
      1000, 1000,  600,  200, 1000,  250,  100,  250, 200, 1500,   75,  400,
       600,  500,  300,   25,  800,  500,  600,  200, 300, 1500,  300, 1500,
       600,   10, 1000, 1500,  150,  400,  400,  250, 100, 1000,  600,  600,
      1500, 1500,  300,  150, 1500, 1500, 1500,  500, 800,  500, 1000, 1000,
       400,  600,  150,  250,  150, 1000,   75,  250, 150,  300,   10,  100,
       600,  100,  800,  150,  800,  250,  500,   25,  50,   50, 1000,  150,
       200,  200,  500,  300,  200, 1500, 1000,   50, 500,  800,  800,   50,
       400,  500,  150,  500,  800,   10, 1000,  250, 150,  500,  250,  100,
       800,  200,  100,  800,   75,   75,   25,  800, 400,  200,  600,  300,
       150, 1500,  200,   10,  800,  300, 1500,  800, 500,  300,  100, 1000,
        75,   75,  200,  400, 1000,  100,  100, 1500, 100,  300,  300,  100,
        25,   25
    ];

    uint256 public constant MAX_BOTTOM_ID = 30;
    uint256 public constant MAX_FOOTWEAR_ID = 59;
    uint256 public constant MAX_BELT_ID = 88;
    uint256 public constant MAX_WEAPON_ID = 120;
    uint256 public constant MAX_ACCESSORY_ID = 157;
    uint256 constant NO_TRAIT = 255;

    event BodyMinted(address indexed _to, uint256 indexed _tokenId, uint256 indexed _goonId, uint8 _bottom, uint8 _footwear, uint8 _belt, uint8 _leftHand, uint8 _rightHand);

    struct Body {
        uint8 bottom;
        uint8 footwear;
        uint8 belt;
        uint8 leftHand;
        uint8 rightHand;
    }

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _goonContract
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;

        goonContract = AvatarContract(_goonContract);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mint(uint8 _bottom, uint8 _footwear, uint8 _belt, uint8 _leftHand, uint8 _rightHand, uint256 goonID) external payable {
        require(goonContract.ownerOf(goonID) == msg.sender, "Mint: Avatar not owned by sender");
        require(!usedGoons[goonID], "Mint: Goon already used");
        require((_bottom <= MAX_BOTTOM_ID || _bottom == NO_TRAIT) &&
                ((MAX_BOTTOM_ID <_footwear && _footwear <= MAX_FOOTWEAR_ID) || _footwear == NO_TRAIT) &&
                ((MAX_FOOTWEAR_ID <_belt && _belt <= MAX_BELT_ID) || _belt == NO_TRAIT) &&
                ((MAX_BELT_ID <_leftHand && _leftHand <= MAX_WEAPON_ID) || _leftHand == NO_TRAIT) &&
                ((MAX_WEAPON_ID <_rightHand && _rightHand <= MAX_ACCESSORY_ID) || _rightHand == NO_TRAIT),
                "Mint: At least one trait id out of range");
        require(_bottom != NO_TRAIT || _footwear != NO_TRAIT || _belt != NO_TRAIT || _leftHand != NO_TRAIT || _rightHand != NO_TRAIT, "Mint: At least one trait needs to be selected");
        require(msg.value == getBodyPrice(_bottom, _footwear, _belt, _leftHand, _rightHand), "Mint: payment incorrect");
        require(isTraitAvailable(_bottom) && isTraitAvailable(_footwear) && isTraitAvailable(_belt) && isTraitAvailable(_leftHand) && isTraitAvailable(_rightHand), "Mint: At least one trait sold out");

        Body memory body = Body(_bottom, _footwear, _belt, _leftHand, _rightHand);
        uint256 tokenId = totalSupply() + 1;
        bodies[tokenId] = body;

        if(_bottom != NO_TRAIT) mintedTraitAmount[_bottom] += 1;
        if(_footwear != NO_TRAIT) mintedTraitAmount[_footwear] += 1;
        if(_belt != NO_TRAIT) mintedTraitAmount[_belt] += 1;
        if(_leftHand != NO_TRAIT) mintedTraitAmount[_leftHand] += 1;
        if(_rightHand != NO_TRAIT) mintedTraitAmount[_rightHand] += 1;

        usedGoons[goonID] = true;

        _mint(msg.sender, tokenId);

        emit BodyMinted(msg.sender, tokenId, goonID, _bottom, _footwear, _belt, _leftHand, _rightHand);
    }

    function withdrawEther(address payable _to, uint256 _amount) external onlyOwner {
        _to.transfer(_amount);
    }    

    function isTraitAvailable(uint traitId) public view returns (bool) {
        return traitId == NO_TRAIT || mintedTraitAmount[traitId] < scarcities[traitId];
    }

    function getTraitAvailability() public view returns (bool[] memory){
        bool[] memory result = new bool[](scarcities.length);
        for(uint256 i; i < scarcities.length; i++) {
            result[i] = isTraitAvailable(i);
        }
        return result;
    }

    function getUnusedAvatarsByOwner(address owner) public view returns (uint256[] memory) {
        uint256[] memory tokens = goonContract.tokensOfOwner(owner);

        uint256 numUnused = 0;
        uint256[] memory result = new uint256[](tokens.length);
        for(uint256 i; i < tokens.length; i++) {
            if(!usedGoons[tokens[i]]) {
                result[numUnused] = tokens[i];
                numUnused++;
            }
        }
        return trim(result, numUnused);
    }

    function getUnusedAvatars() public view returns (uint256[] memory) {
        uint256 numUnused = 0;
        uint256[] memory result = new uint256[](9696);
        for(uint256 i=1; i <= 9696; i++) {
            if(!usedGoons[i]) {
                result[numUnused] = i;
                numUnused++;
            }
        }
        return trim(result, numUnused);
    }    

    function trim(uint256[] memory result, uint256 numUnused) internal pure returns (uint256[] memory) {
        uint256[] memory trimmedResult = new uint256[](numUnused);
        for(uint256 i; i < numUnused; i++) {
            trimmedResult[i] = result[i];
        }
        return trimmedResult; 
    }

    function getMintedTraitAmounts() public view returns (uint256[] memory) {
        uint256[] memory result = new uint[](MAX_ACCESSORY_ID);

        for(uint256 i = 0; i < MAX_ACCESSORY_ID; i++) {
            result[i] = mintedTraitAmount[i];
        }
        return result;
    }

    function getTraits(uint256 tokenId) public view returns (uint256[] memory) {
        uint256[] memory result = new uint[](5);

        result[0] = bodies[tokenId].bottom;
        result[1] = bodies[tokenId].footwear;
        result[2] = bodies[tokenId].belt;
        result[3] = bodies[tokenId].leftHand;
        result[4] = bodies[tokenId].rightHand;

        return result;
    }

    function getBodyPrice(uint8 _bottom, uint8 _footwear, uint8 _belt, uint8 _leftHand, uint8 _rightHand) public view returns (uint256) {
        return getTraitPrice(_bottom) + getTraitPrice(_footwear) + getTraitPrice(_belt) + getTraitPrice(_leftHand) + getTraitPrice(_rightHand);
    }

    function getTraitPrice(uint256 trait) public view returns (uint256) {
        if(trait == NO_TRAIT || scarcities[trait] > 100) return 0;

        uint256 scarcity = scarcities[trait];

        if(scarcity > 75) return 69000000000000000;
        if(scarcity > 50) return 99000000000000000;
        if(scarcity > 25) return 190000000000000000;
        if(scarcity > 10) return 390000000000000000;
        return 690000000000000000;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}

interface AvatarContract is IERC721 {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}