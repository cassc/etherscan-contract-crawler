//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ERC721A.sol";

contract DoodleRooms is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private baseURI;
    string public verificationHash;
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;
    bool public isPublicSaleActive;

    uint256 public constant MAX_DOODLE_ROOMS_PER_TX = 5;
    uint256 public constant MAX_PRESALE_DOODLE_ROOMS_PER_WALLET = 5;
    uint256 public constant MAX_OG_DOODLE_ROOMS_PER_WALLET = 10;
    uint256 public constant DOODLE_ROOMS_SUPPLY = 9999;

    uint256 public constant DOODLE_ROOM_PRICE = 0.02 ether;
    uint256 public constant THREE_DOODLE_ROOMS_PRICE = 0.05 ether;
    uint256 public constant FIVE_DOODLE_ROOMS_PRICE = 0.06 ether;
    uint256 public constant TEN_DOODLE_ROOMS_PRICE = 0.12 ether;
    uint256 public constant MAX_GIFTED_DOODLE_ROOMS = 100;

    address public shareOneAddress;
    address public shareTwoAddress;

    uint256 public maxOGSaleDoodleRooms;
    bytes32 public ogSaleMerkleRoot;
    bool public isOGSaleActive;

    uint256 public maxPresaleDoodleRooms;
    bytes32 public presaleMerkleRoot;
    bool public isPresaleActive;

    uint256 public numGiftedDoodleRooms;
    bytes32 public claimListMerkleRoot;

    mapping(address => uint256) public presaleMintCounts;
    mapping(address => uint256) public ogSaleMintCounts;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier presaleActive() {
        require(isPresaleActive, "Public presale sale is not open");
        _;
    }

    modifier ogSaleActive() {
        require(isOGSaleActive, "OG presale is not open");
        _;
    }

    modifier canMintDoodleRooms(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <=
            DOODLE_ROOMS_SUPPLY - MAX_GIFTED_DOODLE_ROOMS,
            "Not enough DoodleRooms remaining to mint"
        );
        _;
    }

    modifier canGiftDoodleRooms(uint256 num) {
        require(
            numGiftedDoodleRooms + num <= MAX_GIFTED_DOODLE_ROOMS,
            "Not enough DoodleRooms remaining to gift"
        );
        require(
            totalSupply() + num <= DOODLE_ROOMS_SUPPLY,
            "Not enough DoodleRooms remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 numberOfTokens) {
        require(
            (numberOfTokens == 3 ? THREE_DOODLE_ROOMS_PRICE :
            numberOfTokens == 5 ? FIVE_DOODLE_ROOMS_PRICE :
            numberOfTokens == 10 ? TEN_DOODLE_ROOMS_PRICE :
            DOODLE_ROOM_PRICE * numberOfTokens) == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in the list"
        );
        _;
    }

    constructor(
        address _openSeaProxyRegistryAddress,
        uint256 _maxPresaleDoodleRooms,
        bytes32 _presaleMerkleRoot,

        uint256 _maxOGDoodleRooms,
        bytes32 _ogPresaleMerkleRoot,
        address _shareOneAddress,
        address _shareTwoAddress
    ) ERC721A("Doodle Rooms", "DR", 10) {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxPresaleDoodleRooms = _maxPresaleDoodleRooms;
        presaleMerkleRoot = _presaleMerkleRoot;
        ogSaleMerkleRoot = _ogPresaleMerkleRoot;
        maxOGSaleDoodleRooms = _maxOGDoodleRooms;

        shareOneAddress = _shareOneAddress;
        shareTwoAddress = _shareTwoAddress;

        baseURI = "ipfs://QmXQzSvUhxk6F7na1P9ocUttyFCqA8QRg5LV9iURUJMqvp";
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    publicSaleActive
    isCorrectPayment(numberOfTokens)
    canMintDoodleRooms(numberOfTokens)
    {
        require(numberOfTokens <= MAX_DOODLE_ROOMS_PER_TX, "Max mint of Doodle Rooms per tx is five");

        _safeMint(msg.sender, numberOfTokens);
    }

    function mintPresale(
        uint256 numberOfTokens,
        bytes32[] calldata merkleProof
    )
    external
    payable
    nonReentrant
    presaleActive
    canMintDoodleRooms(numberOfTokens)
    isCorrectPayment(numberOfTokens)
    isValidMerkleProof(merkleProof, presaleMerkleRoot)
    {
        uint256 numAlreadyMinted = presaleMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_PRESALE_DOODLE_ROOMS_PER_WALLET,
            "Max DoodleRooms to mint in presale is five"
        );

        require(
            totalSupply() + numberOfTokens <= maxPresaleDoodleRooms,
            "Not enough DoodleRooms remaining to mint"
        );

        presaleMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function mintOGSale(
        uint256 numberOfTokens,
        bytes32[] calldata merkleProof
    )
    external
    payable
    nonReentrant
    ogSaleActive
    canMintDoodleRooms(numberOfTokens)
    isCorrectPayment(numberOfTokens)
    isValidMerkleProof(merkleProof, ogSaleMerkleRoot)
    {
        uint256 numAlreadyMinted = ogSaleMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_OG_DOODLE_ROOMS_PER_WALLET,
            "Max DoodleRooms to mint in og sale is five"
        );

        require(
            totalSupply() + numberOfTokens <= maxOGSaleDoodleRooms,
            "Not enough DoodleRooms remaining to mint"
        );

        ogSaleMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getOGSaleMintCount(address _addr) public view returns (uint256) {
        return ogSaleMintCounts[_addr];
    }

    function getPresaleMintCount(address _addr) public view returns (uint256) {
        return presaleMintCounts[_addr];
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
    external
    onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setVerificationHash(string memory _verificationHash)
    external
    onlyOwner
    {
        verificationHash = _verificationHash;
    }

    // ============ SALE/PRESALE/OG_SALE STATE CHANGES ============

    function setPresaleSupply(uint256 _maxPresaleDoodleRooms)
    external
    onlyOwner
    {
        maxPresaleDoodleRooms = _maxPresaleDoodleRooms;
    }

    function setOGSaleSupply(uint256 _maxOGPresaleDoodleRooms)
    external
    onlyOwner
    {
        maxOGSaleDoodleRooms = _maxOGPresaleDoodleRooms;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
    external
    onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsPresaleActive(bool _isPresaleActive)
    external
    onlyOwner
    {
        isPresaleActive = _isPresaleActive;
    }

    function setIsOGSaleActive(bool _isOGSaleActive)
    external
    onlyOwner
    {
        isOGSaleActive = _isOGSaleActive;
    }

    function setPresaleListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        presaleMerkleRoot = merkleRoot;
    }

    function setOGPresaleListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        ogSaleMerkleRoot = merkleRoot;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function reserveForGifting(uint256 numToReserve)
    external
    nonReentrant
    onlyOwner
    canGiftDoodleRooms(numToReserve)
    {
        numGiftedDoodleRooms += numToReserve;

        _safeMint(msg.sender, numToReserve);
    }

    function giftDoodleRooms(address[] calldata addresses)
    external
    nonReentrant
    onlyOwner
    canGiftDoodleRooms(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedDoodleRooms += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 shareOne = balance / 5;
        uint256 shareTwo = balance - shareOne;

        payable(shareOneAddress).transfer(shareOne);
        payable(shareTwoAddress).transfer(shareTwo);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", tokenId.toString()))
        : '';
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), (salePrice * 7) / 100);
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}