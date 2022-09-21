// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {FireCatNFTStorage} from "./storages/FireCatNFTStorage.sol";
import {IFireCatNFT} from "../src/interfaces/IFireCatNFT.sol";


contract FireCatNFT is IFireCatNFT, ERC721Enumerable, Ownable, FireCatNFTStorage, ReentrancyGuard {
    using Strings for uint256;

    event Mint(address minter, address recipient, uint256 newTokenId);
    event UpgradeToken(address minter, uint256 tokenId, uint256 newLevel);
    event AddSupply(uint256 amount, uint256 newSupplyLimit);
    event SetHighestLevel(uint256 level);
    event SetUpgradeProxy(address upgradeProxy);
    event SetUpgradeStorage(address upgradeStorage);
    event SetFireCatProxy(address fireCatProxy);
    
    /**
     * @dev Total number of ERC721 token.
     */
    uint256 private _totalSupply;

    /**
    * @dev Mapping from token ID to token level.
    */
    mapping(uint256 => uint256) private _tokenLevel;

    /**
    * @dev Mapping from owner address to token ID.
    */
    mapping(address => uint256[]) private _ownerTokenId;

    /**
    * @dev Mapping from owner address to whether the owner has minted a token.
    */
    mapping(address => bool) private _hasMinted;

    /**
    * @dev To set the highest level of NFT.
    */
    uint256 private _highestLevel;

    /**
    * @dev To set the supply limit of NFT.
    */
    uint256 private _supplyLimit;

    error MaxSupply(uint256 supplyLimit);
    error NonExistentTokenURI(uint256 tokenId);
    error WithdrawTransfer(address sender);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _initialSupply
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        _supplyLimit = _initialSupply;
    }
    
    modifier onlyProxy() {
        require(msg.sender == fireCatProxy, "NFT:E00");
        _;
    }

    /// @inheritdoc IFireCatNFT
    function totalSupply() public view override(ERC721Enumerable, IFireCatNFT) returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IFireCatNFT
    function freshTokenId() public view returns (uint256) {
        return currentTokenId + 1;
    }

    /// @inheritdoc IFireCatNFT
    function hasMinted(address user) public view returns (bool) {
        return _hasMinted[user];
    }

    /// @inheritdoc IFireCatNFT
    function supplyLimit() public view returns (uint256) {
        return _supplyLimit;
    }

    /// @inheritdoc IFireCatNFT
    function highestLevel() public view returns (uint256) {
        return _highestLevel;
    }

    /// @inheritdoc IFireCatNFT
    function tokenIdOf(address owner) public view override(IFireCatNFT) returns (uint256[] memory) {
        return _ownerTokenId[owner];
    }

    /// @inheritdoc IFireCatNFT
    function tokenLevelOf(uint256 tokenId) public view returns (uint256) {
        return _tokenLevel[tokenId];
    }
    
    /// @inheritdoc IFireCatNFT
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IFireCatNFT, ERC721)
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI(tokenId);
        }
        uint256 level = _tokenLevel[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, level.toString())) : "";

    }

    /**
    * @notice remove tokenId from array.
    * @dev Remove array element by shifting elements from right to left.
    * @param user address.
    * @param index uint256.
    */
    function removeTokenId(address user, uint256 index) internal {
        require(index < _ownerTokenId[user].length, "NFT:E10");

        for (uint i = index; i < _ownerTokenId[user].length - 1; i++) {
            _ownerTokenId[user][i] = _ownerTokenId[user][i + 1];
        }
        _ownerTokenId[user].pop();
    }

    /**
    * @notice Every address only mints one NFT. 
    * @dev Mint NFT, set default level 1.
    * @param recipient address.
    * @return newTokenId uint256
    */
    function _mint(address recipient) internal returns (uint256) {
        require(recipient != address(0), "NFT:E11");
        require(!hasMinted(recipient), "NFT:E01");

        uint256 newTokenId = freshTokenId();
        if (newTokenId > _supplyLimit) {
            revert MaxSupply(_supplyLimit);
        }

        _totalSupply += 1;
        _hasMinted[recipient] = true;
        currentTokenId = newTokenId;
        _tokenLevel[newTokenId] = 1;
        _safeMint(recipient, newTokenId);
        emit Mint(msg.sender, recipient, newTokenId);
        return newTokenId;
    }

    /**
    * @notice After token transfer, _ownerTokenId remove an element. 
    * @dev Call after _transfer.
    * @param from address.
    * @param to address.
    * @param tokenId uint256.
    */
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override {
        _ownerTokenId[to].push(tokenId);

        uint256[] memory fromTokenList = _ownerTokenId[from];
        for (uint256 i = 0; i < _ownerTokenId[from].length; i++) {
            if (fromTokenList[i] == tokenId) {
                removeTokenId(from, i);
            }
        }
    }

    /// @inheritdoc IFireCatNFT
    function mintTo(address recipient) external onlyOwner returns (uint256) {
        return _mint(recipient);
    }

    /// @inheritdoc IFireCatNFT
    function multiMintTo(address[] memory recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i]);
        }
    }

    /// @inheritdoc IFireCatNFT
    function proxyMint(address recipient) external onlyProxy returns (uint256) {
        return _mint(recipient);
    }

    /// @inheritdoc IFireCatNFT
    function upgradeToken(uint256 tokenId) external override(IFireCatNFT) nonReentrant {
        require(_hasMinted[msg.sender], "NFT:E03");
        require(ownerOf(tokenId) == msg.sender, "NFT:E04");    
        require(_tokenLevel[tokenId] + 1 <= _highestLevel, "NFT:E05");
        require(upgradeProxy != address(0) && upgradeStorage != address(0), "NFT:E06");

        bytes memory callData = abi.encodeWithSignature("isQualified(uint256)", tokenId);
        (bool res, bytes memory returnData) = upgradeProxy.delegatecall(callData);
        require(res, string(returnData));

        bool judgeRes = abi.decode(returnData, (bool));
        require(judgeRes, "NFT:E07");
        uint256 newLevel = _tokenLevel[tokenId] + 1;
        _tokenLevel[tokenId] = newLevel;
        emit UpgradeToken(msg.sender, tokenId, newLevel);
    }

    /// @inheritdoc IFireCatNFT
    function addSupply(uint256 amount_) external onlyOwner {
        require(_supplyLimit + amount_ > _supplyLimit, "NFT:E08");
        _supplyLimit += amount_;
        emit AddSupply(amount_, _supplyLimit);
    }

    /// @inheritdoc IFireCatNFT
    function burn(uint256 tokenId_) external onlyOwner {
        _totalSupply -= 1;
        _burn(tokenId_);
    }

    /// @inheritdoc IFireCatNFT
    function setHighestLevel(uint256 level_) external onlyOwner {
        require(level_ > _highestLevel, "NFT:E09");
        _highestLevel = level_;
        emit SetHighestLevel(level_);
    }

    /// @inheritdoc IFireCatNFT
    function setUpgradeProxy(address upgradeProxy_) external onlyOwner {
        upgradeProxy = upgradeProxy_;
        emit SetUpgradeProxy(upgradeProxy_);
    }

    /// @inheritdoc IFireCatNFT
    function setUpgradeStorage(address upgradeStorage_) external onlyOwner {
        upgradeStorage = upgradeStorage_;
        emit SetUpgradeStorage(upgradeStorage_);
    }

    /// @inheritdoc IFireCatNFT
    function setFireCatProxy(address fireCatProxy_) external onlyOwner {
        fireCatProxy = fireCatProxy_;
        emit SetFireCatProxy(fireCatProxy_);
    }
}