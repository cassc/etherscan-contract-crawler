// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IERC4906.sol";
import "./IERC4907.sol";
import "./IFirstOwnerProof.sol";

contract BaseNFT is ERC721Enumerable, ERC2981, IERC4906, IERC4907, Ownable {
    bytes4 internal constant ERC4906_INTERFACE_ID = 0x49064906;

    using Strings for uint256;

    struct UserInfo {
        address user;
        uint64 expires;
    }

    // indicate to OpenSea that an NFT's metadata is frozen
    event PermanentURI(string uri, uint256 indexed tokenID);

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    IFirstOwnerProof internal immutable _firstOwnerProof;

    string internal _baseTokenURI;
    mapping(uint256 tokenID => string uri) internal _tokenURIs;
    mapping(uint256 tokenID => bool isFrozen) internal _isTokenURIFrozens;

    mapping(uint256 tokenID => uint256 tokenType) internal _tokenTypes;
    mapping(uint256 tokenType => uint256 supply) internal _typeSupplies;
    mapping(address owner => mapping(uint256 tokenType => uint256 balance))
        internal _typeBalances;

    mapping(uint256 tokenID => uint256 holdingStartedAt)
        internal _holdingStarteds;
    mapping(uint256 tokenID => address firstOwner) internal _firstOwners;

    bool internal _isRoyaltyFrozen;

    mapping(uint256 tokenID => UserInfo userInfo) internal _users;

    mapping(address minter => bool isMinter) internal _minters;
    bool internal _isMintersFrozen;

    modifier onlyMinter() {
        require(_minters[msg.sender], "BaseNFT: caller is not a minter");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address firstOwnerProof_
    ) ERC721(name_, symbol_) {
        _firstOwnerProof = IFirstOwnerProof(firstOwnerProof_);
        _setDefaultRoyalty(owner(), 0);
    }

    function firstOwnerProof() external view returns (address) {
        return address(_firstOwnerProof);
    }

    function supportsInterface(
        bytes4 interfaceID_
    ) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return
            interfaceID_ == ERC4906_INTERFACE_ID ||
            interfaceID_ == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceID_);
    }

    function tokenURI(
        uint256 tokenID_
    ) public view override returns (string memory) {
        _requireMinted(tokenID_);

        string memory uri = _tokenURIs[tokenID_];

        if (bytes(uri).length > 0) {
            return uri;
        }

        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        _tokenTypes[tokenID_].toString(),
                        "/",
                        tokenID_.toString()
                    )
                )
                : "";
    }

    function setTokenURI(
        uint256 tokenID_,
        string calldata uri_
    ) external onlyOwner {
        _requireMinted(tokenID_);
        _requireTokenURINotFrozen(tokenID_);

        _tokenURIs[tokenID_] = uri_;

        emit MetadataUpdate(tokenID_);
    }

    function freezeTokenURI(uint256 tokenID_) external onlyOwner {
        _requireMinted(tokenID_);
        _requireTokenURINotFrozen(tokenID_);

        _isTokenURIFrozens[tokenID_] = true;

        emit PermanentURI(_tokenURIs[tokenID_], tokenID_);
    }

    function tokenType(uint256 tokenID_) external view returns (uint256) {
        _requireMinted(tokenID_);

        return _tokenTypes[tokenID_];
    }

    function typeSupply(uint256 tokenType_) external view returns (uint256) {
        return _typeSupplies[tokenType_];
    }

    function typeBalanceOf(
        address owner_,
        uint256 tokenType_
    ) external view returns (uint256) {
        require(
            owner_ != address(0),
            "BaseNFT: address zero is not a valid owner"
        );

        return _typeBalances[owner_][tokenType_];
    }

    function firstOwnerOf(uint256 tokenID_) external view returns (address) {
        address firstOwner = _firstOwners[tokenID_];

        require(firstOwner != address(0), "BaseNFT: invalid token ID");

        return firstOwner;
    }

    function holdingPeriod(uint256 tokenID_) external view returns (uint256) {
        _requireMinted(tokenID_);

        return block.timestamp - _holdingStarteds[tokenID_];
    }

    function royaltyInfo(
        uint256 tokenID_,
        uint256 salePrice_
    ) public view override returns (address, uint256) {
        _requireMinted(tokenID_);

        return super.royaltyInfo(tokenID_, salePrice_);
    }

    function setDefaultRoyalty(
        address receiver_,
        uint96 feeNumerator_
    ) external onlyOwner {
        _requireRoyaltyNotFrozen();

        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function freezeRoyalty() external onlyOwner {
        _requireRoyaltyNotFrozen();

        _isRoyaltyFrozen = true;
    }

    function setUser(
        uint256 tokenID_,
        address user_,
        uint64 expires_
    ) external {
        _requireApprovedOrOwner(msg.sender, tokenID_);

        UserInfo storage userInfo = _users[tokenID_];
        userInfo.user = user_;
        userInfo.expires = expires_;

        emit UpdateUser(tokenID_, user_, expires_);
    }

    function userOf(uint256 tokenID_) external view returns (address) {
        _requireMinted(tokenID_);

        if (block.timestamp >= uint256(_users[tokenID_].expires)) {
            return address(0);
        }

        return _users[tokenID_].user;
    }

    function userExpires(uint256 tokenID_) external view returns (uint256) {
        _requireMinted(tokenID_);

        return _users[tokenID_].expires;
    }

    function addMinter(address minter_) external onlyOwner {
        _requireMintersNotFrozen();

        require(
            minter_ != address(0),
            "BaseNFT: new minter is the zero address"
        );
        require(!_minters[minter_], "BaseNFT: already added");

        _minters[minter_] = true;

        emit MinterAdded(minter_);
    }

    function isMinter(address minter_) external view returns (bool) {
        return _minters[minter_];
    }

    function removeMinter(address minter_) external onlyOwner {
        _requireMintersNotFrozen();

        require(_minters[minter_], "BaseNFT: already removed");

        delete _minters[minter_];

        emit MinterRemoved(minter_);
    }

    function freezeMinters() external onlyOwner {
        _requireMintersNotFrozen();

        _isMintersFrozen = true;
    }

    function _requireApprovedOrOwner(
        address spender_,
        uint256 tokenID_
    ) internal view {
        require(
            _isApprovedOrOwner(spender_, tokenID_),
            "BaseNFT: caller is not token owner nor approved"
        );
    }

    function _requireTokenURINotFrozen(uint256 tokenID_) internal view {
        require(!_isTokenURIFrozens[tokenID_], "BaseNFT: token URI frozen");
    }

    function _requireRoyaltyNotFrozen() internal view {
        require(!_isRoyaltyFrozen, "BaseNFT: royalty frozen");
    }

    function _requireMintersNotFrozen() internal view {
        require(!_isMintersFrozen, "BaseNFT: minters frozen");
    }

    function _mint(address to_, uint256 tokenID_, uint256 tokenType_) internal {
        _tokenTypes[tokenID_] = tokenType_;

        _mint(to_, tokenID_);
    }

    function _mint(address to_, uint256 tokenID_) internal override {
        uint256 tokenType_ = _tokenTypes[tokenID_];

        super._mint(to_, tokenID_);

        _typeSupplies[tokenType_]++;
        _typeBalances[to_][tokenType_]++;

        _firstOwners[tokenID_] = to_;
        _firstOwnerProof.airdrop(to_, tokenID_, tokenType_);

        emit MetadataUpdate(tokenID_);
    }

    function _burn(uint256 tokenID_) internal override {
        address owner_ = ownerOf(tokenID_);
        uint256 tokenType_ = _tokenTypes[tokenID_];

        super._burn(tokenID_);

        if (bytes(_tokenURIs[tokenID_]).length > 0) {
            delete _tokenURIs[tokenID_];
        }

        delete _tokenTypes[tokenID_];
        _typeSupplies[tokenType_]--;
        _typeBalances[owner_][tokenType_]--;

        _resetTokenRoyalty(tokenID_);

        emit MetadataUpdate(tokenID_);
    }

    function _transfer(
        address from_,
        address to_,
        uint256 tokenID_
    ) internal override {
        uint256 tokenType_ = _tokenTypes[tokenID_];

        super._transfer(from_, to_, tokenID_);

        _typeBalances[from_][tokenType_]--;
        _typeBalances[to_][tokenType_]++;
    }

    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenID_,
        uint256 batchSize_
    ) internal override {
        super._afterTokenTransfer(from_, to_, firstTokenID_, batchSize_);

        if (from_ != to_) {
            if (to_ == address(0)) {
                delete _holdingStarteds[firstTokenID_];
            } else {
                _holdingStarteds[firstTokenID_] = block.timestamp;
            }

            if (_users[firstTokenID_].user != address(0)) {
                delete _users[firstTokenID_];

                emit UpdateUser(firstTokenID_, address(0), 0);
            }
        }
    }
}