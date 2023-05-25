// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./OnChainKevinLib.sol";
import "./interfaces/IOnChainKevinRenderer.sol";


//  ______     __   __     ______     __  __     ______     __     __   __     __  __     ______     __   __   __     __   __    
// /\  __ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\  __ \   /\ \   /\ "-.\ \   /\ \/ /    /\  ___\   /\ \ / /  /\ \   /\ "-.\ \   
// \ \ \/\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \  __ \  \ \ \  \ \ \-.  \  \ \  _"-.  \ \  __\   \ \ \'/   \ \ \  \ \ \-.  \  
//  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\  \ \_\ \_\  \ \_____\  \ \__|    \ \_\  \ \_\\"\_\ 
//   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/\/_/   \/_/   \/_/ \/_/   \/_/\/_/   \/_____/   \/_/      \/_/   \/_/ \/_/ 


contract OnChainKevin is ERC721Enumerable, ReentrancyGuard {
    using OnChainKevinLib for uint8;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    mapping(uint256 => string) internal _tokenIdToHash;
    mapping(string => bool) public hashToMinted;
    mapping(address => uint256) public addressMintedCounts;

    address public renderingContractAddress;

    //uint256s
    uint256 SEED_NONCE = 0;

    uint256 private constant MAX_KEVINS = 2000;
    uint256 private constant V1_FOUNDER_KEVINS = 50;
    uint256 private constant MAX_PUBLIC_MINT = MAX_KEVINS - V1_FOUNDER_KEVINS;
    uint256 private constant NUM_LAYERS = 9;
    string[] private TRAIT_INDEX_NAME = [
        "Lasers",
        "Head Accessory",
        "Mouth",
        "Face Accessory",
        "Eyes",
        "Nose",
        "Shirt",
        "Skin",
        "Background"
    ];

    string public baseURI = "https://onchainkevin.com/api/v4/";
    uint256 internal v1PublicKevins = 521;
    uint256 internal maxPerAddress = 5;
    uint16[][NUM_LAYERS] private TIERS;
    bool public isMintingPaused = true;
    address _owner;

    constructor() ERC721("OnChainKevin", "DERP") {
        _owner = msg.sender;

        // *SHOUTOUT* to Anonymice and Chain Runners for the inspiration.

        //Lasers
        TIERS[0] = [2, 5, 10, 30, 40, 50, 1863];
        //Head Accessory
        TIERS[1] = [10, 15, 20, 35, 50, 60, 65, 70, 75, 80, 90, 95, 150, 170, 180, 190, 200, 215, 230];
        //Mouth
        TIERS[2] = [40, 80, 100, 120, 160, 200, 250, 300, 350, 400];
        //Face Accessory
        TIERS[3] = [10, 15, 20, 35, 50, 60, 70, 75, 80, 110, 115, 160, 220, 230, 240, 250, 260];
        //Eyes
        TIERS[4] = [200, 250, 280, 290, 300, 330, 350];
        //Nose
        TIERS[5] = [200, 300, 400, 500, 600];
        //Shirt
        TIERS[6] = [40, 45, 55, 65, 80, 85, 95, 100, 110, 115, 120, 150, 220, 230, 240, 250];
        //Skin
        TIERS[7] = [50, 750, 1200];
        //Background
        TIERS[8] = [10, 80, 100, 180, 200, 210, 220, 230, 240, 260, 270];
    }

    modifier whenPublicMintActive() {
        require(isPublicMintActive(), "Public sale not open");
        _;
    }

/*
  __  __ _     _   _             ___             _   _             
 |  \/  (_)_ _| |_(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___
 | |\/| | | ' \  _| | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
 |_|  |_|_|_||_\__|_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/
                         |___/                                     
*/

    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i.toString();
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 19, "Too many layers");

        // This will generate a 18 character string.
        string memory currentHash = "";

        for (uint8 i = 0; i < NUM_LAYERS; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % MAX_KEVINS
            );

            string memory rarity = rarityGen(_randinput, i);

            if (OnChainKevinLib.parseInt(rarity) < 10) {
                currentHash = string(
                    abi.encodePacked(currentHash, "0", rarity)
                );
            } else {
                currentHash = string(
                    abi.encodePacked(currentHash, rarity)
                );
            }

        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    function mint(uint256 tokenId) internal {
        _tokenIdToHash[tokenId] = hash(tokenId, msg.sender, 0);
        hashToMinted[_tokenIdToHash[tokenId]] = true;

        _safeMint(msg.sender, tokenId);
    }

    function mintKevin(uint256 _count) external whenPublicMintActive returns (uint256, uint256) {
        require(_count > 0, "Invalid Kevin count");
        require(tokenIds.current() + v1PublicKevins + _count <= MAX_PUBLIC_MINT, "All OnChainKevins are gone");

        uint256 userMintedAmount = addressMintedCounts[msg.sender] + _count;
        require(userMintedAmount <= maxPerAddress, "Exceeded max mints allowed.");

        uint256 firstMintedId = tokenIds.current() + v1PublicKevins + 1;

        for (uint256 i = 0; i < _count; i++) {
            tokenIds.increment();
            mint(tokenIds.current() + v1PublicKevins);
        }

        addressMintedCounts[msg.sender] = userMintedAmount;
        return (firstMintedId, _count);
    }

/*
 ____     ___   ____  ___        _____  __ __  ____     __ ______  ____  ___   ____   _____
|    \   /  _] /    ||   \      |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|  D  ) /  [_ |  o  ||    \     |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|    / |    _]|     ||  D  |    |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|    \ |   [_ |  _  ||     |    |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|  .  \|     ||  |  ||     |    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
|__|\_||_____||__|__||_____|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|

*/

    function isPublicMintActive() public view returns (bool) {
        return tokenIds.current() + v1PublicKevins < MAX_PUBLIC_MINT && isMintingPaused == false;
    }

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        if (renderingContractAddress == address(0)) {
            return '';
        }

        IOnChainKevinRenderer renderer = IOnChainKevinRenderer(renderingContractAddress);
        return renderer.hashToSVG(_hash);
    }

    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        if (renderingContractAddress == address(0)) {
            return '';
        }

        IOnChainKevinRenderer renderer = IOnChainKevinRenderer(renderingContractAddress);
        return renderer.hashToMetadata(_hash);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Invalid token");
        if (_tokenId > v1PublicKevins && _tokenId <= MAX_PUBLIC_MINT) {
            return string(abi.encodePacked(baseURI, OnChainKevinLib.toString(_tokenId), "?dna=", _tokenIdToHash[_tokenId]));
        }

        if (renderingContractAddress == address(0)) {
            return '';
        }

        IOnChainKevinRenderer renderer = IOnChainKevinRenderer(renderingContractAddress);
        return string(abi.encodePacked(baseURI, OnChainKevinLib.toString(_tokenId), "?dna=", renderer._tokenIdToHash(_tokenId)));
    }

    function tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        if (_tokenId > v1PublicKevins && _tokenId <= MAX_PUBLIC_MINT) {
            return _tokenIdToHash[_tokenId];
        }

        if (renderingContractAddress == address(0)) {
            return '';
        }

        IOnChainKevinRenderer renderer = IOnChainKevinRenderer(renderingContractAddress);
        return renderer._tokenIdToHash(_tokenId);
    }

    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /*

  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|

    */

    function setRenderingContractAddress(address _renderingContractAddress) external onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    function changeMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function changeBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function changeV1PublicKevins(uint256 _v1PublicKevins) external onlyOwner {
        v1PublicKevins = _v1PublicKevins;
    }

    function airdropKevins(address[] memory _to, uint256[] memory _tokenIds, string[] memory _hashes)
        external
        onlyOwner
    returns (uint256) {
        uint256 length = _to.length;
        for (uint256 i = 0; i < length; i++) {
            hashToMinted[_hashes[i]] = true;
            _mint(_to[i], _tokenIds[i]);
        }

        return length;
    }

    function toggleMinting() external onlyOwner {
        isMintingPaused = !isMintingPaused;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        _owner = _newOwner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }
}