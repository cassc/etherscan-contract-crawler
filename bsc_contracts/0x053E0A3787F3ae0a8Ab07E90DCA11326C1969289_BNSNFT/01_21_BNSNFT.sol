// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./token/ERC721/ERC721.sol";
import "./token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/IContentRouter.sol";
import "./RecoverableFunds.sol";
import "./interfaces/ITransferCallbackContract.sol";

contract BNSNFT is ERC721, ERC721Enumerable, Pausable, AccessControl, RecoverableFunds {

    using Counters for Counters.Counter;

    IContentRouter public contentRouter;
    ITransferCallbackContract public transferCallbackContract;

    string public baseURI;

    mapping(bytes32 => bool) public domainNameExists;
    mapping(uint256 => string) public tokenIdToDomainNames;
    mapping(bytes32 => uint256) public domainNamesToTokenId;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Web3DNA", "W3DNA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        setBaseURI("https://marketing-service.w3dna.net/api/v1/metadata/");
    }

    function setTransferCallbackContract(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transferCallbackContract = ITransferCallbackContract(contractAddress);
    }

    function isDomainNameExists(string memory domainName) external view returns (bool) {
        return domainNameExists[keccak256(abi.encodePacked(domainName))];
    }

    function setContentRouter(address newContentRouter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contentRouter = IContentRouter(newContentRouter);
    }

    function getDomainNameOwner(string calldata domainName) external view returns (address)  {
        return ownerOf(getTokenIdByDomainName(domainName));
    }

    function getTokenIdByDomainName(string calldata domainName) public view returns (uint256)  {
        bytes32 domainNameHash = keccak256(abi.encodePacked(domainName));
        require(domainNameExists[domainNameHash], "BNSNFT: Domain name not exists");
        return domainNamesToTokenId[domainNameHash];
    }

    function getRelativeContentByTokenId(uint256 tokenId, string memory relativePath) external view returns (IContentRouter.ContentType contentType, string memory)  {
        require(_exists(tokenId), "BNSNFT: Content query for nonexistent token");
        string memory domainName = tokenIdToDomainNames[tokenId];
        return contentRouter.getContentOrAddress(domainName, relativePath);
    }

    function getContentByTokenId(uint256 tokenId) external view returns (IContentRouter.ContentType contentType, string memory)  {
        require(_exists(tokenId), "BNSNFT: Content query for nonexistent token");
        string memory domainName = tokenIdToDomainNames[tokenId];
        return contentRouter.getContentOrAddress(domainName, "");
    }

    function getRelativeContentByDomainName(string memory domainName, string memory relativePath) external view returns (IContentRouter.ContentType contentType, string memory)  {
        return contentRouter.getContentOrAddress(domainName, relativePath);
    }

    function getContentByDomainName(string memory domainName) external view returns (IContentRouter.ContentType contentType, string memory)  {
        return contentRouter.getContentOrAddress(domainName, "");
    }

    function setRelativeContentOrAddressByTokenId(uint tokenId, string memory relativePath, string memory content, IContentRouter.ContentType contentType, address contentProvider) external {
        require(msg.sender == ownerOf(tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BNSNFT: Only admin or token owner can set content");
        require(_exists(tokenId), "BNSNFT: Content query for nonexistent token");
        string memory domainName = tokenIdToDomainNames[tokenId];
        contentRouter.setContentOrAddress(domainName, relativePath, content, contentType, contentProvider);
    }

    function setContentOrAddressByTokenId(uint tokenId, string memory content, IContentRouter.ContentType contentType, address contentProvider) external {
        require(msg.sender == ownerOf(tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BNSNFT: Only admin or token owner can set content");
        require(_exists(tokenId), "BNSNFT: Content query for nonexistent token");
        string memory domainName = tokenIdToDomainNames[tokenId];
        contentRouter.setContentOrAddress(domainName, "", content, contentType, contentProvider);
    }

    function setContentOrAddressByDomainName(string memory domainName, string memory content, IContentRouter.ContentType contentType, address contentProvider) external {
        bytes32 domainNameHash = keccak256(abi.encodePacked(domainName));
        uint tokenId = domainNamesToTokenId[domainNameHash];
        require(msg.sender == ownerOf(tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BNSNFT: Only admin or token owner can set content");
        require(_exists(tokenId), "BNSNFT: Content query for nonexistent token");
        contentRouter.setContentOrAddress(domainName, "", content, contentType, contentProvider);
    }

    function setRelativeContentOrAddressByDomainName(string memory domainName, string memory relativePath, string memory content, IContentRouter.ContentType contentType, address contentProvider) external {
        bytes32 domainNameHash = keccak256(abi.encodePacked(domainName));
        uint tokenId = domainNamesToTokenId[domainNameHash];
        require(msg.sender == ownerOf(tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BNSNFT: Only admin or token owner can set content");
        require(_exists(tokenId), "BNSNFT: Content query for nonexistent token");
        contentRouter.setContentOrAddress(domainName, relativePath, content, contentType, contentProvider);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        if (address(transferCallbackContract) != address(0x0)) {
            transferCallbackContract.beforeTransferCallback(from, to, tokenId);
        }

        ERC721.transferFrom(from, to, tokenId);

        if (address(transferCallbackContract) != address(0x0)) {
            transferCallbackContract.afterTransferCallback(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        if (address(transferCallbackContract) != address(0x0)) {
            transferCallbackContract.beforeTransferCallback(from, to, tokenId);
        }

        ERC721.safeTransferFrom(from, to, tokenId, "");

        if (address(transferCallbackContract) != address(0x0)) {
            transferCallbackContract.afterTransferCallback(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) {
        if (address(transferCallbackContract) != address(0x0)) {
            transferCallbackContract.beforeTransferCallback(from, to, tokenId);
        }

        ERC721.safeTransferFrom(from, to, tokenId, data);

        if (address(transferCallbackContract) != address(0x0)) {
            transferCallbackContract.afterTransferCallback(from, to, tokenId);
        }
    }

    /**
     *
     * Check domain names before call this method!!!
     *
     **/
    function unsafeBatchMint(address to, string[] calldata domainNames) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < domainNames.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _balances[to] += 1;
            _owners[tokenId] = to;
            bytes32 domainNameHash = keccak256(abi.encodePacked(domainNames[i]));
            domainNameExists[domainNameHash] = true;
            tokenIdToDomainNames[tokenId] = domainNames[i];
            domainNamesToTokenId[domainNameHash] = tokenId;
        }
    }

    function safeBatchMint(address to, string[] calldata domainNames) public onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < domainNames.length; i++) {
            bytes32 domainNameHash = keccak256(abi.encodePacked(domainNames[i]));
            require(!domainNameExists[domainNameHash], "BNSNFT: Domain name already exists");
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            domainNameExists[domainNameHash] = true;
            tokenIdToDomainNames[tokenId] = domainNames[i];
            domainNamesToTokenId[domainNameHash] = tokenId;
        }
    }

    function safeMint(address to, string calldata domainName) public onlyRole(MINTER_ROLE) returns (uint256) {
        bytes32 domainNameHash = keccak256(abi.encodePacked(domainName));
        require(!domainNameExists[domainNameHash], "BNSNFT: Domain name already exists");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        domainNameExists[domainNameHash] = true;
        tokenIdToDomainNames[tokenId] = domainName;
        domainNamesToTokenId[domainNameHash] = tokenId;
        return tokenId;
    }

    // FIXME: Why?
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // FIXME: Why?
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveTokens(recipient, tokenAddress);
    }

    function retrieveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveETH(recipient);
    }

}