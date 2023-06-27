//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ERC721A.sol";

interface DoodleRooms {
    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);
}

contract DoodlePets is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private baseURI;
    string public verificationHash;
    address private openSeaProxyRegistryAddress;

    bool private isOpenSeaProxyActive = true;
    bool public isPublicSaleActive;

    DoodleRooms public doodleRooms;

    uint256 public constant MAX_DOODLE_PETS_FOR_DOODLE_ROOMS_WITH_PETS = 200;
    uint256 public constant MAX_FREE_MINT_DOODLE_PETS = 200;
    uint256 public constant MAX_GIFTED_DOODLE_PETS = 50;

    uint256 public constant MAX_DOODLE_PETS_PER_WALLET = 5;
    uint256 public constant MAX_DOODLE_PETS_PER_TX = 10;
    uint256 public constant DOODLE_PETS_SUPPLY = 4644;

    uint256 public constant DOODLE_PET_PRICE_FIRST_PHASE = 0.03 ether;
    uint256 public constant THREE_DOODLE_PETS_PRICE_FIRST_PHASE = 0.075 ether;
    uint256 public constant FIVE_DOODLE_PETS_PRICE_FIRST_PHASE = 0.1 ether;

    uint256 public constant DOODLE_PET_PRICE = 0.04 ether;
    uint256 public constant THREE_DOODLE_PETS_PRICE = 0.1 ether;
    uint256 public constant FIVE_DOODLE_PETS_PRICE = 0.15 ether;
    uint256 public constant TEN_DOODLE_PETS_PRICE = 0.3 ether;

    address public shareOneAddress;
    address public shareTwoAddress;

    bytes32 public firstPhaseMerkleRoot;
    bool public isFirstPhaseActive;

    bool public isPresaleActive;

    bool public shouldCheckDoodleRoomOwnership;

    uint256 public numGiftedDoodlePets;

    uint256 public numClaimedDoodlePets;
    bytes32 public claimListMerkleRoot;
    bool public isClaimActive;

    mapping(address => uint256) public presaleMintCounts;
    mapping(address => uint256) public firstPhaseMintCounts;
    mapping(address => bool) public claimCount;

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Third phase is not open");
        _;
    }

    modifier presaleActive() {
        require(isPresaleActive, "Presale is not open");
        _;
    }

    modifier firstPhaseActive() {
        require(isFirstPhaseActive, "First phase is not open");
        _;
    }

    modifier canMintDoodlePets(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens < (DOODLE_PETS_SUPPLY - MAX_GIFTED_DOODLE_PETS - MAX_FREE_MINT_DOODLE_PETS - MAX_DOODLE_PETS_FOR_DOODLE_ROOMS_WITH_PETS),
            "Not enough DoodlePets remaining to mint"
        );
        _;
    }

    modifier canGiftDoodlePets(uint256 num) {
        require(
            numGiftedDoodlePets + num <= MAX_GIFTED_DOODLE_PETS + MAX_DOODLE_PETS_FOR_DOODLE_ROOMS_WITH_PETS,
            "Not enough DoodlePets remaining to gift"
        );
        require(
            totalSupply() + num <= DOODLE_PETS_SUPPLY,
            "Not enough DoodlePets remaining to mint"
        );
        _;
    }

    modifier isCorrectFirstPhaseOrPresalePayment(uint256 numberOfTokens) {
        require(
            (numberOfTokens == 3 ? THREE_DOODLE_PETS_PRICE_FIRST_PHASE :
            numberOfTokens == 5 ? FIVE_DOODLE_PETS_PRICE_FIRST_PHASE :
            DOODLE_PET_PRICE_FIRST_PHASE * numberOfTokens) == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isDoodleRoomOwner() {
        require(doodleRooms.balanceOf(msg.sender) > 0, "Must be a Doodle Room owner");
        _;
    }

    modifier isCorrectPayment(uint256 numberOfTokens) {
        require(
            (numberOfTokens == 3 ? THREE_DOODLE_PETS_PRICE :
            numberOfTokens == 5 ? FIVE_DOODLE_PETS_PRICE :
            numberOfTokens == 10 ? TEN_DOODLE_PETS_PRICE :
            DOODLE_PET_PRICE * numberOfTokens) == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    constructor(
        address _openSeaProxyRegistryAddress,
        bytes32 _firstPhasePresaleMerkleRoot,
        bytes32 _claimMerkleRoot,
        address _shareOneAddress,
        address _shareTwoAddress
    ) ERC721A("Doodle Pets", "DP", 10) {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;

        firstPhaseMerkleRoot = _firstPhasePresaleMerkleRoot;
        claimListMerkleRoot = _claimMerkleRoot;

        shareOneAddress = _shareOneAddress;
        shareTwoAddress = _shareTwoAddress;

        shouldCheckDoodleRoomOwnership = true;

        doodleRooms = DoodleRooms(0x5426C860C9e660145Ad09d3FB26427e5Fd4569E9);

        baseURI = "ipfs://QmZzeyfwQLc6bLdxTB9bvw7q497b3g8qEBraRU3vXwNdRq";
    }

    function mint(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    publicSaleActive
    isCorrectPayment(numberOfTokens)
    canMintDoodlePets(numberOfTokens)
    {
        if (shouldCheckDoodleRoomOwnership) {
            require(doodleRooms.balanceOf(msg.sender) > 0, "Must be a Doodle Room owner");
        }
        require(numberOfTokens <= MAX_DOODLE_PETS_PER_TX, "Max mint of Doodle Pets per tx is ten");

        _safeMint(msg.sender, numberOfTokens);
    }

    function mintPresale(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    presaleActive
    isDoodleRoomOwner
    canMintDoodlePets(numberOfTokens)
    isCorrectFirstPhaseOrPresalePayment(numberOfTokens)
    {
        uint256 numAlreadyMinted = presaleMintCounts[msg.sender];
        require(
            numAlreadyMinted + numberOfTokens <= MAX_DOODLE_PETS_PER_WALLET,
            "Max Doodle Pets to mint in presale is five"
        );

        presaleMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function mintFirstPhase(
        uint256 numberOfTokens,
        bytes32[] calldata merkleProof
    )
    external
    payable
    nonReentrant
    firstPhaseActive
    canMintDoodlePets(numberOfTokens)
    isCorrectFirstPhaseOrPresalePayment(numberOfTokens)
    {
        require(
            doodleRooms.balanceOf(msg.sender) > 25 ||
            MerkleProof.verify(
                merkleProof,
                firstPhaseMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "mintFirstPhase: Must be whitelisted or at least a Tycoon Doodle Room owner"
        );

        uint256 numAlreadyMinted = firstPhaseMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_DOODLE_PETS_PER_WALLET,
            "Max DoodlePets to mint during first phase is five"
        );

        firstPhaseMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getFirstPhaseCount(address _addr) public view returns (uint256) {
        return firstPhaseMintCounts[_addr];
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

    function setIsFirstPhaseActive(bool _firstPhaseActive)
    external
    onlyOwner
    {
        isFirstPhaseActive = _firstPhaseActive;
    }

    function setShouldCheckDoodleRoomOwnership(bool _shouldCheck)
    external
    onlyOwner
    {
        shouldCheckDoodleRoomOwnership = _shouldCheck;
    }

    function setFirstPhaseMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        firstPhaseMerkleRoot = merkleRoot;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function reserveForGifting(uint256 numToReserve)
    external
    nonReentrant
    onlyOwner
    canGiftDoodlePets(numToReserve)
    {
        numGiftedDoodlePets += numToReserve;

        _safeMint(msg.sender, numToReserve);
    }

    function giftDoodlePets(address[] calldata addresses)
    external
    nonReentrant
    onlyOwner
    canGiftDoodlePets(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedDoodlePets += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function claim(bytes32[] calldata proof)
    external
    nonReentrant
    {
        require(isClaimActive, "Claim not active");
        require(numClaimedDoodlePets <= MAX_FREE_MINT_DOODLE_PETS);
        require(totalSupply() + 1 <= DOODLE_PETS_SUPPLY);
        require(
            MerkleProof.verify(
                proof,
                claimListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not eligible for a free mint"
        );
        require(!claimCount[msg.sender], "Already claimed a free Doodle Pet");

        claimCount[msg.sender] = true;
        numClaimedDoodlePets += 1;

        _safeMint(msg.sender, 1);
    }


    function setDoodlePetsContract(address _addr) external onlyOwner {
        doodleRooms = DoodleRooms(_addr);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 shareOne = (balance * 13) / 100;
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