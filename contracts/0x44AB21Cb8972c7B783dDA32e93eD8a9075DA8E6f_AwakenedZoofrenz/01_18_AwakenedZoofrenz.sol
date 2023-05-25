// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./IERC1155Burnable.sol";
import "./IZoofrenzToken.sol";
import "./IZoofrenzERC20.sol";
import "./IAwakenedZoofrenzVRF.sol";

contract AwakenedZoofrenz is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    IZoofrenzToken ZFT;
    IAwakenedZoofrenzVRF VRF;
    
    uint256 public constant maxAwakenSupply = 4000;

    uint256 public migrateReward = 200;

    uint256 public numberOfAwakened;

    string public baseURI;
    
    string public unrevealedURI;
    
    bool public isMigrateEnabled;

    bool public isAwakenEnabled;

    mapping(address=>bool) public operators;
    
    mapping(uint256=>uint256) private _frenzRarities;
    
    mapping(uint256=>uint256) private VRFRequestIds;
    
    mapping(uint256=>uint256) private originalIds;

    mapping(uint256=>uint256) private awakenedIds;

    mapping(uint256=>uint256) private migratedIds;

    mapping(uint256=>uint256) private VRFAwakenedIds;

    constructor(address initVRFAddress) ERC721A ("Zoofrenz Apefrenz 2.0", "ZA2") {
        VRF = IAwakenedZoofrenzVRF(initVRFAddress);

        isMigrateEnabled = true;
        isAwakenEnabled = true;
    }

    function setVRF(address newAddress) external onlyOwner {
        VRF = IAwakenedZoofrenzVRF(newAddress);
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 6666;
    }

    function setRarities(uint256[] calldata tokenIds, uint256[] calldata rarities) external onlyOwner {
        require(tokenIds.length == rarities.length, "tokenIds does not match rarities length");
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            _frenzRarities[tokenIds[i]] = rarities[i];
        }
    }

    function frenzRarities(uint256 tokenId) external view returns (uint256) {
        uint256 editionId = originalIds[tokenId];

        if(editionId < 6666) {
            return ZFT.frenzRarities(editionId);
        } else {
            if(address(VRF) != address(0))
                return _frenzRarities[VRF.getResult(VRFRequestIds[tokenId])];
            else
                return 0;
        }
    }

    function getStartTokenId() external pure returns (uint256) {
        return _startTokenId();
    }

    function getAwakenedId(uint256 originalId) external view returns (uint256) {
        return awakenedIds[originalId];
    }

    function getOriginalId(uint256 tokenId) external view returns (uint256) {
        return originalIds[tokenId];
    }

    function getVRFRequestId(uint256 tokenId) external view returns (uint256) {
        return VRFRequestIds[tokenId];
    }

    function getVRFAwakenedId(uint256 requestId) external view returns (uint256) {
        return VRFAwakenedIds[requestId];
    }

    function getMigratedId(uint256 tokenId)  external view returns (uint256) {
        return migratedIds[tokenId];
    }

    function getRevealedId(uint256 tokenId) external view returns (uint256) {
        return VRFRequestIds[tokenId] != 0 ? VRF.getResult(VRFRequestIds[tokenId]) : originalIds[tokenId];
    }

    function setOriginalId(uint256 tokenId, uint256 zftId) external callerIsOperator {
        originalIds[tokenId] = zftId;
        awakenedIds[zftId] = tokenId;
    }

    function setMigratedId(uint256 tokenId, uint256 migratedId) external callerIsOperator {
        migratedIds[tokenId] = migratedId;
    }

    function setOperators(address[] calldata operator) external onlyOwner {
        for (uint256 i = 0; i < operator.length; i++) {
            operators[operator[i]] = true;
        }
    }

    function mint(address to, uint256 amount) external callerIsOperator {
        _safeMint(to, amount);    
    }

    function burn(uint256 tokenId) external callerIsOperator {
        _burn(tokenId, false);
    }

    function devMigrate(uint256[] calldata zftIds, address to) external onlyOwner {
        uint256 tokenId;
        uint256 startId = _totalMinted() + _startTokenId();

        for(uint256 i = 0; i < zftIds.length; i++) {
            tokenId = startId + i;
            
            originalIds[tokenId] = zftIds[i];
        }

        _safeMint(to, zftIds.length);
    }

    function requestVRF (uint256 tokenId) external callerIsOperator {
        uint256 rId = VRF.requestRandomWords();
        VRFRequestIds[tokenId] = rId;
        VRFAwakenedIds[rId] = tokenId;
    }

    function isTokenExist(uint256 tokenId) external view returns (bool){
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        uint256 editionId;

        if(VRFRequestIds[tokenId] != 0) {
            editionId = VRF.getResult(VRFRequestIds[tokenId]);
            
            if(editionId == 0)
                return unrevealedURI;
        } else {
            editionId = originalIds[tokenId];
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, editionId.toString(), ".json")) : "";
	}

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setUnvealedURI (string memory newURI) external onlyOwner {
        unrevealedURI = newURI;
    }

    modifier callerIsOperator() {
        require(operators[msg.sender], "not operator");
        _;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }
}