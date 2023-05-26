// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./Decompressor.sol";
import "./Leaderboard.sol";


interface GM420 {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}


contract BrickBreakers is ERC721Enumerable, Ownable, ReentrancyGuard, Leaderboard {
    using Strings for uint256;

    uint256 public constant PRICE = 0.069 ether;
    string[] levelNames = ["reverseX", "rows", "columns", "pyramid", "hourglass", "rhombus", "heart", "flying saucer", "X", "spiral", "diamond", "face", "skull", "butterfly", "star"];
    string[] paddlePaletteNames = ["classic", "retro vibes", "hades"];
    string[] brickPaletteNames = ["mango", "watermelon", "classic", "purple dream", "cotton candy", "retro vibes"];
    string[] bgPaletteNames = ["SF", "NYC", "cool", "environmental", "pride", "block3d"];

    uint256 constant TOTAL_SUPPLY = 2500;
    uint256 constant GM420_AMOUNT = 420;
    uint256 constant MAX_MINT_PER_TX = 5;
    // Modulus is 2^28. minus 1 to do bitwise operations and not division. we'll end up throwing about 40% of the values
    // away, but it's still cheaper
    uint256 constant M = 0x8000000 - 1;
    uint256 constant A = 0x7331331;
    uint256 constant C = 1036235;
    // has to be accurate otherwise we'll get uneven distributions
    uint256 constant TOTAL_OPTIONS = 113246208;
    uint256 constant LEVEL_COUNT = 15;

    bytes[] _content;
    bytes[] _compressionDict;
    bytes _before;
    bytes _after;
    bytes _gmoneyLogo;
    bytes _ethersCdnPath;
    uint256 _publiclyMinted = 0;
    uint256 _reservedMinted = 0;
    uint256 _totalReserved = 30;
    bool _mintLive = false;
    bool _preMintLive = false;
    mapping(address => bool) private _preMintAllowList;
    mapping(uint256 => uint256) private _tokenSeeds;

    address gm420;
    address splitterAddress;

    uint256 lcgState = 0x13618923;

    // ---------- events ----------
    event GM420Redeemed(address account, uint256 gm420Token);
    event GiveawayRedeemed(address account, uint256 tokenId);

    // ---------- content ----------
    function setContent(bytes[] memory content, bytes[] memory compressionDict) external onlyOwner {
        _content = content;
        _compressionDict = compressionDict;
    }

    function setBeforeAfter(bytes calldata beforeB, bytes calldata afterB, bytes calldata gmoneyLogo, bytes calldata ethersCdnPath) external onlyOwner {
        // hack used to bypass opensea's security restrictions
        // before: <html><head><meta http-equiv="refresh" content="0; url=https://ipfs.io/ipfs/QmPmSjSa3vvBaMd64Hq7smtStGFwFvq32HRo3PJdX54RZF#
        // 0x3c68746d6c3e3c686561643e3c6d65746120687474702d65717569763d22726566726573682220636f6e74656e743d22303b2075726c3d68747470733a2f2f697066732e696f2f697066732f516d506d536a536133767642614d643634487137736d745374474677467671333248526f33504a64583534525a4623
        _before = beforeB;
        // after: "></head></html>
        // 0x223e3c2f686561643e3c2f68746d6c3e
        _after = afterB;
        // 0x89504e470d0a1a0a0000000d4948445200000018000000180806000000e0773df80000008f4944415478da63601805a30008fee3c1941b7eca4f1027a6d412bc86536ac9ffc9e69c4463722c016b04b990189a6c5f98aa08fc6fcd0fc38b298907b8055961f6608c6c304c8c22d7c32c00f157f66463b81c2446150b681144ffe91607c89680c49069aa5980cb272071aafa802641841c2ce898aa16d0349271594271698a1cc9b4a80fb05940dd9a8c1a16000011744c9b1da9c7350000000049454e44ae426082
        _gmoneyLogo = gmoneyLogo;
        // 0x68747470733a2f2f63646e2e6574686572732e696f2f6c69622f6574686572732d352e322e756d642e6d696e2e6a73
        _ethersCdnPath = ethersCdnPath;
    }

    // ---------- Settings ----------
    function setMintStatus(bool status) external onlyOwner {
        _mintLive = status;
    }

    function isMintLive() external view returns (bool) {
        return _mintLive;
    }

    function setPreMintStatus(bool status) external onlyOwner {
        _preMintLive = status;
    }

    function setGM420Address(address _gm420) external onlyOwner {
        gm420 = _gm420;
    }

    function isPreMintLive() external view returns (bool) {
        return _preMintLive;
    }

    function setPreMintAllowList(address[] calldata allowList) external onlyOwner {
        for (uint256 i = 0; i < allowList.length; i++) {
           _preMintAllowList[allowList[i]] = true;
        }
    }

    function setReserved(uint256 reserved) external onlyOwner {
        require(reserved >= _reservedMinted, "Already minted more than that!");
        require(reserved + _publiclyMinted <= TOTAL_SUPPLY - GM420_AMOUNT, "Not enough pieces left #2!");
        _totalReserved = reserved;
    }

    // ---------- All kinds of minting ----------
    function giveAway(address to) external nonReentrant onlyOwner {
        require(totalSupply() + 1 <= TOTAL_SUPPLY, "Exceeds maximum supply");
        require(_reservedMinted < _totalReserved, "Exceeds maximum supply");
        uint256 tokenId = TOTAL_SUPPLY - _totalReserved + _reservedMinted;
        _reservedMinted++;
        _mintInternal(to, tokenId);
        emit GiveawayRedeemed(to, tokenId);
    }

    function claim(uint256 gm420TokenId) external nonReentrant {
        require(!_exists(gm420TokenId), "BrickBreakers: already redeemed!");
        require(GM420(gm420).ownerOf(gm420TokenId) == msg.sender);
        _mintInternal(msg.sender, gm420TokenId);
        emit GM420Redeemed(msg.sender, gm420TokenId);
    }

    function claimAll() external nonReentrant {
        GM420 contractInterface = GM420(gm420);
        uint256 tokenCount = contractInterface.balanceOf(msg.sender);
        for (uint256 i; i < tokenCount; i++) {
            uint256 gm420TokenId = contractInterface.tokenOfOwnerByIndex(msg.sender, i);

            if (!_exists(gm420TokenId)) {
                _mintInternal(msg.sender, gm420TokenId);
                emit GM420Redeemed(msg.sender, gm420TokenId);
            }
        }
    }

    function isOnAllowList(address account) external view returns (bool) {
        return _preMintAllowList[account] == true;
    }

    function preMint() external payable nonReentrant {
        require(_preMintLive, "Premint isn't active atm");
        require(msg.value >= PRICE, "Ether sent is less than PRICE");
        require(totalSupply() + 1 <= TOTAL_SUPPLY, "Exceeds maximum supply");
        require(_publiclyMinted + _totalReserved + 1 <= TOTAL_SUPPLY - GM420_AMOUNT, "Exceeds maximum supply");
        require(_preMintAllowList[msg.sender] == true, "Sender not on allow list");

        uint256 tokenId = _publiclyMinted + GM420_AMOUNT;
        _preMintAllowList[msg.sender] = false;
        _publiclyMinted += 1;

        _mintInternal(msg.sender, tokenId);
    }

    function mint(uint256 num) external payable nonReentrant {
        require(_mintLive, "Mint isn't active atm");
        require(num <= 5, "Maximum of 5 pieces per tx");
        require(msg.value >= PRICE * num, "Ether sent is less than PRICE*num");
        require(totalSupply() + num <= TOTAL_SUPPLY, "Exceeds maximum supply");
        require(_publiclyMinted + num + _totalReserved <= TOTAL_SUPPLY - GM420_AMOUNT, "Exceeds maximum supply");

        uint256 firstTokenId = _publiclyMinted + GM420_AMOUNT;
        // I know we set to nonReentrant, but still good practice to increase by the total amount ahead of time?
        _publiclyMinted += num;
        for (uint256 i; i < num; i++) {
            _mintInternal(msg.sender, firstTokenId + i);
        }
    }

    function _mintInternal(address to, uint256 tokenId) internal {
        uint256 tokenSeed = _getTokenSeed();
        _tokenSeeds[tokenId] = tokenSeed;
        _safeMint(to, tokenId);
    }

    function publiclyAvailableTokens() external view returns (uint256) {
        return TOTAL_SUPPLY - GM420_AMOUNT - _publiclyMinted - _totalReserved;
    }

    // ---------- Leaderboard ----------
    function submitScore(string calldata name, uint32 score, uint32 tokenId) public {
        require(_exists(uint256(tokenId)), "Non-existent token");
        require(ownerOf(uint256(tokenId)) == msg.sender, "Only the owner can set a high score");
        addEntry(name, score, tokenId);
    }

    // ---------- GAME GENERATION ----------
    function cleanGameURI(uint256 tokenId) public view returns (bytes memory, string memory, string memory) {
        require(_tokenSeeds[tokenId] != 0, "Invalid token ID");
        bytes memory attributes = _buildAttributes(_tokenSeeds[tokenId]);
        string memory output = Base64.encode(abi.encodePacked(
                Decompressor.decompress(_content[3], _compressionDict),
                _ethersCdnPath,
                Decompressor.decompress(_content[4], _compressionDict),
                tokenId.toString(),
                Decompressor.decompress(_content[5], _compressionDict),
                attributes,
                Decompressor.decompress(_content[6], _compressionDict),
                Base64.encode(_gmoneyLogo),
                Decompressor.decompress(_content[7], _compressionDict)
            ));

        return (attributes, output, _buildStaticImage(tokenId));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        (bytes memory attributes, string memory output, string memory staticImage) = cleanGameURI(tokenId);
//        return string(attributes);
        output = Base64.encode(abi.encodePacked(
            _before,
            output,
            _after));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "BrickBreakers #', tokenId.toString(),
        // opensea don't support html as data URIs atm. when they do, change this back to data: URI
        //            '", "description": "Top secret atm.", "image": "data:text/html;base64,',
            '","description":"The classical game, by GM420 & Gmoney.","image":"data:image/svg;base64,',
            staticImage,
            '","animation_url":"data:text/html;base64,', output,
            '","attributes": [', attributes,
            ']}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function _buildStaticImage(uint256 tokenId) private view returns (string memory) {
        return Base64.encode(abi.encodePacked(
            Decompressor.decompress(_content[0], _compressionDict),
            tokenId.toString(),
            Decompressor.decompress(_content[1], _compressionDict),
            Base64.encode(_gmoneyLogo),
            Decompressor.decompress(_content[2], _compressionDict)
        ));
    }

    function _buildAttributes(uint256 tokenSeed) private view returns (bytes memory) {
        uint powerUps = 2;
        bytes memory result = abi.encodePacked(_getSingleAttribute("bigger paddle", "true"), ",", _getSingleAttribute("score multiplier", "true"));
        if (tokenSeed & 1 != 0) {
            result = abi.encodePacked(result, ",", _getSingleAttribute("fire ball", "true"));
            powerUps++;
        }
        tokenSeed >>= 1;
        if (tokenSeed & 1 != 0) {
            result = abi.encodePacked(result, ",", _getSingleAttribute("iron ball", "true"));
            powerUps++;
        }
        tokenSeed >>= 1;
        if (tokenSeed & 1 != 0) {
            result = abi.encodePacked(result, ",", _getSingleAttribute("sticky paddle", "true"));
            powerUps++;
        }
        tokenSeed >>= 1;
        if (tokenSeed & 1 != 0) {
            result = abi.encodePacked(result, ",", _getSingleAttribute("multiple balls", "true"));
            powerUps++;
        }
        tokenSeed >>= 1;
        if (tokenSeed & 1 != 0) {
            result = abi.encodePacked(result, ",", _getSingleAttribute("extra lives", "true"));
            powerUps++;
        }
        tokenSeed >>= 1;
        result = abi.encodePacked(result, ",", _getSingleAttribute("# of powerups", powerUps.toString()));
        uint levels = 0;
        for (uint i = 0; i < LEVEL_COUNT; i++) {
            if (tokenSeed & 1 != 0) {
                result = abi.encodePacked(result, ",", _getSingleAttribute(string(abi.encodePacked("level ", levelNames[i])), "true"));
                levels++;
            }
            tokenSeed >>= 1;
        }
        result = abi.encodePacked(result, ",", _getSingleAttribute("# of levels", levels.toString()));
        result = abi.encodePacked(result, ",", _getSingleAttribute("paddle palette", paddlePaletteNames[tokenSeed % 3]));
        tokenSeed /= 3;
        result = abi.encodePacked(result, ",", _getSingleAttribute("brick palette", brickPaletteNames[tokenSeed % 6]));
        tokenSeed /= 6;
        result = abi.encodePacked(result, ",", _getSingleAttribute("bg", bgPaletteNames[tokenSeed % 6]));
//        tokenSeed /= 6;

        return result;
    }

    function _getSingleAttribute(string memory name, string memory value) private pure returns (bytes memory) {
        return abi.encodePacked('{"trait_type":"', name, '","value":"', value, '"}');
    }

    // ---------- Minting and pseudo-randomness ----------
    function _getTokenSeed() private returns (uint256) {
        uint256 tokenSeed;

        do {
            tokenSeed = _nextLCG();
        } while (!_decideOnRarity(tokenSeed));
        return tokenSeed;
    }

    function _decideOnRarity(uint256 tokenSeed) private pure returns (bool) {
        // fireball: 6.25% ( / 8 )
        if ((tokenSeed & 1 != 0) && (0 != uint256(keccak256(abi.encodePacked("fire ball", tokenSeed))) & 7)) {
            return false;
        }
        tokenSeed >>= 1;
        // fireball: 12.5% ( / 4 )
        if ((tokenSeed & 1 != 0) && (0 != uint256(keccak256(abi.encodePacked("iron ball", tokenSeed))) & 3)) {
            return false;
        }
        tokenSeed >>= 2;
        // multiple balls: 25% ( / 2 )
        if ((tokenSeed & 1 != 0) && (0 != uint256(keccak256(abi.encodePacked("multiple balls", tokenSeed))) & 1)) {
            return false;
        }
        tokenSeed >>= 1;
        // extra lives: 25% ( / 2 )
        if ((tokenSeed & 1 != 0) && (0 != uint256(keccak256(abi.encodePacked("extra lives", tokenSeed))) & 1)) {
            return false;
        }
        tokenSeed >>= 1;

        // at least one level
        if (tokenSeed & ((1 << LEVEL_COUNT) - 1) == 0) {
            return false;
        }
        tokenSeed >>= LEVEL_COUNT;

        tokenSeed /= 18;
        // puzzle probability: 4.1% ( / 4 )
        if ((tokenSeed % 6 == 5) && (0 != uint256(keccak256(abi.encodePacked("bg", tokenSeed))) & 3)) {
            return false;
        }

        return true;
    }

    function _nextLCG() private returns (uint256) {
        do {
            lcgState = (A * lcgState + C) & M;
        } while (lcgState >= TOTAL_OPTIONS);
        return lcgState;
    }

    // ---------- $$$$$$$$$$$ ----------
    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "No balance");
        (bool sent,) = payable(splitterAddress).call{value: _balance}("");
        require(sent, "FAILED withdraw");
    }

    // ---------- constructor ----------
    constructor(address _splitterAddress) ERC721("gmoney_brick_breaker", "BRCK") Ownable() ReentrancyGuard() Leaderboard() {
        splitterAddress = _splitterAddress;
    }
}