// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Birds is ERC721A, Ownable, ReentrancyGuard, IERC721Receiver {
    using Strings for uint256;
    string private _baseTokenURI;
    string private _defaultTokenURI;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant GUARANTEED_SUPPLY = 3000;
    uint256 public constant PHASE1_DURATION = 30 minutes;
    uint256 public constant PHASE2_DURATION = 6 hours;
    uint256 public constant WHITELIST_PRICE = 0.08 ether;
    uint256 public constant PUBLIC_PRICE = 0.1 ether;
    uint256 public constant WHITELIST_MAX_QUANTITY = 2;
    bytes32 public gamelistRoot;
    bytes32 public birdlistRoot;
    uint256 public PHASE1_STARTING_AT;
    uint256 public PHASE2_STARTING_AT;
    uint256 public PUBLIC_STARTING_AT;

    uint256 public phase1_total;
    uint256 public phase2_total;
    mapping(address => bool) public guaranteed_minted;
    mapping(address => uint256) public whitelist_minted;
    uint256 public constant refundPeriod = 72 hours;
    address public refundAddress;
    uint256 public refundEndTime;
    mapping(uint256 => bool) public hasRefunded;

    event Refund(
        address indexed _sender,
        uint256 indexed _tokenId
    );

    constructor() ERC721A("FlappyMoonbird Genesis Birds", "FMGB") {
        _safeMint(0x2B37E4c2999101f6458a534a6871Fd1904c6dF3f, 500);
        _defaultTokenURI = "ipfs://QmWHs2CGKiFoGz2dT86LytBy89C3zQkJgpKsvcZ57XVQrA";
        PHASE1_STARTING_AT = 1683637200;
        PHASE2_STARTING_AT = PHASE1_STARTING_AT + PHASE1_DURATION;
        PUBLIC_STARTING_AT = PHASE1_STARTING_AT + PHASE2_DURATION;
        refundAddress = address(this);
        refundEndTime = PHASE1_STARTING_AT + refundPeriod;
    }

    function setGamelistRoot(bytes32 merkleroot) external onlyOwner {
        gamelistRoot = merkleroot;
    }

    function setBirdlistRoot(bytes32 merkleroot) external onlyOwner {
        birdlistRoot = merkleroot;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function gamelistMint(address to, bytes32[] calldata proof) external payable nonReentrant {
        require(PHASE1_STARTING_AT <= block.timestamp, "Phase1 not ready");
        require(guaranteed_minted[to] == false, "Already minted");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceed alloc");
        require(msg.value == WHITELIST_PRICE, "Not match price");
        bytes32 leaf = keccak256(abi.encodePacked(to));
        bool isValidLeaf = MerkleProof.verify(proof, gamelistRoot, leaf);
        require(isValidLeaf == true, "Not in merkle");
        phase1_total++;
        guaranteed_minted[to] = true;
        _safeMint(to, 1);
    }

    function birdlistMint(
        address to,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(PHASE1_STARTING_AT <= block.timestamp, "Phase1 not ready");
        require(whitelist_minted[to] < WHITELIST_MAX_QUANTITY, "Already minted");
        require(totalSupply() < 7000 || block.timestamp > PHASE2_STARTING_AT, "Wait for GuaranteedWL");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed alloc");
        require(msg.value == quantity * WHITELIST_PRICE, "Not match price");
        bytes32 leaf = keccak256(abi.encodePacked(to));
        bool isValidLeaf = MerkleProof.verify(proof, birdlistRoot, leaf);
        require(isValidLeaf == true, "Not in merkle");
        phase2_total += quantity;
        whitelist_minted[to] += quantity;
        _safeMint(to, quantity);
    }

    function publicMint(address to, uint256 quantity) external payable nonReentrant {
        require(PUBLIC_STARTING_AT <= block.timestamp, "Phase3 not ready");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed alloc");
        require(msg.value == quantity * PUBLIC_PRICE, "Not match price");
        _safeMint(to, quantity);
    }

    function refund(uint256 tokenId) external nonReentrant {
        require(block.timestamp < refundDeadlineOf(tokenId), "Refund expired");
        require(msg.sender == ownerOf(tokenId), "Not token owner");

        uint256 refundAmount = refundOf(tokenId);
        Address.sendValue(payable(msg.sender), refundAmount);
        hasRefunded[tokenId] = true;
        safeTransferFrom(msg.sender, refundAddress, tokenId);
        emit Refund(msg.sender, tokenId);
    }

    function refundDeadlineOf(uint256 tokenId) public view returns (uint256) {
        if (hasRefunded[tokenId]) {
            return 0;
        }
        return refundEndTime;
    }

    function refundOf(uint256 tokenId) public view returns (uint256) {
        if (hasRefunded[tokenId]) {
            return 0;
        }
        return WHITELIST_PRICE;
    }

    function setPresaleMint(uint256 presaleTime) external onlyOwner {
        PHASE1_STARTING_AT = presaleTime;
        PHASE2_STARTING_AT = PHASE1_STARTING_AT + PHASE1_DURATION;
        PUBLIC_STARTING_AT = PHASE1_STARTING_AT + PHASE2_DURATION;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }

    function setDefaultTokenURI(string calldata URI) external onlyOwner {
        _defaultTokenURI = URI;
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : _defaultTokenURI;
    }

    function rescueRefundBird (uint256 tokenId) external onlyOwner {
        require(hasRefunded[tokenId], "Not refund");
        IERC721 nft = IERC721(address(this));
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(block.timestamp > refundEndTime, "Refund period not over");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}