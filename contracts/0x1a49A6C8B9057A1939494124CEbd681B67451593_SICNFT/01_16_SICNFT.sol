//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view
      returns (address receiver, uint256 royaltyAmount);
}

contract SICNFT is
    ERC721A,
    Ownable,
    Pausable,
    PaymentSplitter,
    IERC2981
{
    /******************************************************
     ***************** ENUMS & CONSTANTS ******************
     ******************************************************/

    enum Stage {
        Initial,
        Presale,
        Public
    }

    uint256 public constant PRESALE_PRICE = 0.25 ether;
    uint256 public constant PUBLIC_PRICE = 0.3 ether;

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_PRESALE_SUPPLY = 500;

    uint256 public constant MAX_TOKENS_PER_ADDRESS_PRESALE = 3;
    uint256 public constant MAX_TOKENS_PER_ADDRESS_PUBLIC = 2;

    /******************************************************
     *********************** STATE ************************
     ******************************************************/

    Stage public stage = Stage.Initial;
    bytes32 public whitelistMerkleRoot;
    string public baseURI;
    uint256 public royaltyAmount; // range: [0 - 10000]

    /******************************************************
     ********************** EVENTS ************************
     ******************************************************/

    event PresaleStarted();
    event PublicSaleStarted();

    /******************************************************
     ******************** CONSTRUCTOR *********************
     ******************************************************/

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        bytes32 _whitelistMerkleRoot,
        string memory _initialBaseURI,
        uint64 _initialRoyaltyAmount
    ) ERC721A("Secret Island Club", "SIC") PaymentSplitter(_payees, _shares) {
        whitelistMerkleRoot = _whitelistMerkleRoot;
        baseURI = _initialBaseURI;
        royaltyAmount = _initialRoyaltyAmount;
    }

    /******************************************************
     ********************** MINTING ***********************
     ******************************************************/

    function mintPresale(
        address _to,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        whenNotPaused
        duringPresale
        isValidAddress(_to)
        isOnWhitelist(_to, _merkleProof, whitelistMerkleRoot)
        canAnyoneMintQuantity(_quantity, MAX_PRESALE_SUPPLY)
        canOwnerMintQuantityPresale(_to, _quantity)
        isCorrectPayment(PRESALE_PRICE, _quantity)
    {
        _safeMint(_to, _quantity);
        _incrementPresaleSlotsUsed(_to, _quantity);
    }

    function mintPublic(address _to, uint256 _quantity)
        external
        payable
        whenNotPaused
        duringPublicSale
        isValidAddress(_to)
        canAnyoneMintQuantity(_quantity, MAX_SUPPLY)
        canOwnerMintQuantityPublic(_to, _quantity)
        isCorrectPayment(PUBLIC_PRICE, _quantity)
    {
        _safeMint(_to, _quantity);
        _incrementPublicSlotsUsed(_to, _quantity);
    }

    /*******************************************************
     ********************* ADMINISTRATION ******************
     *******************************************************/

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
        beforePresale
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function startPresale() public onlyOwner beforePresale {
        stage = Stage.Presale;
        emit PresaleStarted();
    }

    function startPublicSale() public onlyOwner duringPresale {
        stage = Stage.Public;
        emit PublicSaleStarted();
    }

    function setBaseURI(string calldata _newBaseURI) public onlyOwner beforePresale {
        baseURI = _newBaseURI;
    }

    function setRoyaltyAmount(uint256 _newRoyaltyAmount) public onlyOwner {
        royaltyAmount = _newRoyaltyAmount;
    }

    /*******************************************************
     *********************** OWNABLE ***********************
     *******************************************************/

    function renounceOwnership() public view override onlyOwner {
        revert("Disabled");
    }

    /*******************************************************
     *********************** ERC165 ************************
     *******************************************************/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /*******************************************************
     ***************** Royalty (ERC2981) *******************
     *******************************************************/

    function royaltyInfo(uint256, uint256 _price) external view returns (address, uint256) {
        uint256 royalty = (_price * royaltyAmount) / 10000;
        return (address(this), royalty);
    }

    /*******************************************************
     * Delegators for ERC721A internal read-only functions *
     *******************************************************/

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /*******************************************************
     ******** ERC721A AddressData.aux - mint slots *********
     *******************************************************/

    function getPresaleSlotsUsed(address _owner) public view returns (uint32) {
        uint64 aux = _getAux(_owner);
        (uint32 presaleSlotsUsed, ) = unpack64(aux);
        return presaleSlotsUsed;
    }

    function _incrementPresaleSlotsUsed(address _owner, uint256 _quantity) internal {
        uint64 aux = _getAux(_owner);
        (uint32 presaleSlotsUsed, uint32 publicSlotsUsed) = unpack64(aux);
        uint64 auxUpdated = pack64(presaleSlotsUsed + uint32(_quantity), publicSlotsUsed);
        _setAux(_owner, auxUpdated);
    }

    function getPublicSlotsUsed(address _owner) public view returns (uint32) {
        uint64 aux = _getAux(_owner);
        (, uint32 publicSlotsUsed) = unpack64(aux);
        return publicSlotsUsed;
    }

    function _incrementPublicSlotsUsed(address _owner, uint256 _quantity) internal {
        uint64 aux = _getAux(_owner);
        (uint32 presaleSlotsUsed, uint32 publicSlotsUsed) = unpack64(aux);
        uint64 auxUpdated = pack64(presaleSlotsUsed, publicSlotsUsed + uint32(_quantity));
        _setAux(_owner, auxUpdated);
    }

    /*******************************************************
     ********************* Token metadata ******************
     *******************************************************/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /******************************************************
     ********************* MODIFIERS **********************
     ******************************************************/

    modifier beforePresale() {
        require(stage == Stage.Initial, "Only before presale");
        _;
    }

    modifier duringPresale() {
        require(stage == Stage.Presale, "Only during presale");
        _;
    }

    modifier duringPublicSale() {
        require(stage == Stage.Public, "Only after presale");
        _;
    }

    modifier isOnWhitelist(
        address _address,
        bytes32[] calldata _merkleProof,
        bytes32 _root
    ) {
        require(
            MerkleProof.verify(
                _merkleProof,
                _root,
                keccak256(abi.encodePacked(_address))
            ),
            "Address not on whitelist"
        );
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0), "No zero address");
        _;
    }

    modifier isCorrectPayment(uint256 _price, uint256 _quantity) {
        require(_price * _quantity == msg.value, "Incorrect ETH value sent");
        _;
    }

    modifier canAnyoneMintQuantity(
        uint256 _quantity,
        uint256 _maxSupply
    ) {
        require(_quantity > 0, "Quantity value must be positive");
        require(
            totalSupply() + _quantity <= _maxSupply,
            "Quantity would exceed max supply"
        );
        _;
    }

    modifier canOwnerMintQuantityPresale(
        address _owner,
        uint256 _quantity
    ) {
        require(
            getPresaleSlotsUsed(_owner) + _quantity <= MAX_TOKENS_PER_ADDRESS_PRESALE,
            "Maximum tokens per address"
        );
        _;
    }

    modifier canOwnerMintQuantityPublic(
        address _owner,
        uint256 _quantity
    ) {
        require(
            getPublicSlotsUsed(_owner) + _quantity <= MAX_TOKENS_PER_ADDRESS_PUBLIC,
            "Maximum tokens per address"
        );
        _;
    }

    /******************************************************
     *********************** UTILS ************************
     ******************************************************/

    function pack64(uint32 a, uint32 b) public pure returns (uint64) {
        return uint64 (uint64(a) << 32 | uint64 (b));
    }

    function unpack64(uint64 x) public pure returns (uint32, uint32) {
        return (uint32 (uint64 (x >> 32)), uint32 (uint64 (x)));
    }

}