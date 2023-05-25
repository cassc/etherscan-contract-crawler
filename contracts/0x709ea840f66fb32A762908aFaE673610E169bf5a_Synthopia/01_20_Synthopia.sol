// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";
import "./PaymentSplitter.sol";

contract Synthopia is
    ERC721Enumerable,
    Ownable,
    PaymentSplitter,
    ReentrancyGuard,
    VRFConsumerBase
{
    using ECDSA for bytes32;

    bool SALE_ENDED;
    uint256 PUBLIC_SALE_START_TIME;
    address SIGNER;
    string BASE_URI;
    uint256 public CODE_MINT_PRICE = 0.0639 ether;
    uint256 public PUBLIC_MINT_PRICE = 0.0693 ether;
    uint256 public MAX_SUPPLY = 9639;
    uint256 public FINAL_SEED;

    mapping(uint256 => bytes32) tokenIdToHash;
    mapping(address => bool) public admin;
    mapping(bytes32 => bool) public usedUuids;

    uint256 currentId;
    bytes32 keyHash;
    uint256 fee;

    constructor(
        address signer,
        string memory baseUri,
        address[] memory payees,
        uint256[] memory shares,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _vrfFee,
        bytes32 _keyHash
    )
        ERC721("Synthopia", "S/A")
        PaymentSplitter(payees, shares)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        SIGNER = signer;
        BASE_URI = baseUri;
        for (uint256 i; i < payees.length; i++) {
            admin[payees[i]] = true;
        }
        keyHash = _keyHash;
        fee = _vrfFee;
    }

    event AdminUpdated(address adminAddress, bool value);

    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        if (FINAL_SEED == 0) {
            FINAL_SEED = randomness;
        }
    }

    function withdrawLink(address to) public onlyOwner {
        LINK.transferFrom(address(this), to, LINK.balanceOf(address(this)));
    }

    function updateAdmin(address adminAddress, bool value) public onlyOwner {
        admin[adminAddress] = value;
        emit AdminUpdated(adminAddress, value);
    }

    modifier onlyAdmin() {
        require(admin[msg.sender] == true, "Not admin");
        _;
    }

    function release(address payable account) public override onlyAdmin {
        super.release(payable(account));
    }

    function withdraw() public onlyAdmin {
        for (uint256 i = 0; i < numberOfPayees(); i++) {
            release(payable(payee(i)));
        }
    }

    function setBaseUri(string memory baseUri) public onlyOwner {
        BASE_URI = baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function updateSigner(address signer) public onlyOwner {
        SIGNER = signer;
    }

    function _mintInternal(
        uint256 amount,
        uint256 cost,
        bytes32 code
    ) internal nonReentrant {
        require(
            amount <= (publicSaleStarted() ? 10 : 3),
            "Max mint amount exceeded"
        );
        require(currentId < MAX_SUPPLY, "All minted");
        require(currentId + amount <= MAX_SUPPLY, "Cannot mint amount");
        uint256 costToMint = amount * cost;
        require(costToMint <= msg.value, "Invalid value");
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = ++currentId;
            _safeMint(msg.sender, tokenId);
            tokenIdToHash[tokenId] = keccak256(
                abi.encodePacked(blockhash(block.number - 1), tokenId)
            );
            emit Minted(tokenId, code);
        }
        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token ID does not exist");
        return
            uint256(
                keccak256(abi.encodePacked(tokenIdToHash[tokenId], FINAL_SEED))
            );
    }

    event Minted(uint256 tokenId, bytes32 code);

    function mintWithSignature(
        bytes32 uuid,
        uint256 amount,
        bytes memory signature
    ) public payable {
        require(publicSaleStarted() == false, "Use mint function");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, uuid));
        require(
            hash.toEthSignedMessageHash().recover(signature) == SIGNER,
            "Invalid signature"
        );
        require(usedUuids[uuid] == false, "Invalid UUID");
        _mintInternal(amount, CODE_MINT_PRICE, uuid);
    }

    function mint(uint256 amount) public payable {
        require(publicSaleStarted() == true, "Public mint not started");
        require(publicSaleEnded() == false, "Public sale ended");
        _mintInternal(amount, PUBLIC_MINT_PRICE, "");
    }

    function publicSaleEnded() public view returns (bool) {
        return SALE_ENDED;
    }

    function publicSaleStarted() public view returns (bool) {
        return PUBLIC_SALE_START_TIME > 0;
    }

    function endPublicSale() public onlyOwner {
        SALE_ENDED = true;
    }

    function startPublicSale() public onlyOwner {
        require(!publicSaleStarted(), "Public sale has already begun");
        PUBLIC_SALE_START_TIME = block.timestamp;
    }

    event DataAdded(uint256 indexed id);

    function sendCallData(bytes calldata data, uint256 id) public onlyOwner {
        emit DataAdded(id);
    }
}