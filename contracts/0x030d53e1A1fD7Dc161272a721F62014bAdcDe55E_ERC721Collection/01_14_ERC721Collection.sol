// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract ERC721Collection is ERC721URIStorageUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    mapping(bytes32 => bool) private tokenExists;
    mapping(address => bool) public whitelist;
    uint256 public currentTokenId;
    uint256 public maxSupply;

    error NonExistentToken();
    error NoPermission();
    error TokenURIEmpty();
    error TokenExist();
    error LimitedMaxSupply();
    error InvalidMaxSupply();

    event SetTokenURI(uint256 tokenId, string tokenUri);
    event SetPermission(address account, bool permission);
    event SetMaxSupply(uint256 newMaxSupply);

    modifier existTokenId(uint256 tokenId) {
        if (tokenId == 0 || tokenId > currentTokenId) revert NonExistentToken();
        _;
    }

    modifier hasPermission(address account) {
        if (account != owner() && !whitelist[account]) revert NoPermission();
        _;
    }

    // **********************  Constructor  **********************
    function initialize(string memory name_, string memory symbol_, uint256 maxSupply_) public initializer {
        maxSupply = maxSupply_;

        // Ownable Initialize
        __Ownable_init();
        // Pausable Initialize
        __Pausable_init();
        // ERC721URIStorage Initialize
        __ERC721URIStorage_init();
        // ERC721 Initialize
        __ERC721_init(name_, symbol_);
    }

    function mintTo(address _to, string memory _tokenURI) external hasPermission(_msgSender()) {
        if(bytes(_tokenURI).length == 0) revert TokenURIEmpty();
        if(currentTokenId >= maxSupply) revert LimitedMaxSupply();

        // check token exists
        bytes32 uriHash = keccak256(abi.encodePacked(_tokenURI));
        if(tokenExists[uriHash] == true) revert TokenExist();

        // mint
        tokenExists[uriHash] = true;

        uint256 tokenId = currentTokenId + 1;
        currentTokenId = tokenId;

        _mint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function totalSupply() external view returns (uint256) {
        return currentTokenId;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external hasPermission(_msgSender()) existTokenId(_tokenId) {
        if(bytes(_tokenURI).length == 0) revert TokenURIEmpty();

        // check token tokenExists
        bytes32 uriHash = keccak256(abi.encodePacked(_tokenURI));
        if(tokenExists[uriHash] == true) revert TokenExist();

        bytes32 originUriHash = keccak256(abi.encodePacked(tokenURI(_tokenId)));

        // update map
        tokenExists[originUriHash] = false;
        tokenExists[uriHash] = true;

        _setTokenURI(_tokenId, _tokenURI);

        emit SetTokenURI(_tokenId, _tokenURI);
    }

    function setPermission(address account, bool flag) external onlyOwner {
        whitelist[account] = flag;

        emit SetPermission(account, flag);
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        if(currentTokenId > maxSupply_) revert InvalidMaxSupply();

        maxSupply = maxSupply_;

        emit SetMaxSupply(maxSupply_);
    }

    // **********************  Pausable  **********************
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}