// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract VictoriaVRLand is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 constant internal ID_LENGTH = 1e7;

    string public baseURI;
    bool revealed = false;
    uint256 public startTime; 

    uint256[] public tokenIds;
    mapping(address => uint8[]) whitelist;

    event Mint(address user, uint256 tokenId);

    constructor(
        string memory name, 
        string memory symbol,
        string memory _baseURI,
        uint256 _startTime
    ) ERC721(name, symbol) {
        tokenIds = new uint256[](4);
        baseURI = _baseURI;
        startTime = _startTime;
    }

    // ====================== OWNER FUNCTIONS ====================== //

    function setUsersWhitelist(address[] calldata users, uint8[][] calldata tiers) external onlyOwner {
        require(users.length == tiers.length, "INCOMPATIBLE_ARRAY_LENGTHS");

        for (uint i = 0; i < users.length; i++) {
            delete whitelist[users[i]];

            for (uint j = 0; j < tiers[i].length; j++) {
                uint8 tier = tiers[i][j];
                require(tier > 0 && tier < 5, "INVALID_TIER");
                whitelist[users[i]].push(tier);
            }
        }
    }

    function reveal(bool _status) external onlyOwner {
        revealed = _status;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    
    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    // ====================== EXTERNAL FUNCTIONS ====================== //

    function mintAll(address receiver) external {
        uint256 length = whitelist[receiver].length;
        require(length > 0, "NOT_WHITELISTED");

        while (length > 0) {
            mint(receiver);
            length--;
        }
    }

    function mint(address receiver) public { 
        uint256 length = whitelist[receiver].length;
        require(block.timestamp >= startTime, "NOT_STARTED");
        require(length > 0, "NOT_WHITELISTED");

        uint8 tier = whitelist[receiver][length - 1];
        whitelist[receiver].pop();

        uint256 tokenIdByTier = tokenIds[tier - 1]++;
        require(tokenIdByTier < ID_LENGTH, "MAX_TOKENS");

        uint256 tokenId = tier * ID_LENGTH + tokenIdByTier;
        _safeMint(receiver, tokenId);

        emit Mint(receiver, tokenId);
    }

    // ====================== VIEW FUNCTIONS ====================== //

    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory _tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            _tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return _tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint8 tier = getTierByTokenId(tokenId);
        uint256 tokenIdByTier = tokenId % ID_LENGTH;

        return bytes(baseURI).length > 0 ? 
            string(abi.encodePacked(
                baseURI,
                uint256(tier).toString(),
                "/",
                revealed ? tokenIdByTier.toString() : "hidden",
                ".json"
            )) 
            : "";
    }

    function getTierByTokenId(uint256 tokenId) public pure returns (uint8) {
        return uint8(tokenId / ID_LENGTH);
    }

    function getUserWhitelist(address user) external view returns (uint8[] memory) {
        return whitelist[user];
    }
}