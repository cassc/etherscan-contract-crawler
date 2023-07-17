// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract MomentX_Genesis_Tablet is ERC721, ERC721URIStorage, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    // Role Setting
    bytes32 public constant EVENT_MANAGER_ROLE = keccak256("EVENT_MANAGER_ROLE");

    // NFT ID counter
    Counters.Counter private _tokenIdCounter;
    string constant public baseURI = "https://meta.momentx.app/genesis/tables/";

    // presale & openSale control
    bool public isPreSale = false;
    bool public isOpenSale = false;
    address public constant VAULT = 0x886728d9eFAB7d2E94f6757e95a7Ad459ab8b0aE;
    address private _marketplace_manager;
    address private _whitelist_admin;

    mapping(address => bool) private whiteList_minted; // true = minted, false not minted

    // NFT setting
    uint256 private keyPrice = 0.01 ether;
    uint256 private constant MAX_KEY = 1000;

    //GameFI setting
    uint256 private constant GENESIS = 0;
    uint256 private constant UR = 0;

    uint256 public constant collection_era = GENESIS;
    uint256 public constant collection_rarity = UR;



    constructor() ERC721("MomentX Genesis Tablet", "MXGT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EVENT_MANAGER_ROLE, msg.sender);
        _marketplace_manager = msg.sender;
        _whitelist_admin = 0xEE44aC234b5de7d369a398DB6f5C5A4856f0524e;
        _mintKeys();

    }


    modifier onlyValidAccess(bytes memory signature){
        require (isValidAccessMessage(msg.sender, signature));
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function owner() public view returns(address){ //for opensea
        return _marketplace_manager;
    }

    function transferMarketOwner(address newOwner) public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0), "new owner is the zero address");
        _marketplace_manager = newOwner;
    }

    function setWhiteListAdmin(address newAdmin) public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "new whitelist admin is the zero address");
        _whitelist_admin = newAdmin;
    }

    function mintKeys(bytes memory signature) public nonReentrant payable{

        require(_tokenIdCounter.current() < MAX_KEY, "already sold out");
        require(isPreSale || isOpenSale, "Sale not open");
        require(msg.value >= keyPrice, "insufficient ether");

        if(isPreSale && !isOpenSale){
            require(isValidAccessMessage(msg.sender, signature), "your address is not in whitelist");
            require(!whiteList_minted[msg.sender], "you can only mint once during presale");

            whiteList_minted[msg.sender] = true;

            _mintKeys();
            _withdraw();

            emit isMintSuccess(true, _tokenIdCounter.current()-1);

        } else if (isOpenSale){

            _mintKeys();
            _withdraw();

            emit isMintSuccess(true, _tokenIdCounter.current()-1);
        } else {

            emit isMintSuccess(false, 0);
        }

    }

    function mint5Keys() public nonReentrant payable{

        require(_tokenIdCounter.current() < MAX_KEY-4, "already sold out");
        require(isOpenSale, "Sale not open");
        require(msg.value >= keyPrice*5, "insufficient ether");

            _mintKeys();
            _mintKeys();
            _mintKeys();
            _mintKeys();
            _mintKeys();

            _withdraw();

        emit isMintSuccess(true, _tokenIdCounter.current()-1);
    }

    function _mintKeys() internal  {

        _safeMint(msg.sender, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(),string(abi.encodePacked(baseURI, _tokenIdCounter.current().toString(), ".json")));
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
       return super.tokenURI(tokenId);
    }

     function _exists(uint256 tokenId) internal view override returns (bool) {
        return super._exists(tokenId);
    }

    // setting for sale
    function saleControl(bool b_pre, bool b_open) public onlyRole(EVENT_MANAGER_ROLE){

        isPreSale = b_pre;
        isOpenSale = b_open;
    }


    function _withdraw() internal {
        (bool success, ) = payable(address(VAULT)).call{value: address(this).balance}("");
        require(success);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = payable(address(VAULT)).call{value: address(this).balance}("");
        require(success);
    }

    function isValidAccessMessage(address _add, bytes memory signature) view internal returns(bool){

        address recovered_address = keccak256(abi.encodePacked(address(this),_add)).toEthSignedMessageHash().recover(signature);

        return  (_whitelist_admin == recovered_address);
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    event totalWhiteListAdded(uint amount);
    event isMintSuccess(bool is_success, uint tokenId);

}