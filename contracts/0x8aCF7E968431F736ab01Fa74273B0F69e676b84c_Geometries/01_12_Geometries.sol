// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "erc721a/contracts/ERC721A.sol";

import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/extension/Royalty.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/**
 * @title Geometries contract
 *
 * @notice Smart Contract provides ERC721 functionality with public and private sales options.
 */
contract Geometries is Ownable, Royalty, ERC721A {
    // Use safeMath library for doing arithmetic with uint256 and uint8 numbers
    using SafeMath for uint256;
    using SafeMath for uint8;

    // Use String library for string formatting
    using Strings for uint256;

    // Artwork data type with fixed geometry and edition numbers
    struct Artwork {
        uint256 geometry ;
        uint256 edition;
    }

    // max edition for every Geometries
    uint256 constant maxEdition = 100;

    // geometriesCount maximum available Geometry of Collection
    uint256 constant geometriesCount = 22;

    // geometriesCount maximum available Geometry for Public and Private sales
    uint256 constant geometriesForSale = 20;

    // permanent royalty BPS value for collection
    uint256 constant royaltyBPS = 10_00;

    // price of a single token in wei
    uint256 private _artworkPrice;

    // address to withdraw funds from contract
    address payable private _withdrawAddress;

    // base uri for token metadata
    string private _baseTokenURI;

    // is collection is freeze
    bool private freeze;

    // private sale current status - active or not
    bool private _privateSale;

    // public sale current status - active or not
    bool private _publicSale;

    // maximum available editions limit for sale
    uint256 private _maxSaleEdition;

    // Allowlisted addresses that can participate in the
    // private sale event and how many tokens could be minted for this address
    mapping(address => uint8) private _allowList;

    // geometry => already minted editions for geometry
    mapping(uint256 => uint256) private _geometriesEditions;

    // tokenID => Artwork data mapping
    mapping(uint256 => Artwork) private _artworkEditions;

    // mapping denyListed operators (marketplaces, wallets, etc...)
    mapping(address => bool) private _operatorsDenyList;

    // event that emits when private sale changes state
    event privateSaleState(bool active);

    // event that emits when public sale changes state
    event publicSaleState(bool active);

    /**
     * @dev Emitted when `tokenId` token with specific `edition` and `geometry` is minted to `to`.
     */
    event Minted(address indexed to, uint256 indexed tokenId, uint256 geometry, uint256 edition);

    /**
     * @dev contract constructor
     *
     * @param name is contract name
     * @param symbol is contract basic symbol
     * @param baseTokenURI is base (default) tokenURI with metadata
     * @param artworkPrice is a price for single artwork
     * @param withDrawAddress is a recipient address for sales and royalty
     * @param maxSaleEditions maximum available editions limit for sale
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 artworkPrice,
        address payable withDrawAddress,
        uint256 maxSaleEditions
    ) ERC721A(name,symbol) {
        _setupOwner(msg.sender);
        _withdrawAddress = withDrawAddress;
        _baseTokenURI = baseTokenURI;
        _artworkPrice = artworkPrice;
        _maxSaleEdition = maxSaleEditions;

        _setupDefaultRoyaltyInfo(withDrawAddress, royaltyBPS);
    }

    /**
     * @dev set price for one token
     *
     * @param price is a new price for token
     */
    function setArtworkPrice(uint256 price) external onlyOwner {
        require(!freeze, "Collection is frozen!");
        require(!_privateSale, "Private sale is active!");
        require(!_publicSale, "Public sale is active!");

        _artworkPrice = price;
    }

    /**
      * @dev check if collection is freeze now
      *
      * @return bool if collection is freeze
      */
    function isCollectionFreeze() public view virtual returns (bool) {
        return freeze;
    }

    /**
     * @dev freeze collection
     */
    function freezeCollection() external onlyOwner {
        require(!_privateSale, "Private sale is active!");
        require(!_publicSale, "Public sale is active!");

        freeze = true;
    }

    /**
     * @dev set new _baseTokenURI for collection
       */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!freeze, "Collection is frozen!");

        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev check if private sale is active now
     *
     * @return bool if private sale active
     */
    function isPrivateSaleActive() public view virtual returns (bool) {
        return _privateSale;
    }

    /**
     * @dev check if public sale is active now
     *
     * @return bool if public sale active
     */
    function isPublicSaleActive() public view virtual returns (bool) {
        return _publicSale;
    }

    /**
     * @dev switch private sale state
     */
    function flipPrivateSaleState() external onlyOwner {
        require(!freeze, "Collection is frozen!");
        require(!_publicSale, "Public sale is active!");

        _privateSale = !_privateSale;
        emit privateSaleState(_privateSale);
    }

    /**
     * @dev switch public sale state
     */
    function flipPublicSaleState() external onlyOwner {
        require(!freeze, "Collection is frozen!");
        require(!_privateSale, "Private sale is active!");

        _publicSale = !_publicSale;
        emit publicSaleState(_publicSale);
    }

    /**
     * @dev show maximum available edition for sale
     *
     * @return uint of maximum available edition for sale
     */
    function maxSaleEdition() public view virtual returns (uint256) {
        return _maxSaleEdition;
    }

    /**
     * @dev set maximum available edition for sale
     */
    function setMaxSaleEdition(uint256 maxSaleEditions) external onlyOwner {
        require(!freeze, "Collection is frozen!");
        _maxSaleEdition = maxSaleEditions;
    }

    /**
     * @dev set new withdraw address
     */
    function setWithdrawAddress(address payable withdrawAddress) external onlyOwner {
        _withdrawAddress = withdrawAddress;
    }

    /**
     * @dev add ETH addresses to allowlist
     *
     * Requirements:
     * - private sale must be inactive
     *
     * @param addresses address[] array of ETH addresses that need to be Allowlisted
     */
    function addAllowlistAddresses(address[] calldata addresses) external onlyOwner {
        require(!_privateSale, "Private sale is now running!!!");
        require(!freeze, "Collection is frozen!");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] != address(0)) {
                _allowList[addresses[i]] = 1;
            }
        }
    }

    /**
      * @dev remove ETH addresses from allowlist
      *
      * Requirements:
      * - private sale must be inactive
      *
      * @param addresses address[] array of ETH addresses that need to be removed from allowlist
      */
    function removeAllowlistAddresses(address[] calldata addresses) external onlyOwner {
        require(!_privateSale, "Private sale is now running!!!");
        require(!freeze, "Collection is frozen!");

        for (uint256 i = 0; i < addresses.length; i++) {
            delete _allowList[addresses[i]];
        }
    }

    /**
     * @dev check if address Allowlisted
     *
     * @param _address address ETH address to check
     * @return bool allowlist status
     */
    function isAllowlisted(address _address) public view returns (bool) {
        return _allowList[_address] > 0
        ? true
        : false;
    }

    /**
     * @dev add ETH operator addresses to denyList
     *
     *
     * @param operators address[] array of ETH operators addresses that need to be DenyListed
     */
    function addDenyListOperators(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] != address(0)) {
                _operatorsDenyList[operators[i]] = true;
            }
        }
    }

    /**
      * @dev remove ETH operator addresses from denyList
      *
      *
      * @param operators address[] array of ETH operators addresses that need to be removed from DenyListed
      */
    function removeDenyListOperators(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            delete _operatorsDenyList[operators[i]];
        }
    }

    /**
     * @dev check if operator address DenyListed
     *
     * @param _operator address ETH operator address to check
     * @return bool DenyListed status
     */
    function isDenyListed(address _operator) public view returns (bool) {
        return _operatorsDenyList[_operator];
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `to` address must be not DenyListed.
     * - `tokenId` must exist.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require(!isDenyListed(to), "Operator address DenyListed!");
        super.approve(to, tokenId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - `operator` address must be not DenyListed.
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(!isDenyListed(operator), "Operator address DenyListed!");

        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev mint new Artwork to sender on public sale
     *
     * @param geometry selected Geometry by user
     */
    function mint(uint256 geometry) public payable {
        require(_publicSale || _privateSale, "publicSale or privateSale must be active!");
        require(geometry <= geometriesForSale, "Geometry should less than maximum available Geometry for sale!");
        require(_artworkPrice == msg.value, "Ether value sent is not correct!");

        if (_privateSale) {
            require(_allowList[msg.sender] > 0, "Address not Allowlisted or sender private sale limit have reached!");
            _allowList[msg.sender] = uint8(_allowList[msg.sender].sub(1));
        }

        _mintTo(geometry, msg.sender);

        payable(_withdrawAddress).transfer(msg.value);
    }

    /**
     * @dev mint new Artwork to address
     *
     * @param geometry selected Geometry by user
     * @param to mint Artwork to provided address
     */
    function mintTo(uint256 geometry, address to) external onlyOwner {
        require(geometry <= geometriesCount, "Geometry should less than maximum available Geometry!");

        if (_privateSale) {
            require(_allowList[to] > 0, "Address not Allowlisted or sender private sale limit have reached!");
            _allowList[to] = uint8(_allowList[to].sub(1));
        }

        _mintTo(geometry, to);
    }

    /**
     * @dev mint new Artwork to address
     *
     * @param geometry selected Geometry by user
     * @param to mint Artwork to provided address
     */
    function _mintTo(uint256 geometry, address to) internal {
        require(!freeze, "Collection is frozen!");
        require(geometry > 0, "Geometry should not be 0!");
        require(_geometriesEditions[geometry].add(1) <= maxEdition, "Geometry has already maximum numbers of editions!");
        require(_geometriesEditions[geometry].add(1) <= _maxSaleEdition, "Maximum editions for this sale state reached!");

        _safeMint(to, 1);

        _artworkEditions[_nextTokenId().sub(1)] = Artwork({ geometry: geometry, edition: _geometriesEditions[geometry].add(1) });
        _geometriesEditions[geometry] = _geometriesEditions[geometry].add(1);

        emit Minted(to, _nextTokenId().sub(1), geometry, _geometriesEditions[geometry]);
    }

    /**
     * @dev mint every Geometry edition to address
     *
     * @param to mint Collection to provided address
     */
    function mintCollectionTo(address to) external onlyOwner {
        require(!freeze, "Collection is frozen!");
        require(!_publicSale, "Public sale is active!");
        require(!_privateSale, "Private sale is active!");

        uint256 startIndex = _nextTokenId();

        _safeMint(to , geometriesCount);

        for (uint256 g = 1; g <= geometriesCount; g++) {

            _artworkEditions[startIndex] = Artwork({ geometry: g, edition: _geometriesEditions[g].add(1) });
            _geometriesEditions[g] = _geometriesEditions[g].add(1);

            emit Minted(to, startIndex, g, _geometriesEditions[g]);

            startIndex = startIndex.add(1);
        }
    }

    /**
     *  @dev Returns the URI for a given tokenId.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenMetadataIndex(_tokenId)))) : '';
    }

    /**
     * @dev Return Geometry number for provided tokenID
     */
    function tokenGeometry(uint256 tokenId) public view returns (uint256) {
        return _artworkEditions[tokenId].geometry;
    }

    /**
     * @dev Return Edition number for provided tokenID
     */
    function tokenEdition(uint256 tokenId) public view returns (uint256) {
        return _artworkEditions[tokenId].edition;
    }

    /**
     *  @dev return Metadata index for provided tokenID
     */
    function tokenMetadataIndex(uint256 tokenId) internal view returns (uint256) {
        return tokenGeometry(tokenId).sub(1).mul(maxEdition).add(tokenEdition(tokenId));
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns whether owner can be set in the given execution context.
     */
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev This function returns who is authorized to set royalty info for contract.
     */
    function _canSetRoyaltyInfo() internal view virtual override returns(bool){
        return msg.sender == owner();
    }

    /**
     * @dev See ERC 165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool) {
            return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId;
    }
}