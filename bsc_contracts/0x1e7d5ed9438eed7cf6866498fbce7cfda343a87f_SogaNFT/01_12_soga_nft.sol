// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SogaNFT is ERC721,Ownable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    using Strings for uint256;

    // Contract URI
    string private _contractUri;

    // Bbase URI
    string private _baseUri;

    //Contract Owner
    address private _owner;

    // Mapping minter address to approved
    mapping(address => bool) private _minters;
    
    mapping(address => bool) private _addressesBlacklist;
    mapping(uint256 => bool) private _tokedIdBlacklist;

    modifier onlyMinter() {
        bool ok = msg.sender == _owner;
        if (!ok){
            ok = _minters[msg.sender];
        }
        
        require(ok,"Illegal operation.");
        _;
    }

    constructor(
        //address owner,
        string memory name_, 
        string memory symbol_,
        string memory contractUri,
        string memory baseUri
        ) ERC721(name_,symbol_) Ownable(){
        //_owner = owner;
        _owner = msg.sender;
        _contractUri = contractUri;
        _baseUri = baseUri;
    }

    /** 
     * @dev For OpenSea Contract-level metadata 
     *  https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toMetadataPath(tokenId))) : "";
    }

    //Mint
    function mint(address to, uint256 tokenId) public onlyMinter {
        _mint(to,tokenId);
    }

    //Batch Mint
    function batchMint(address to, uint256[] calldata tokenIds) public onlyMinter {
        require(tokenIds.length > 0,"Illegal parameter.");
        require(tokenIds.length <= 30,"Illegal parameter.");

        for (uint i = 0; i < tokenIds.length; i++){
            _mint(to,tokenIds[i]);
        }
    }

    //Minter
    function approveMinter(address[] calldata addresses, bool approved) public onlyOwner {
        require(addresses.length > 0,"Illegal parameter.");
        require(addresses.length <= 30,"Illegal parameter.");

        for (uint i = 0; i < addresses.length; i++){
            _minters[addresses[i]] = approved;
        }
    }

    function isMinter(address minter) public view returns (bool){
        if (_owner == minter) return true;
        
        return _minters[minter];
    }

    function toMetadataPath(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(64 + 6);
        for (uint256 i = 63; i > 0; --i) {
            buffer[i + 6] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }

        buffer[6] = _SYMBOLS[value & 0xf];

        buffer[0] = buffer[6];
        buffer[1] = buffer[7];
        buffer[2] = bytes("/")[0];
        buffer[3] = buffer[8];
        buffer[4] = buffer[9];
        buffer[5] = buffer[2];

        return string(buffer);
    }

    function version () public pure returns (string memory) {
        return "v1.1.0";
    }

    function exists (uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    //v1.1.0
    function setBaseURI (string memory uri) public onlyOwner {
        _baseUri = uri;
    }

    function setContractURI (string memory uri) public onlyOwner {
        _contractUri = uri;
    }

    function blockAddress (address addr,bool isBlock) public onlyOwner {
        if (isBlock) {
            _addressesBlacklist[addr] = isBlock;
        } else {
            delete _addressesBlacklist[addr];
        }
    }

    function blockTokenId (uint256[] calldata tokenIds,bool isBlock) public onlyOwner {
        require(tokenIds.length > 0,"Illegal parameter.");

        for (uint i = 0; i < tokenIds.length; i++){
            if (isBlock) {
                _tokedIdBlacklist[tokenIds[i]] = isBlock;
            } else {
                delete _tokedIdBlacklist[tokenIds[i]];
            }
        }
    }

    function isBlockedAddress(address addr) public view returns (bool){
        return _addressesBlacklist[addr];
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function batchBurn(uint256[] calldata tokenIds) public onlyOwner {
        require(tokenIds.length > 0,"Illegal parameter.");

        for (uint i = 0; i < tokenIds.length; i++){
            _burn(tokenIds[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId, /* firstTokenId */
        uint256 batchSize
    ) internal virtual override {
        if (to != address(0)) {
            require(from == address(0) || _addressesBlacklist[from] == false,"The 'from' address has been blacklisted");
            require(_addressesBlacklist[to] == false,"The 'to' address has been blacklisted");
            require(_tokedIdBlacklist[tokenId] == false,"Token ID has been blacklisted");
        }

        super._beforeTokenTransfer(from,to,tokenId,batchSize);
    }
}