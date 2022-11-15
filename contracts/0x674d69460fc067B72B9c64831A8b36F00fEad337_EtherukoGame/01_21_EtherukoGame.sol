//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "hardhat/console.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/access/AccessControl.sol";
import "./openzeppelin/security/Pausable.sol";
import "./interface/IEtherukoGame.sol";
import "./openzeppelin/token/ERC721/ERC721.sol";
import "./openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "./openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
import "./openzeppelin/token/ERC721/extensions/ERC721Pausable.sol";
import "./openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";

contract EtherukoGame is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable,
    Ownable,
    IEtherukoGame
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public _name = "EtherukoCard";
    string public _symbol = "ETHERUCARD";
    string public _baseUri = "https://api.etheruko.com/metadata/card/";

    uint256 public maxSupply = 250000;

    constructor() ERC721("EtherukoGame", "ETHERUKOGAME") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier supplyLimit(uint256 _amount) {
        require(
            totalSupply() + _amount <= maxSupply,
            "EtherukoGame: Max supply reached"
        );
        _;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit SetMaxSupply(newMaxSupply);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyRole(MINTER_ROLE)
    {
        _setTokenURI(tokenId, _tokenURI);
        emit SetTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseUri = baseURI;
        emit SetBaseURI(baseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setName(string memory newName) external onlyOwner {
        _name = newName;
        emit SetName(newName);
    }

    function setSymbol(string memory newSymbol) external onlyOwner {
        _symbol = newSymbol;
        emit SetSymbol(newSymbol);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function grantMinter(address account) external onlyRole(MINTER_ROLE) {
        _grantRole(MINTER_ROLE, account);
        emit GrantMinter(account);
    }

    function revokeMinter(address account) external onlyRole(MINTER_ROLE) {
        _revokeRole(MINTER_ROLE, account);
        emit RevokeMinter(account);
    }

    function isPauser(address account) external view returns (bool) {
        return hasRole(PAUSER_ROLE, account);
    }

    function grantPauser(address account) external onlyRole(PAUSER_ROLE) {
        _grantRole(PAUSER_ROLE, account);
        emit GrantPauser(account);
    }

    function revokePauser(address account) external onlyRole(PAUSER_ROLE) {
        _revokeRole(PAUSER_ROLE, account);
        emit RevokePauser(account);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    )
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        supplyLimit(1)
        returns (uint256)
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit SafeMint(to, tokenId, uri);
        return tokenId;
    }

    function sequencialSafeMint(address to)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        returns (uint256)
    {
        uint256 tokenId = totalSupply();
        return safeMint(to, tokenId, Strings.toString(tokenId));
    }

    function safeMassMint(
        address to,
        uint256[] memory tokenIds,
        string[] memory uris
    )
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        supplyLimit(tokenIds.length)
        returns (uint256[] memory)
    {
        require(
            tokenIds.length == uris.length,
            "EtherukoGame: tokenIds and uris length mismatch"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeMint(to, tokenIds[i], uris[i]);
        }
        return tokenIds;
    }

    function sequencialSafeMassMint(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        supplyLimit(amount)
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](amount);
        string[] memory uris = new string[](amount);
        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = totalSupply();
            uris[i] = Strings.toString(tokenIds[i]);
        }
        return safeMassMint(to, tokenIds, uris);
    }

    function sequencialSafeBatchMint(
        address[] calldata toList,
        uint256[] calldata amountList
    ) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(
            toList.length == amountList.length,
            "EtherukoGame: toList and amountList length mismatch"
        );
        for (uint256 i = 0; i < toList.length; i++) {
            sequencialSafeMassMint(toList[i], amountList[i]);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}