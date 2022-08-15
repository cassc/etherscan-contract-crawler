// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EMRecruit is ERC721A, ERC721AQueryable, Ownable, Pausable, ReentrancyGuard {

    /* ========== LIBRARIES ========== */

    using ECDSA for bytes32;

    /* ========== STATE VARIABLES ========== */

    // the base baseURI for nft
    string public baseURI;
    // the no revealUri
    string public notRevealedURI;
    // recruit price
    uint256 public price = 0.0069 ether;
    // level up price
    uint256 public levelUpprice = 0.0069 ether;
    // vip mintin period
    uint256 public vipMintingPeriod = 86400 ; // 24h
    // vip sale start time
    uint256 public vipSaleStartTime = 1658508635;
    // total supply
    uint256 TOTAL_SUPPLY = 3000;
    // lieutenant level
    uint8 public lieutenantLevel = 4;
    //max level
    uint8 public maxLevel = 4;
    // systemSigner
    address private systemSigner;
    // reveal state
    bool public revealed = false;
    // for nft custom uri setting
    mapping(uint256 => string) private _tokenURIs;
    //list of frer toekns
    mapping(uint256 => bool) public isFreeToken;
    //mapping from token to level
    mapping(uint256 => uint256) public recuitToLevel;
    //mapping from user to free mint
    mapping(address => bool) public hasFreeMinted;
    //operators
    mapping(address => bool) public operators;


    /* ========== MODIFICATORS ========== */

    modifier onlyValidSignature(bytes32 _msgHash, bytes memory _signature, address _signer) {
        address signer = _msgHash.toEthSignedMessageHash().recover(_signature);
        require(signer == _signer, "INVALID_SIGNATURE");
        _;
    }

    modifier hashMessage(bytes32 _msgHash, uint256 at) {
        require(keccak256(abi.encodePacked(msg.sender, at)) == _msgHash, "INVALID_MESSAGE");
        _;
    }

    modifier canFreeMint(bytes32 _msgHash, uint256 at, uint8 level) {
        require(keccak256(abi.encodePacked(msg.sender, at, level)) == _msgHash, "INVALID_MESSAGE");
        _;
    }

    modifier canLevelUp(bytes32 _msgHash, uint256 at, uint8 level) {
        require(keccak256(abi.encodePacked(msg.sender, at, level)) == _msgHash, "INVALID_MESSAGE");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor(string memory name_, string memory symbol_, string memory baseUri_, string memory notRevealedUri_, address siger_)
     ERC721A(name_, symbol_) {
        baseURI = baseUri_;
        notRevealedURI = notRevealedUri_;
        systemSigner = siger_;

        _safeMint(owner(), 1150);
    }

    /* ========== VIEWS ========== */

    function numberMinted(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }
    
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _totalSupply() internal view returns (uint256) {
        unchecked {
            return _totalMinted() - _totalBurned();
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        if(_exists(tokenId))
        {
            TokenOwnership memory ownership;
            ownership = _ownershipOf(tokenId);
            require(!ownership.burned, 'THIS TOKEN WAS BURNED');
            require((recuitToLevel[tokenId] == lieutenantLevel) || (tokenId > 0 && tokenId < 1151), 'NEED TO LEVELUP TO LIEUTENANT');
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
         if (revealed == false) {
            return notRevealedURI;
        }
        string memory uri = _tokenURIs[_tokenId];
        if(bytes(uri).length > 0 )
            return string(abi.encodePacked(uri));

        string memory base = _baseURI();

        if(_tokenId > 0 && _tokenId < 1151){
            return bytes(base).length != 0 ? string(abi.encodePacked(base, "level", _toString(lieutenantLevel), "/", _toString(_tokenId), ".json")) : '';
        }
        return bytes(base).length != 0 ? string(abi.encodePacked(base, "level", _toString(recuitToLevel[_tokenId]), "/", _toString(_tokenId), ".json")) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner returns (bool) {
        baseURI = _uri;
        return true;
    }

    function safeMint(bytes32 _msgHash, bytes memory _signature, uint256 at)
    external
    whenNotPaused
    nonReentrant
    onlyValidSignature(_msgHash, _signature, systemSigner)
    canFreeMint(_msgHash, at, 1)
    {
        require(msg.sender != address(0), "0 IS NOT A CORRECT ADDRESS");
        require(!hasFreeMinted[msg.sender], "QUANTITY_EXCEEDED");
        require(_totalSupply() <= TOTAL_SUPPLY, "SOLD_OUT");
        uint256 id = _nextTokenId();
        isFreeToken[id] = true;
        recuitToLevel[id] = 1;
        hasFreeMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function buyRecuit(uint256 _quatity)
    external
    payable
    whenNotPaused
    nonReentrant
    {
        require(msg.sender != address(0), "0 IS NOT A CORRECT ADDRESS");
        require(_quatity > 0,  "0 IS NOT VALID QUANTIIY");
        require(msg.value >= price * _quatity, "NOT_ENOUG_FUND");
        require((block.timestamp - vipSaleStartTime ) > vipMintingPeriod,"VIP SALE PERIOD");
        require(_totalSupply() <= TOTAL_SUPPLY, "SOLD_OUT");

        _updateState(_quatity);
    }


    function vipSale(uint256 _quatity, bytes32 _msgHash, bytes memory _signature, uint256 at)
    external
    payable
    whenNotPaused
    nonReentrant
    onlyValidSignature(_msgHash, _signature, systemSigner)
    hashMessage(_msgHash, at)
    {
        require(msg.sender != address(0), "0 IS NOT A CORRECT ADDRESS");
        require(_quatity > 0,  "0 IS NOT VALID QUANTIIY");
        require(msg.value >= price * _quatity, "NOT_ENOUG_FUND");
        require(block.timestamp - vipSaleStartTime < vipMintingPeriod, "VIP SALE PERIOD OVER");
        require(_totalSupply() <= TOTAL_SUPPLY, "SOLD_OUT");
        _updateState(_quatity);
    }

    function levelUp(bytes32 _msgHash, bytes memory _signature, uint256 _at, uint256 _tokenId, uint8 _level)
    external
    whenNotPaused
    nonReentrant
    onlyValidSignature(_msgHash, _signature, systemSigner)
    canLevelUp(_msgHash, _at, _level)
    {
        if(!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        require(msg.sender == ownerOf(_tokenId), "NOT OWNER");
        require(_level <= maxLevel, "MAXIMUM_LEVEL_EXCEEDED");
        require(recuitToLevel[_tokenId] == (_level -1), "CAN_ONLY_UPDRADE_ONE_LEVEL_AT_THE_TIME");
        recuitToLevel[_tokenId] = _level;
    }

    function payForlevelUp(uint256 _tokenId, uint8 _level)
    external
    payable
    whenNotPaused
    nonReentrant
    {
        if(!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        require(msg.value >= levelUpprice * _level, "NOT_ENOUG_FUND");
        require(_level > 0, "LEVEL_CAN_NOT_BE_0");
        require((recuitToLevel[_tokenId] + _level ) <= maxLevel, "MAXIMUM_LEVEL_EXCEEDED");
        recuitToLevel[_tokenId] += _level;
    }

    function levelUpByOwner(uint256 _tokenId, uint8 _level)
    external 
    onlyOwner 
    nonReentrant
    {
        require(_level > 0, "LEVEL_CAN_NOT_BE_0");
        require(_level < maxLevel, "MAXIMUM_LEVEL_EXCEEDED");
        require(recuitToLevel[_tokenId] < _level, "CAN_NOT_UPGRADE_TO_LOWER_LEVEL");
        recuitToLevel[_tokenId] = _level;
    }

    function safeMintByOwner(address _to, uint256 _quantity) external onlyOwner nonReentrant {
        uint256 startId = _nextTokenId();
        _safeMintByOwner(_to, _quantity);
        for (uint256 index = 0; index < _quantity -1; index++) {
            recuitToLevel[startId + index] = 1;
        }
    }

    function safeMintBatchByOwner(address[] memory _tos, uint256[] memory _quantities) external onlyOwner nonReentrant {
        require(_tos.length == _quantities.length, "THE 2 ARRAYS SHOULD HAVE THE SAME LENGTH");
        require(_totalSupply() <= TOTAL_SUPPLY, "SOLD_OUT");
        for (uint256 index = 0; index < _tos.length; index++) {
            _safeMintByOwner(_tos[index], _quantities[index]);
        }
    }

    function _safeMintByOwner(address _to, uint256 _quantity) internal {
        require(_to != address(0), "0 IS NOT A VALID ADDRESS");
        require(_quantity > 0, "0 IS NOT VALID QUANTIIY");
        uint256 startId = _nextTokenId();
        _safeMint(_to, _quantity);
        for (uint256 index = 0; index < _quantity; index++) {
            isFreeToken[startId + index] = true;
            recuitToLevel[startId + index] = 1;
        }
    }

    function burn(uint256 _tokenId) external whenNotPaused nonReentrant {
        _burn(_tokenId, true);
    }

    function setTokenURIByOnwer(uint256 _tokenId, string memory _tokenURI) external onlyOwner nonReentrant {
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function _updateState( uint256 _quatity) private{
        uint256 startId = _nextTokenId();
        _safeMint(msg.sender, _quatity);
        for (uint256 index = 0; index < _quatity; index++) {
            recuitToLevel[startId + index] = 1;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- SETTERS ---------- */

    function setSystemSigner(address _systemSigner) public onlyOwner nonReentrant {
        systemSigner = _systemSigner;
    }

    function setVipSaleStartTime(uint256 _vipSaleStartTime) public onlyOwner nonReentrant {
        vipSaleStartTime = _vipSaleStartTime;
    }

    function setVipMintingPeriod(uint256 _period) public onlyOwner nonReentrant {
        vipMintingPeriod = _period;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price * 1e16;
    }

    function setLevelUpprice(uint256 _price) external onlyOwner {
        levelUpprice = _price * 1e16;
    }

    function setMaximumLevel(uint8 _maxLevel) external onlyOwner {
        maxLevel = _maxLevel;
    }

    function setLieutenantLevel(uint8 _level) external onlyOwner {
        lieutenantLevel = _level;
    }

    function setRevealed(bool _reveale) public onlyOwner nonReentrant {
        revealed = _reveale;
    }

    function setOperator(address operator, bool approved) public onlyOwner  {
        operators[operator] = approved;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more than zero");
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    /* ---------- STATE MUTATIONS ---------- */

    function pause() public onlyOwner nonReentrant{
        _pause();
    }

    function unpause() public onlyOwner nonReentrant{
        _unpause();
    }
}