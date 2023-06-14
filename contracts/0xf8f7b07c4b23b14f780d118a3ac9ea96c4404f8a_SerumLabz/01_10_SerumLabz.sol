// SPDX-License-Identifier: MIT
// SerumLabz brought to you by blockgeni3 - Testnet 1
pragma solidity 0.8.15;

import "./extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SerumLabz is ERC721AQueryable, Ownable {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    address payable immutable private bgaddress = payable(0xddC3A364260e619316E0A5dE60ef00326E8F164d);
    address payable immutable private lpaddress = payable(0x772CAC9Bbccd07Ef28b1c6da3AEc4E62611C43Ef);
    address payable immutable private maddress = payable(0x4A938B9D5b631f26aFBC014f7beB234090350D40);
    address payable immutable private sladdress = payable(0x8798eDF9dc9A46511D9EFaD6418Ead87f3A6624f);



    uint256 private constant MAX_SUPPLY = 7777;
    uint256 private constant MAX_PER_WALLET = 10;

    uint256 public cost = 1 * 10 ** 16;
    bool public publicMintStarted = false;
    bool public privateMintStarted = false;
    bool private revealedState = false;
    
    string private baseURI;
    string private notRevealedURI;
    bytes32 private presaleMerkleRoot;

    mapping(address => uint256) private numberMinted;

    constructor(string memory _initBaseURI, string memory _initNotRevealedURI, bytes32 _root) ERC721A("SerumLabz", "SLBZ") {
        require(bytes(_initBaseURI).length > 0, "[Error] Base URI Cannot Be Blank");
        require(bytes(_initNotRevealedURI).length > 0, "[Error] Not Revealed URI Cannot Be Blank");
        require(_root.length > 0, "[Error] Empty Root");

        baseURI = _initBaseURI;
        notRevealedURI = _initNotRevealedURI;
        presaleMerkleRoot = _root;
    }

    // ===== Check Caller Is User =====
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "[Error] Function cannot be called by a contract");
        _;
    }

    // ===== Check Mint Compliance =====
    modifier maxWalletCheck(uint8 quantity) {
        require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET && numberMinted[msg.sender] + quantity <= MAX_PER_WALLET, "[Error] Max Per Wallet Reached");
        _;
    }

    // ===== Check Supply =====
    modifier supplyCheck(uint8 quantity) {
        require(totalSupply() + quantity < MAX_SUPPLY, "[Error] Max Mint Reached");
        require(quantity > 0, "[Error] Quantity cannot be zero");
        _;
    }

    // ===== Check Not Null Value =======
    modifier notNull(string memory str){
        require(bytes(str).length > 0, "[Error] Null Value Received");
        _;
    }

    // ===== Dev Mint =====
    function devMint(uint8 quantity) external onlyOwner supplyCheck(quantity) {
        _mint(msg.sender, quantity);
    }

    // ===== Private Mint =====
    function privateMint(bytes32[] memory proof, uint8 quantity) external payable maxWalletCheck(quantity) supplyCheck(quantity) callerIsUser {
        require(!publicMintStarted && privateMintStarted, "[Error] Private Mint Not Started");
        require(proof.verify(presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "[Error] You are not on the whitelist");

        if(numberMinted[msg.sender] == 0) {
            require(msg.value >= (cost * (quantity - 1)), "[Error] Not enough funds supplied");
        } else {
            require(msg.value >= cost * quantity, "[Error] Not enough funds supplied");
        }

        numberMinted[msg.sender] += quantity;

        revealedState = (totalSupply() + quantity == MAX_SUPPLY);

        _mint(msg.sender, quantity);

        sendFunds(msg.value);
    }
    
    // ===== Mint =====
    function mint(uint8 quantity) external payable maxWalletCheck(quantity) supplyCheck(quantity) callerIsUser {
        require(publicMintStarted && !privateMintStarted, "[Error] Public Mint Not Started");
        require(msg.value < (cost * quantity), "[Error] Public Mint Not Started");

        numberMinted[msg.sender] += quantity;

        revealedState = (totalSupply() + quantity == MAX_SUPPLY);

        _mint(msg.sender, quantity);

        sendFunds(msg.value);
    }

    // ===== Stop Mint =====
    function stopMint() external onlyOwner {
        publicMintStarted = false;
        privateMintStarted = false;
    }

    // ===== Turn on public mint =====
    function turnOnPublicMint() external onlyOwner {
        publicMintStarted = true;
        privateMintStarted = false;
    }

    // ===== Turn on private mint =====
    function turnOnPrivateMint() external onlyOwner {
        publicMintStarted = false;
        privateMintStarted = true;
    }

    // ===== Toggle Revealed State =====
    function toggleReveal() external onlyOwner {
        revealedState = !revealedState;
    }

    // ===== Update Merkle Root =====
    function setMerkleRoot(bytes32 root) external onlyOwner {
        require(root.length > 0, "[Error] Empty Root");
        presaleMerkleRoot = root;
    }

    // ===== Change Mint Price =====
    function setMintPrice(uint256 value) external onlyOwner {
        require(value > 0, "[Error] Value cannot be 0");
        cost = value;
    }

    // ===== Change Base URI =====
    function setBaseURI(string memory newBaseURI) external onlyOwner notNull(newBaseURI){
        baseURI = newBaseURI;
    }

    // ===== Change Not Revealed URI =====
    function setNotRevealedURI(string memory newNotRevealedURI) external onlyOwner notNull(newNotRevealedURI) {
        notRevealedURI = newNotRevealedURI;
    }

    // ===== Change Not Revealed URI =====
    function withdraw() external onlyOwner {
        sendFunds(address(this).balance);
    }

    // ===== Set Start Token ID =====
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ===== Set Base URI =====
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ===== Set Token URI =====
    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        string memory currentUri = (revealedState == true) ? baseURI : notRevealedURI;
        return bytes(currentUri).length > 0 ? string(abi.encodePacked(currentUri, tokenId.toString(), ".json")) : "";
    }

    // ===== Split Funds =====
    function sendFunds(uint256 _totalMsgValue) internal {
        (bool s1,) = bgaddress.call{value: (_totalMsgValue * 25) / 100}("");
        (bool s2,) = lpaddress.call{value: (_totalMsgValue * 35) / 100}("");
        (bool s3,) = maddress.call{value: (_totalMsgValue * 20) / 100}("");
        (bool s4,) = sladdress.call{value: (_totalMsgValue * 20) / 100}("");
        require(s1 && s2 && s3 && s4, "[Error] Payment Splitter Failure");
    }

    // ===== Fallbacks =====
    receive() external payable {
        sendFunds(address(this).balance);
    }

    fallback() external payable {
        sendFunds(address(this).balance);
    }
}