// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "../lib/erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IMetaFlyers.sol";


contract MetaFlyers is IMetaFlyers, ERC721AQueryable, IERC2981, Ownable, Pausable {

    constructor() ERC721A("MetaFlyers", "MFLY") {
        _pause();
    }

    // EVENTS 
    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenBurned(address indexed owner, uint256 indexed tokenId);
    event TokenBonusAdded(address indexed owner, uint256 indexed tokenId, uint16 indexed traitId);

    // ERRORS
    error OnlyAdmin();
    error MaxSupplyReached();
    error MetaFlyerLocked();
    error MetaFlyerNotLocked();
    error TokenDoesNotExist();

    // PUBLIC VARS 
    bool public IS_REVEALED = false;
    uint256 public MAX_TOKENS = 7777;                       // max number of tokens that can be minted    
    uint16 public totalMinted;                              // number of tokens have been minted so far
    uint16 public totalLocked;                              // number of tokens have been locked so far    
    address public royaltyAddress;                          // address which receives the royalties

    // PRIVATE VARS
    string private _tokenRevealedBaseURI;                   // uri for revealing nfts   
    string private _tokenUnrevealedURI;                     // uri for unrevealed nfts
    string private _tokenLockedURI;                         // uri for locked nfts 
    uint256 private _royaltyPermille = 55;                  // royalty permille (to support 1 decimal place) 
    mapping(address => bool) private _admins;               // mapping to hold administrator contract       
    mapping(uint256 => Locked) private _lockedByTokenId;    // tokenId => Locked; map of all staked by tokenId
    mapping(address => uint256) private numUserLocked;      // user => Locked; map of all locked by user address

    // MODIFIERS 
    modifier onlyAdmin() {
        if(!_admins[msg.sender]) revert OnlyAdmin();
        _;       
    }

    // ADMIN ONLY FUNCTIONS 
    function mint(address recipient, uint16 qty) external onlyAdmin whenNotPaused {
        if(totalMinted + qty > MAX_TOKENS) revert MaxSupplyReached();
        
        for (uint i = 1; i <= qty; i++) {           
            emit TokenMinted(recipient, totalMinted + i);
        }

        totalMinted += qty;

        _safeMint(recipient, qty);
        
    }

    function burn(uint256 tokenId) external onlyAdmin whenNotPaused {
        emit TokenBurned(ownerOf(tokenId), tokenId);
        _burn(tokenId, false);        
    }

    function lock(uint256 tokenId, address user) external onlyAdmin {
        if(_isLocked(tokenId)) revert MetaFlyerLocked();

        //add lock
        _lockedByTokenId[tokenId] = IMetaFlyers.Locked({
            tokenId: uint64(tokenId),
            lockTimestamp: uint64(block.timestamp),
            claimedAmount: 0
        });

        numUserLocked[user]++;
        totalLocked++;
    }

    function unlock(uint256 tokenId, address user) external onlyAdmin {
        if(!_isLocked(tokenId)) revert MetaFlyerNotLocked();

        // remove lock
        delete _lockedByTokenId[tokenId];

        numUserLocked[user]--;
        totalLocked--;
    }
    
    function refreshLock(uint256 tokenId, uint256 amount) external onlyAdmin {
        if(!_isLocked(tokenId)) revert MetaFlyerNotLocked();

        // updates only the claimTimestamp and nothing else
        IMetaFlyers.Locked memory myLock = _getLock(tokenId);
        myLock.claimedAmount += uint128(amount);
        _lockedByTokenId[tokenId] = myLock;
    }

    function getLock(uint256 tokenId) external view returns (Locked memory) {
        return _getLock(tokenId);
    }

    function _getLock(uint256 tokenId) private view returns (Locked memory) {
        if(!_isLocked(tokenId)) revert MetaFlyerNotLocked();
        return _lockedByTokenId[tokenId];
    }

    function isLocked(uint256 tokenId) external view returns (bool) {
        return _isLocked(tokenId);
    }

    function _isLocked(uint256 tokenId) private view returns (bool) {
        if (_lockedByTokenId[tokenId].tokenId == tokenId) return true;
        return false;
    }

    function isAdmin(address addr) external view returns (bool) {
        return _admins[addr];
    }

    // PUBLIC FUNCTIONS
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddress, salePrice * _royaltyPermille/1000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165, IERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        if(!IS_REVEALED) return _tokenUnrevealedURI;
        if(_isLocked(tokenId)) return _tokenLockedURI;
        return string(abi.encodePacked(_tokenRevealedBaseURI, Strings.toString(tokenId)));
    }

    function metaFlyersURI(uint256 tokenId) public view returns (string memory) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        if(!IS_REVEALED) return _tokenUnrevealedURI;
        return string(abi.encodePacked(_tokenRevealedBaseURI, Strings.toString(tokenId)));
    }
    
    function getAllLockedTokens(address owner, bool locked) external view returns (uint256[] memory) {        
        uint256[] memory ownerTokenIds =  _tokensOfOwner(owner);
        uint256 amount;              
        uint256 count;

        if(locked) amount =  numUserLocked[owner]; 
        else amount = ownerTokenIds.length - numUserLocked[owner];
                 
        uint256[] memory filteredTokenIds = new uint256[](amount); 
        for(uint16 i = 0; i < ownerTokenIds.length && count < amount; i++) {
            uint256 tokenId = ownerTokenIds[i];
            
            if (_isLocked(uint128(tokenId)) == locked) {
                filteredTokenIds[count++] = tokenId;
            }
        }
        return filteredTokenIds;       
    }

    function tokensOfOwner(address owner) external view  returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    // OVERRIDES
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A)  {
        if(_isLocked(uint128(tokenId))) revert MetaFlyerLocked();
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override(ERC721A, IERC721A)  {
        if(_isLocked(uint128(tokenId))) revert MetaFlyerLocked();
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId) public payable override(ERC721A, IERC721A) {
        if(_isLocked(uint128(tokenId))) revert MetaFlyerLocked();
        super.approve(to, tokenId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // OWNER ONLY FUNCTIONS 
    function setRevealedBaseURI(string calldata uri) external onlyOwner {
        _tokenRevealedBaseURI = uri;
    }

    function setLockedURI(string calldata uri) external onlyOwner {
        _tokenLockedURI = uri;
    }

    function setUnrevealedURI(string calldata uri) external onlyOwner {
        _tokenUnrevealedURI = uri;
    }

    function setIsRevealed(bool _isRevealed) external onlyOwner {
        IS_REVEALED = _isRevealed;
    }

    function setPaused(bool _paused) external onlyOwner {
        require(royaltyAddress != address(0), "MetaFlyers: Royalty address must be set");
        if (_paused) _pause();
        else _unpause();
    }

    function setRoyaltyPermille(uint256 number) external onlyOwner {
        _royaltyPermille = number;
    }

    function setRoyaltyAddress(address addr) external onlyOwner {
        royaltyAddress = addr;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }
}