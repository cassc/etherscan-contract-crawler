// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


contract BoostNFT is Initializable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    using StringsUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256[5] public tokenPrices;
    address[] public whiteLists;
    bool public locked;

    struct Datas {
        uint8 level;
        uint8 rarity;
        uint256 metaId;
        bool disabled;
    }

    mapping (uint256 => Datas) data;
    modifier checkWhiteList(address userAddress) {
        require(!locked || (locked && exists(userAddress)), "this funcition is locked.");
        _;
    } 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("BoostNFT", "BTN");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        tokenPrices = [
          0.024 * 10 ** 18,
          0.024 * 10 ** 18,
          0.072 * 10 ** 18,
          0.14 * 10 ** 18,
          0.22 * 10 ** 18
        ];
        locked = false;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://logout-theta.vercel.app/api/utils/getNftData/";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 metaDataId) private checkWhiteList(msg.sender) returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());

        uint8 rarity;
        uint8 randomNum = random(tokenId);
        if (randomNum < 4) {
            rarity = 6;
        }
        if (randomNum < 8) {
            rarity = 5;
        } else if(randomNum < 16) {
            rarity = 4;
        } else if(randomNum < 32) {
            rarity = 3;
        } else if(randomNum < 64) {
            rarity = 2;
        } else {
            rarity = 1;
        }
        
        data[tokenId].rarity = rarity;
        data[tokenId].metaId = metaDataId;
        data[tokenId].level = 1;
        data[tokenId].disabled = false;
        return tokenId;
    }

    function safeMint(address to, uint256 metaDataId) public payable returns(uint256) {
        require(msg.value > tokenPrices[metaDataId - 1], "You must pay enough BNB");
        uint256 tokenId = mint(to, metaDataId);
        return tokenId;
    }

    function multiSafeMint(address to, uint256[] memory metaDataIds) public payable returns(uint256[] memory) {
        require(msg.value > getTotalPrice(metaDataIds), "You must pay enough BNB");
        uint256[] memory ids = new uint256[](uint256(metaDataIds.length));
        for (uint i = 0; i < metaDataIds.length; i++) {
            ids[i] = mint(to, metaDataIds[i]);
        }
        return ids;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

        // original functions

    function levelUp(uint256 tokenId, uint8 step) public onlyRole(MINTER_ROLE) {
        require(data[tokenId].rarity * data[tokenId].metaId > (data[tokenId].level + step), "exceed max level");
        data[tokenId].level += step;
    }

    function getData(uint256 tokenId) public view returns (Datas memory) {
        return data[tokenId];
    }

    function getMetadataId(uint256 tokenId) public view returns (uint256) {
        return data[tokenId].metaId;
    }

    function addWhiteList(address userAddress) public onlyRole(PAUSER_ROLE) {
        whiteLists.push(userAddress);
    }

    function toggleLocked() public onlyRole(PAUSER_ROLE) {
        locked = !locked;
    }

    // util func

    function random(uint256 nonce) private view returns(uint8) {
        // max 256
        return uint8(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce))) % 251);
    }

    function getTotalPrice(uint256[] memory arr) public view returns(uint256){
        uint256 sum = 0;
            
        for(uint i = 0; i < arr.length; i++)
            sum = sum + tokenPrices[arr[i] - 1];
        return sum;
    }

    function exists(address userAddress) public view returns (bool) {
        for (uint i = 0; i < whiteLists.length; i++) {
            if (whiteLists[i] == userAddress) {
                return true;
            }
        }
        return false;
    }

    function withdraw() external onlyRole(MINTER_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
}