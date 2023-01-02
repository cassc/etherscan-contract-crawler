// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./NFTLibrary.sol";

contract OlyxNFT is Initializable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using Strings for uint256;

    bytes32 public constant TOKEN_FREEZER = keccak256("TOKEN_FREEZER");
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER");
    bytes32 public constant TOKEN_GAME_ROLE = keccak256("TOKEN_GAME_ROLE");

    uint256 public maxnftcount;

    string private _internalBaseURI;

    NFTLibrary.NFT[] private _nft;

    struct CollectionNFT {string name; string category; uint8 level;}
    mapping(uint8 => CollectionNFT) public scollection;

    event TokenMint(address indexed to, uint indexed tokenId, string name, string category, uint level);

    function initialize() public initializer {
        __ERC721_init("OlyxAI NFT", "OLYXAI");
        __ERC721Enumerable_init();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_MINTER_ROLE, msg.sender);
        _setupRole(TOKEN_GAME_ROLE, msg.sender);
        _internalBaseURI = "https://nft.olyx.ai/";

        maxnftcount = 1000;

    }

    //Modifier functions --------------------------------------------------------------------------------------------

    modifier onlyOwnerOf(address account, uint256 _nftId) {
        require(ownerOf(_nftId) == account, "Must be owner of NFT to Stake");
        _;
    }
    
    //External functions --------------------------------------------------------------------------------------------

    function setnftCount(uint256 count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxnftcount = count;
    }
 
    function addCollection(uint8[] memory id, string[] memory nftName, string[] memory nftCategory, uint8[] memory nftlevel) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(id.length == nftCategory.length && id.length == nftName.length, 'Input not true');
        for(uint8 i = 0; i < nftName.length ; i ++) {
            scollection[id[i]] = CollectionNFT(nftName[i], nftCategory[i], nftlevel[i]);
        }
    }
    function editCollection(uint8 _id, string memory nftName, string memory nftCategory, uint8 nftLevel) external onlyRole(DEFAULT_ADMIN_ROLE) {
        scollection[_id].name = nftName;
        scollection[_id].category = nftCategory;
        scollection[_id].level = nftLevel;
    }  
    function editNFT(uint256 tokenId, string memory nftName, string memory nftCategory, uint8 nftlevel) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _nft[tokenId].name = nftName;
        _nft[tokenId].category = nftCategory;
        _nft[tokenId].level = nftlevel;
    }
    function editLevelNFT(uint256 tokenId, uint8 nftlevel) public onlyRole(TOKEN_GAME_ROLE) {
        _nft[tokenId].level = nftlevel;
    }          
    function setBaseURI(string calldata newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _internalBaseURI = newBaseUri;
    }

    function getNFT(uint256 _nftId) external view returns (NFTLibrary.NFT memory) {
        return _getNft(_nftId);
    }

    function getInfoForStaking(uint tokenId)
        external
        view
        returns (
            address tokenOwner,
            string memory category,
            uint8 level,
            bool stakeFreeze
        )
    {
        tokenOwner = ownerOf(tokenId);
        category = _nft[tokenId].category;
        level = _nft[tokenId].level;
        stakeFreeze = _nft[tokenId].stakeFreeze;
    }

    function tokenFreeze(uint tokenId) external onlyRole(TOKEN_FREEZER) {
        // Clear all approvals when freeze token , use for staking part
        _approve(address(0), tokenId);

        _nft[tokenId].stakeFreeze = true;
    }

    function tokenUnfreeze(uint tokenId) external onlyRole(TOKEN_FREEZER) {
        _nft[tokenId].stakeFreeze = false;
    }

    //Public functions --------------------------------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function approve(address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) {
        if (_nft[tokenId].stakeFreeze == true) {
            revert("ERC721: Token frozen");
        }
        super.approve(to, tokenId);
    }

    function mint(address to, uint8 nft) public onlyRole(TOKEN_MINTER_ROLE) nonReentrant returns(uint256) {
        require(to != address(0), "Address can not be zero");
        require(_nft.length <= maxnftcount, "Max Limit");
        uint256 tokenId = _nft.length;
        _nft.push(NFTLibrary.NFT(scollection[nft].name, scollection[nft].category, scollection[nft].level, tokenId, false));
        _safeMint(to, tokenId);
        return tokenId;
    }

    //Internal functions --------------------------------------------------------------------------------------------

    function _getNft(uint256 _nftId) internal view returns (NFTLibrary.NFT memory) {
        require(_nftId < _nft.length, "NFT does not exist");
        NFTLibrary.NFT memory nftdetail = _nft[_nftId];
        return nftdetail;
    }

    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }

    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
        emit TokenMint(to, tokenId, _nft[tokenId].name, _nft[tokenId].category, _nft[tokenId].level);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        if (_nft[tokenId].stakeFreeze == true) {
            revert("ERC721: Token frozen");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

}