// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./Mint721AValidator.sol";
import "./ERC721AURIUpgradeable.sol";
import "./LibERC721AMint.sol";
import "./Royalty.sol";
import "./ERC721AEnumerableUpgradeableDedicated.sol";
import "./OwnablePausableUpgradeable.sol";

contract ERC721ARareCirclesUpgradeableDedicated is
ContextUpgradeable,
AccessControlUpgradeable,
UUPSUpgradeable,
OwnablePausableUpgradeable,
ERC721AUpgradeableDedicated,
Mint721AValidator,
ERC721AURIUpgradeable,
ERC721AEnumerableUpgradeableDedicated,
Royalty
{
    using SafeMathUpgradeable for uint256;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721A = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721A_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721A_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0x2a55205a; /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Max Supply
    uint256 private _maxSupply;

    // RareCircles Treasury
    address private _RCTreasury;

    // Merchant Treasury
    address private _merchantTreasury;

    /**
    * @dev Indicates that the contract has been setup after creation.
    */
    bool private _setup;

    // mint count event
    mapping(address => uint256) private _minterCount;
    uint256 private _mintLimit;
    mapping(address => bool) private _minterBlacklist;


    event CreateERC721ARareCircles(address indexed owner, string name, string symbol);
    event Payout(address indexed to, uint256 amount);
    event Fee(address indexed to, uint256 amount);
    event Mint(uint256 amount, address indexed to);
    event BaseURI(string uri);
    event PlaceholderHolderURI(string uri);
    event MerchantTreasury(address treasury);
    event RarecirclesTreasury(address treasury);
    event MaxSupply(uint256 maxSupply);
    event Name(string name);
    event Symbol(string symbol);

    function __ERC721ARareCircles_init(string memory _name, string memory _symbol, string memory _baseURI, string memory _placeholderURI) external virtual {
        __ERC721ARareCircles_init_unchained(_name, _symbol, _baseURI, _placeholderURI);

        emit CreateERC721ARareCircles(_msgSender(), _name, _symbol);
    }

    function __ERC721ARareCircles_init_unchained(string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _placeholderURI) internal initializer {
        _setBaseURI(_baseURI);
        _setPlaceholderURI(_placeholderURI);
        _setup = false;

        __Context_init_unchained();
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC721AURI_init_unchained();
        __Mint721AValidator_init_unchained();
        __ERC165_init_unchained();
        __ERC721A_init_unchained(_name, _symbol);
    }

    function _authorizeUpgrade(address) internal override onlyOperatorOrOwner {}

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721AUpgradeableDedicated, ERC721AEnumerableUpgradeableDedicated, AccessControlUpgradeable)
    returns (bool)
    {
        return
        interfaceId == _INTERFACE_ID_ERC165 ||
        interfaceId == _INTERFACE_ID_ERC721A ||
        interfaceId == _INTERFACE_ID_ERC721A_METADATA ||
        interfaceId == _INTERFACE_ID_ERC721A_ENUMERABLE ||
        interfaceId == _INTERFACE_ID_ROYALTIES ||
        AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    // Minting functions
    function mintAndTransfer(LibERC721AMint.Mint721AData memory data) public payable {
        // this is th perform calling mint, it may or may not match data.recipient
        address sender = _msgSender();

        require(data.fee <= msg.value, "ERC721: application fee must be less then or equal to ETH sent");
        // Mint Limit
        uint256 existingAmount = _minterCount[sender];
        if (data.limit > 0) {
            require(existingAmount + data.amount <= data.limit, "ERC721: can't exceed the limit");
        }
        require(data.amount > 0, "ERC721: can't mint 0 tokens");

        // We make sure that this has been signed by the contract owner
        bytes32 _hash = LibERC721AMint.hash(data);
        // validate(owner(), hash, data.signature);
        address signer = getValidator(_hash, data.signature);
        require(signer == owner() || hasRole(MINTER_ROLE, signer), "RC: signature verification error");

        require(msg.value == data.cost, "ERC721: insufficient amount");
        require(
            sender == data.recipient,
            "ERC721: transfer caller is not owner nor approved"
        );
        require(_mintLimit > 0 && data.amount <= (_mintLimit - _minterCount[data.recipient]), "ERC721: exceeded mint limit");
        require(!_minterBlacklist[sender], "ERC721: blacklisted");
        _mintTo(data.amount, data.recipient);

        uint256 payout = msg.value - data.fee;
        if (payout > 0 && _merchantTreasury != address(0)) {
            payable(_merchantTreasury).transfer(payout);
            emit Payout(_merchantTreasury, payout);
        }
        if (data.fee > 0 && _RCTreasury != address(0)) {
            payable(_RCTreasury).transfer(data.fee);
            emit Fee(_RCTreasury, data.fee);
        }
        _minterCount[sender] += data.amount;
    }

    function mintTo(uint256 _amount, address _to) public onlyMinterOrOwner {
        _mintTo(_amount, _to);
    }

    function _mintTo(uint256 _amount, address _to) internal whenNotPaused {
        // Max Supply
        if (_maxSupply > 0) {
            require(totalSupply() + _amount <= _maxSupply, "ERC721: can't exceed max supply");
        }
        _safeMint(_to, _amount);
        emit Mint(_amount, _to);
    }

    // RBAC
    function setMinter(address _minter) external onlyOwner {
        _setupRole(MINTER_ROLE, _minter);
    }

    function setOperator(address _operator) external onlyOwner {
        _setupRole(OPERATOR_ROLE, _operator);
    }

    // TokenURI
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721AUpgradeableDedicated, ERC721AURIUpgradeable)
    returns (string memory)
    {
        return ERC721AURIUpgradeable.tokenURI(tokenId);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
    public
    onlyOperatorOrOwner
    {
        return ERC721AURIUpgradeable._setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseTokenURI(string memory baseTokenURI_) public onlyOperatorOrOwner {
        _setBaseURI(baseTokenURI_);
        emit BaseURI(baseTokenURI_);
    }

    function baseTokenURI() public view returns (string memory) {
        return super.baseURI();
    }

    function setPlaceholderURI(string memory placeholderURI_) public onlyOperatorOrOwner {
        _setPlaceholderURI(placeholderURI_);
        emit PlaceholderHolderURI(placeholderURI_);
    }

    function placeholderURI() public view override returns (string memory) {
        return super.placeholderURI();
    }


    // Token Enumeration
    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokensOfOwner(address owner)
    public
    view
    virtual
    override
    returns (uint256[] memory)
    {
        return super.tokensOfOwner(owner);
    }

    function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return super.tokenByIndex(index);
    }

    // Royalty
    function setRoyalty(address creator_, uint256 amount_) public onlyOperatorOrOwner {
        _saveRoyalty(LibPart.Part(creator_, amount_));
    }

    // Supply
    function totalSupply()
    public
    view
    virtual
    override(ERC721AEnumerableUpgradeableDedicated, ERC721AUpgradeableDedicated)
    returns (uint256)
    {
        return ERC721AEnumerableUpgradeableDedicated.totalSupply();
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOperatorOrOwner {
        _maxSupply = maxSupply_;
        emit MaxSupply(maxSupply_);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    // Treasury
    function setMerchantTreasury(address treasury_) public onlyOperatorOrOwner {
        _merchantTreasury = treasury_;
        emit MerchantTreasury(treasury_);
    }

    function merchantTreasury() public view returns (address) {
        return _merchantTreasury;
    }

    function setRCTreasury(address treasury_) public onlyOperatorOrOwner {
        _RCTreasury = treasury_;
        emit RarecirclesTreasury(treasury_);
    }

    function RCTreasury() public view returns (address) {
        return _RCTreasury;
    }

    // Contract Basics
    function setName(string memory name_) public onlyOperatorOrOwner {
        _setName(name_);
        emit Name(name_);
    }

    function setSymbol(string memory symbol_) public onlyOperatorOrOwner {
        _setSymbol(symbol_);
        emit Symbol(symbol_);
    }

    function setMintLimit(uint256 limit_) public onlyOperatorOrOwner {
        _mintLimit = limit_;
    }

    function mintLimit() public view returns (uint256) {
        return _mintLimit;
    }

    function blacklist(address address_) public onlyOperatorOrOwner {
        _minterBlacklist[address_] = true;
    }

    function unblacklist(address address_) public onlyOperatorOrOwner {
        delete _minterBlacklist[address_];
    }

    function isBlacklisted(address address_) public view returns (bool) {
        return _minterBlacklist[address_];
    }

    function setup(address creator_, uint256 amount_, uint256 maxSupply_, address minter_, address operator_) public onlyOwner {
        require(!_setup, "ERC721: contract is already setup");
        _setup = true;
        _saveRoyalty(LibPart.Part(creator_, amount_));
        setMaxSupply(maxSupply_);
        _setupRole(MINTER_ROLE, minter_);
        _setupRole(OPERATOR_ROLE, operator_);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721AUpgradeableDedicated, ERC721AEnumerableUpgradeableDedicated) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    modifier onlyMinterOrOwner() {
        require(hasRole(MINTER_ROLE, _msgSender()) || owner() == _msgSender(), "ERC721: Caller is not a minter nor owner");
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(hasRole(OPERATOR_ROLE, _msgSender()) || owner() == _msgSender(), "ERC721: Caller is not a operator nor owner");
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}