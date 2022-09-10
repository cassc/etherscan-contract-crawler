// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @dev Theia ERC1155 Collection Version 2
/// Added "mint price" and "treasury"
contract ERC1155CollectionV2 is ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    struct MintInfo {
        bytes32 merkleRoot;
        uint256 maxPerUser;
        uint256 mintAmount;
    }

    string public name;
    string public symbol;
    uint256 public nextTokenId;
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => MintInfo) private _mintInfos;
    mapping(uint256 => mapping(address => uint256)) private _mintedAmount;
    mapping(uint256 => uint256) public mintPrice;
    address public treasury;

    // **********************  Errors  **********************
    error NonExistentToken();
    error WhitelistMint();
    error PublicMint();
    error MaxMintAmount();
    error MaxMintPerUser();
    error InvalidInWhitelist();
    error MaxMintWhitelist();
    error InvalidETH();
    error InvalidTreasury();

    // **********************  Events  **********************
    event AddCollection(uint256 tokenId, string uri, MintInfo mintInfo, uint256 mintPrice);
    event SetMintInfo(MintInfo mintInfo, uint256 tokenId);
    event SetTreasury(address treasury);

    // **********************  Modifiers  **********************
    modifier existTokenId(uint256 tokenId) {
        if (tokenId >= nextTokenId) revert NonExistentToken();
        _;
    }

    // **********************  Constructor  **********************
    function initialize(string memory name_, string memory symbol_) public initializer {
        name = name_;
        symbol = symbol_;

        // Ownable Initialize
        __Ownable_init();
        // Pausable Initialize
        __Pausable_init();
        // ERC1155 Initialize
        __ERC1155_init("");
    }

    /**
     * @dev Add sub collection
     *   if merkleRoot_ is zero, sub collection will be public-mint, or not will be whitelist-mint
     */
    function addCollection(
        string memory uri_,
        bytes32 merkleRoot_,
        uint256 maxPerUser_,
        uint256 mintAmount_,
        uint256 mintPrice_
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;

        nextTokenId++;
        _tokenURIs[tokenId] = uri_;
        _mintInfos[tokenId] = MintInfo({merkleRoot: merkleRoot_, maxPerUser: maxPerUser_, mintAmount: mintAmount_});
        mintPrice[tokenId] = mintPrice_;

        emit AddCollection(tokenId, uri(tokenId), mintInfo(tokenId), mintPrice_);
    }

    /**
     * @dev Public mint
     *  if owner mint, there is no limit
     */
    function publicMint(
        address to_,
        uint256 tokenId_,
        uint256 quantity_,
        bytes memory data_
    ) external existTokenId(tokenId_) whenNotPaused payable {
        uint256 totalSupply_ = _totalSupply[tokenId_];
        if (_msgSender() != owner()) {
            uint256 _mintPrice = mintPrice[tokenId_];
            if(_mintPrice != 0 && msg.value != _mintPrice) revert InvalidETH();

            MintInfo memory mi = mintInfo(tokenId_);

            if (mi.merkleRoot != 0) revert WhitelistMint();
            if (totalSupply_ + quantity_ > mi.mintAmount) revert MaxMintAmount();

            uint256 mintedAmount_ = _mintedAmount[tokenId_][_msgSender()];
            if (mintedAmount_ + quantity_ > mi.maxPerUser) revert MaxMintPerUser();

            _mintedAmount[tokenId_][_msgSender()] = mintedAmount_ + quantity_;
        }
        _totalSupply[tokenId_] = totalSupply_ + quantity_;

        _mint(to_, tokenId_, quantity_, data_);

        if(treasury != address(0)) {
            payable(treasury).transfer(msg.value);
        }
    }

    /**
     * @dev Whitelist mint
     *  if account is not exist in whitelist, he can not mint
     */
    function whitelistMint(
        address to_,
        uint256 tokenId_,
        uint256 quantity_,
        bytes memory data_,
        uint256 index_,
        bytes32[] calldata _proofs,
        uint256 maxAmount
    ) external existTokenId(tokenId_) whenNotPaused payable {
        MintInfo memory mi = mintInfo(tokenId_);
        if (mi.merkleRoot == 0) revert PublicMint();
        uint256 _mintPrice = mintPrice[tokenId_];
        if(_mintPrice != 0 && msg.value != _mintPrice) revert InvalidETH();

        bytes32 leaf = keccak256(abi.encodePacked(index_, _msgSender(), maxAmount));
        if (!MerkleProof.verify(_proofs, mi.merkleRoot, leaf)) revert InvalidInWhitelist();

        uint256 totalSupply_ = _totalSupply[tokenId_];
        if (totalSupply_ + quantity_ > mi.mintAmount) revert MaxMintAmount();

        uint256 mintedAmount_ = _mintedAmount[tokenId_][_msgSender()];
        if (mintedAmount_ + quantity_ > mi.maxPerUser) revert MaxMintPerUser();
        if (mintedAmount_ + quantity_ > maxAmount) revert MaxMintWhitelist();

        unchecked {
            _mintedAmount[tokenId_][_msgSender()] = mintedAmount_ + quantity_;
            _totalSupply[tokenId_] = totalSupply_ + quantity_;
        }

        _mint(to_, tokenId_, quantity_, data_);

        if(treasury != address(0)) {
            payable(treasury).transfer(msg.value);
        }
    }

    /**
     * @dev Public batch mint
     *  Any one can mint several nfts at once. If owner mint, there is no limit
     */
    function mintBatch(
        address to_,
        uint256[] memory tokenIds_,
        uint256[] memory quantities_,
        bytes memory data_
    ) external whenNotPaused payable {
        uint256 totalMintPrice = 0;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            if (tokenId >= nextTokenId) revert NonExistentToken();

            uint256 quantity = quantities_[i];
            uint256 totalSupply_ = _totalSupply[tokenId];

            if (_msgSender() != owner()) {
                uint256 _mintPrice = mintPrice[tokenId];
                if(_mintPrice != 0) {
                    totalMintPrice += _mintPrice;
                }

                MintInfo memory mi = mintInfo(tokenId);

                if (mi.merkleRoot != 0) revert WhitelistMint();
                if (totalSupply_ + quantity > mi.mintAmount) revert MaxMintAmount();

                uint256 mintedAmount_ = _mintedAmount[tokenId][_msgSender()];
                if (mintedAmount_ + quantity > mi.maxPerUser) revert MaxMintPerUser();

                _mintedAmount[tokenId][_msgSender()] = mintedAmount_ + quantity;
            }

            _totalSupply[tokenId] = totalSupply_ + quantity;
        }

        if(msg.value != totalMintPrice) revert InvalidETH();

        _mintBatch(to_, tokenIds_, quantities_, data_);

        if(treasury != address(0)) {
            payable(treasury).transfer(totalMintPrice);
        }
    }

    /**
     * @dev Get token uri by token id
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        return bytes(tokenURI).length > 0 ? tokenURI : super.uri(tokenId);
    }

    /**
     * @dev Set token uri by token id
     */
    function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner existTokenId(tokenId) {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Get token supply by token id
     */
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return _totalSupply[tokenId];
    }

    /**
     * @dev Get mint info of sub collection by token id
     */
    function mintInfo(uint256 tokenId) public view returns (MintInfo memory) {
        return _mintInfos[tokenId];
    }

    /**
     * @dev Set mint info of sub collection
     */
    function setMintInfo(
        uint256 tokenId_,
        bytes32 merkleRoot_,
        uint256 maxPerUser_,
        uint256 mintAmount_,
        uint256 mintPrice_
    ) external onlyOwner existTokenId(tokenId_) {
        _mintInfos[tokenId_] = MintInfo({merkleRoot: merkleRoot_, maxPerUser: maxPerUser_, mintAmount: mintAmount_});
        mintPrice[tokenId_] = mintPrice_;

        emit SetMintInfo(mintInfo(tokenId_), tokenId_);
    }

    /**
     * @dev Get the minted amount of user in sub collection.
     */
    function mintedAmountOf(address account, uint256 tokenId) external view returns (uint256) {
        return _mintedAmount[tokenId][account];
    }

    /**
     * @dev Set treasury.
     */
    function setTreasury(address _treasury) external onlyOwner {
        if(_treasury == address(0)) revert InvalidTreasury();
        treasury = _treasury;

        emit SetTreasury(_treasury);
    }

    // **********************  Pausable  **********************
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}