// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IERC4906.sol";
import "./IFirstOwnerProof.sol";

contract BaseSBT is ERC721Enumerable, IERC4906, IFirstOwnerProof, Ownable {
    bytes4 internal constant ERC4906_INTERFACE_ID = 0x49064906;

    using Strings for uint256;

    // indicate to OpenSea that an NFT's metadata is frozen
    event PermanentURI(string uri, uint256 indexed tokenID);

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    string internal _baseTokenURI;
    mapping(uint256 tokenID => string uri) internal _tokenURIs;
    mapping(uint256 tokenID => bool isFrozen) internal _isTokenURIFrozens;

    mapping(uint256 tokenID => uint256 tokenType) internal _tokenTypes;
    mapping(uint256 tokenType => uint256 supply) internal _typeSupplies;
    mapping(address owner => mapping(uint256 tokenType => uint256 balance))
        internal _typeBalances;

    mapping(uint256 tokenID => uint256 holdingStartedAt)
        internal _holdingStarteds;

    mapping(address minter => bool isMinter) internal _minters;
    bool internal _isMintersFrozen;

    modifier onlyMinter() {
        require(_minters[msg.sender], "BaseSBT: caller is not a minter");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function supportsInterface(
        bytes4 interfaceID_
    ) public view override returns (bool) {
        return
            interfaceID_ == ERC4906_INTERFACE_ID ||
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
            "BaseSBT: address zero is not a valid owner"
        );

        return _typeBalances[owner_][tokenType_];
    }

    function holdingPeriod(uint256 tokenID_) external view returns (uint256) {
        _requireMinted(tokenID_);

        return block.timestamp - _holdingStarteds[tokenID_];
    }

    function airdrop(
        address to_,
        uint256 tokenID_,
        uint256 tokenType_
    ) external onlyMinter {
        _mint(to_, tokenID_, tokenType_);
    }

    function burn(uint256 tokenID_) external {
        _requireApprovedOrOwner(msg.sender, tokenID_);

        _burn(tokenID_);
    }

    function addMinter(address minter_) external onlyOwner {
        _requireMintersNotFrozen();

        require(
            minter_ != address(0),
            "BaseSBT: new minter is the zero address"
        );
        require(!_minters[minter_], "BaseSBT: already added");

        _minters[minter_] = true;

        emit MinterAdded(minter_);
    }

    function isMinter(address minter_) external view returns (bool) {
        return _minters[minter_];
    }

    function removeMinter(address minter_) external onlyOwner {
        _requireMintersNotFrozen();

        require(_minters[minter_], "BaseSBT: already removed");

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
            "BaseSBT: caller is not token owner nor approved"
        );
    }

    function _requireTokenURINotFrozen(uint256 tokenID_) internal view {
        require(!_isTokenURIFrozens[tokenID_], "BaseSBT: token URI frozen");
    }

    function _requireMintersNotFrozen() internal view {
        require(!_isMintersFrozen, "BaseSBT: minters frozen");
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

        _holdingStarteds[tokenID_] = block.timestamp;

        emit MetadataUpdate(tokenID_);
    }

    function _burn(uint256 tokenID_) internal override {
        address owner = ownerOf(tokenID_);
        uint256 tokenType_ = _tokenTypes[tokenID_];

        super._burn(tokenID_);

        if (bytes(_tokenURIs[tokenID_]).length > 0) {
            delete _tokenURIs[tokenID_];
        }

        delete _tokenTypes[tokenID_];
        _typeSupplies[tokenType_]--;
        _typeBalances[owner][tokenType_]--;

        delete _holdingStarteds[tokenID_];

        emit MetadataUpdate(tokenID_);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenID_,
        uint256 batchSize_
    ) internal override {
        require(from_ == address(0) || to_ == address(0), "BaseSBT: soulbound");

        super._beforeTokenTransfer(from_, to_, firstTokenID_, batchSize_);
    }
}