// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./standards/TypeBlocks721.sol";
import "./libraries/TypeBlocksMetadata.sol";
import "./libraries/Utils.sol";
import "./interfaces/IArtWork.sol";

contract TypeBlocksV3 is TypeBlocks721, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _seed;

    string public constant DEFAULT_COLOR = "White";

    bool public isMintLive;
    bool public isBlendable;
    bool public isSuperBurnLive;
    uint256 public mintPrice;
    string[] public baseColor;
    string[] public extendedColor;

    mapping(uint256 => bytes1[]) public tokenLetters;
    mapping(uint256 => string) public tokenColor;
    mapping(uint256 => uint256) public tokenShuffle;
    mapping(address => uint256) public freeMints;

    //V2
    uint256 public pubMintPrice;
    bytes32 private merkleTreeRoot;
    uint256 public maxWlTx;
    mapping(address => uint256) public mintBal;

    //v3
    IArtWork public artwork;
    bytes public constant ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    event MetadataUpdate(uint256 tokenId);

    function initialize() initializer public {
        TypeBlocks721.__ERC721_init('Type Blocks', 'TYPEBLOCKS');

        isMintLive = true;
        isBlendable = false;
        isSuperBurnLive = false;
        mintPrice = 0.0069 ether;
    }

    function devMint(address to, uint256 quantity) external onlyOwner {
        _mint(to, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        if (tokenId > _totalMinted()) revert URIQueryForNonexistentToken();

        bytes1[] memory letters = tokenLetters[tokenId];
        if(letters.length == 0) {
            letters = _initLetters(tokenId);
        }

        string memory color = tokenColor[tokenId];
        if(!Utils.isStringExists(color)) {
            color = DEFAULT_COLOR;
        }

        return TypeBlocksMetadata.tokenURI(tokenId, letters, color, tokenShuffle[tokenId], artwork);
    }

    function blend(uint256[] calldata tokenIds, bool keepColor) external nonReentrant {
        require(isBlendable, "E01");
        require(tokenIds.length > 1, "E02");

        uint256 characters;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "E03");
            bytes1[] storage blendLetters = _getTokenLetters(tokenIds[i]);
            characters = characters + blendLetters.length;
        }

        require(characters < 5, "E04");

        bytes1[] storage _tokenLetters = _getTokenLetters(tokenIds[0]);

        for (uint256 i = 1; i < tokenIds.length; i++) {
            bytes1[] storage blendLetters = _getTokenLetters(tokenIds[i]);
            
            for (uint256 j = 0; j < blendLetters.length; j++) {
                _tokenLetters.push(blendLetters[j]);
            }

            _burn(tokenIds[i]);
        }

        if(!keepColor) {
            tokenColor[tokenIds[0]] = _getBaseColor();
        }

        _shuffleTokenLetters(tokenIds[0]);
        emit MetadataUpdate(tokenIds[0]);
    }
    
    function superBurn(uint256 keeper, uint256 burner, uint256 action) external nonReentrant {
        require(isSuperBurnLive, "E05");
        require(ownerOf(keeper) == msg.sender, "E03");
        require(ownerOf(burner) == msg.sender, "E03");
        require(action >= 0 && action < 3, "E06");

        bytes1[] storage _tokenLetters = _getTokenLetters(keeper);
        bytes1[] memory burnerLetters = _getTokenLetters(burner);

        require((_tokenLetters.length == burnerLetters.length) && (_tokenLetters.length <= 5), "E07");

        // 0 = Color, 1 = Shuffle, 2 = craftLetter
        if(0 == action) {
            tokenColor[keeper] = _getColor();
        } else if(1 == action) {
            _shuffleTokenLetters(keeper);
        } else {
            require(_tokenLetters.length == 4, "E08");
            tokenColor[keeper] = DEFAULT_COLOR;
            _craftLetter(_tokenLetters, burnerLetters);
            _shuffleTokenLetters(keeper);
            _mint(msg.sender, 1);
        }

        _burn(burner);

        emit MetadataUpdate(keeper);
    }

    function _getBaseColor() internal returns (string memory) {
        require(baseColor.length > 0, "E09");
        _seed.increment();
        uint256 n = Utils.getRandom(block.timestamp + _seed.current(), baseColor.length);
        return baseColor[n];
    }

    function _getExtendedColor() internal returns (string memory) {
        require(extendedColor.length > 0, "E09");
        _seed.increment();
        uint256 n = Utils.getRandom(block.timestamp + _seed.current(), extendedColor.length);
        return extendedColor[n];
    }
    
    function _getColor() internal returns (string memory) {
        _seed.increment();
        uint256 n = Utils.getRandom(block.timestamp + _seed.current(), 100);

        if(n < 70) {
            return _getBaseColor();
        } else {
            return _getExtendedColor();
        }
    }

    function _craftLetter(bytes1[] storage letters, bytes1[] memory burnerLetters) internal {
        _seed.increment();
        uint256 n = Utils.getRandom(block.timestamp + _seed.current(), burnerLetters.length);
        bytes1 randomLetter = burnerLetters[n];
        letters.push(randomLetter);
    }

    function _getTokenLetters(uint256 tokenId) internal returns(bytes1[] storage) {
        bytes1[] storage _tokenLetters = tokenLetters[tokenId];
        if(_tokenLetters.length == 0) {
            bytes1[] memory iniLetters = _initLetters(tokenId);
            for (uint256 i; i < iniLetters.length; i++) {
                _tokenLetters.push(iniLetters[i]);
            }
        }
        return _tokenLetters;
    }

    function _shuffleTokenLetters(uint256 tokenId) internal {
        bytes1[] storage _tokenLetters = _getTokenLetters(tokenId);
        for (uint256 i = 0; i < _tokenLetters.length; i++) {
            _seed.increment();
            uint256 n = Utils.getRandom(block.timestamp + _seed.current(), _tokenLetters.length - i) + i;
            bytes1 temp = _tokenLetters[n];
            _tokenLetters[n] = _tokenLetters[i];
            _tokenLetters[i] = temp;
        }
        unchecked { tokenShuffle[tokenId] += 1; }
    }

    function _initLetters(uint256 tokenId) internal view returns (bytes1[] memory letters) {
        if (tokenId <= 2000) {
            letters = getLetter(tokenId, 2, 3);
        } else if (tokenId <= 6000) {
            letters = getLetter(tokenId, 1, 3);
        } else if (tokenId <= 10000) {
            letters = getLetter(tokenId, 1, 2);
        } else {
            letters = getLetter(tokenId, 1, 1);
        }
        return letters;
    }
    
    function getLetter(uint256 tokenId, uint256 min, uint256 max) internal view returns (bytes1[] memory) {
        uint256 range = max - min + 1;
        uint256 length = 1;
        if(range > 1) {
            length = Utils.getRandom(tokenId, range) + min;
        }

        bytes1[] memory letters = new bytes1[](length);
        
        for (uint256 i; i < length; i++) {
            uint256 alphabetIndex = Utils.getRandom(i + length + tokenId, 26);

            letters[i] = ALPHABET[alphabetIndex];
        }

        return letters;
    }

    function setBaseColor(string[] memory color) external onlyOwner {
        baseColor = color;
    }

    function setExtendedColor(string[] memory color) external onlyOwner {
        extendedColor = color;
    }

    function setArtWork(address addr) external onlyOwner {
        artwork = IArtWork(addr);
    }

    function toggleBlendable() external onlyOwner {
        isBlendable = !isBlendable;
    }

    function toggleSuperBurnLive() external onlyOwner {
        isSuperBurnLive = !isSuperBurnLive;
    }
}