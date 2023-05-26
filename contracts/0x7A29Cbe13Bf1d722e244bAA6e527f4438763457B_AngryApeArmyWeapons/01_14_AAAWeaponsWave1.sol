pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AAAToken {
    function tokensOfOwner(address _owner) external view returns(uint[] memory );
}

contract AngryApeArmyWeapons is ERC721Enumerable, Ownable {
    using SafeMath for uint;
    
    string baseURI;
    string public contractURI;
    
    uint public constant MAX_CLAIM = 50;

    uint public constant MAX_WEAPONS = 3333;
    
    AAAToken ogToken;
    
    bool public hasDropStarted = false;
    bool public hasDropFinished = false;
    
    event WeaponMinted(uint indexed tokenId, address indexed owner);
    
    constructor(string memory baseURI_, string memory contractURI_, address ogAddress_)
        ERC721("AAA Weapons Wave 1", "AAAW1") {

        ogToken = AAAToken(ogAddress_);
        baseURI = baseURI_;
        contractURI = contractURI_;
    }

    function claimByOwner(address _to, uint[] memory _tokenIds) public onlyOwner {
        require(hasDropFinished, "AngryApeArmyWeapons::claimByOwner: Drop hasn't finished yet.");
        require(_tokenIds.length <= MAX_CLAIM, "AngryApeArmyWeapons::claimByOwner: Cannot claim more than MAX_CLAIM");

        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] < MAX_WEAPONS, "AngryApeArmyWeapons::claimByOwner: Token outside valid range.");
            _safeMint(_to, _tokenIds[i]);
            emit WeaponMinted(_tokenIds[i], _to);
        }
    }

    function checkClaimableWeapons(address user) public view returns (uint[] memory) {
        require(hasDropStarted, "AngryApeArmyWeapons::checkClaimableWeapons: Drop hasn't started.");

        uint[] memory ogTokenIds = ogToken.tokensOfOwner(user);

        uint tokensToClaim;
        
        for (uint i = 0; i < ogTokenIds.length; i++) {
            if (!_exists(ogTokenIds[i]) && tokensToClaim < MAX_CLAIM) {
                tokensToClaim++;
            }
        }

        require(tokensToClaim > 0, "AngryApeArmyWeapons::checkClaimableWeapons: Address does not have any tokens to claim.");

        uint[] memory claimableTokens = new uint[](tokensToClaim);
        uint claimableTokensCount;

        for (uint i = 0; i < ogTokenIds.length; i++) {
            if (!_exists(ogTokenIds[i]) && claimableTokensCount < MAX_CLAIM) {
                claimableTokens[claimableTokensCount] = ogTokenIds[i];
                claimableTokensCount++;
            }
        }
        return claimableTokens;
    }
    
    function claimWeapons() external {

        uint[] memory ogTokenIds = checkClaimableWeapons(msg.sender);
        
        for (uint i = 0; i < ogTokenIds.length; i++) {
            _safeMint(msg.sender, ogTokenIds[i]);
            emit WeaponMinted(ogTokenIds[i], msg.sender);
        }
    }

    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }
    
    function setContractURI(string memory _URI) external onlyOwner {
        contractURI = _URI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function startDrop() external onlyOwner {
        require(!hasDropStarted, "AngryApeArmyWeapons::startDrop: Drop already active.");
        require(!hasDropFinished, "AngryApeArmyWeapons::startDrop: Drop has already finished.");
        
        hasDropStarted = true;
    }

    function pauseDrop() external onlyOwner {
        require(hasDropStarted, "AngryApeArmyWeapons::pauseDrop: Drop is not active.");
        require(!hasDropFinished, "AngryApeArmyWeapons::pauseDrop: Drop has already finished.");
        
        hasDropStarted = false;
    }

    function finishDrop() external onlyOwner {
        require(hasDropStarted, "AngryApeArmyWeapons::finishDrop: Drop is not active.");
        require(!hasDropFinished, "AngryApeArmyWeapons::finishDrop: Drop has already finished.");
        
        hasDropStarted = false;
        hasDropFinished = true;
    }
}