// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HelloCharlie is ERC721A, Ownable {
    using Strings for uint256;

    enum SaleState {
        PAUSED,
        ANGELS,
        CHARLISTS,
        WAITLIST,
        PUBLIC
    }

    uint256 public MAX_SUPPLY = 5001;
    uint256 public MAX_OG_MINT = 2;
    uint256 public MAX_WHITELIST_MINT = 1;
    uint256 public MAX_FOUNDER_MINT = 375;

    uint256 public MINT_PRICE = .039 ether;

    string private baseTokenUri;
    string public placeholderTokenUri;

    SaleState public currState;

    bool public isRevealed = false; 

    bytes32 private merkleRoot;
    bytes32 private merkleRootOG;
    bytes32 private merkleRootWA;

    mapping(address => uint256) public totalOGMint;
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalWaitlistMint;
    mapping(address => uint256) public totalFounderMint;

    constructor() ERC721A("Hello Charlie", "CHAR") { }

    modifier correctState(SaleState _state) {
        require(currState == _state, "Incorrect state.");
        _;
    }

    function ogMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable correctState(SaleState.ANGELS) {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply.");
        require((totalOGMint[msg.sender] + _quantity) <= MAX_OG_MINT, "You have reached the maximum amount of mints.");
        require(msg.value >= MINT_PRICE * _quantity, "Invalid Amount.");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootOG, sender), "You are not an OG!");

        totalOGMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable correctState(SaleState.CHARLISTS) {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply.");
        require((totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT, "You have reached the maximum amount of mints.");
        require(msg.value >= MINT_PRICE * _quantity, "Invalid Amount.");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "You are not whitelisted!");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function waitlistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable correctState(SaleState.WAITLIST) {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply.");
        require((totalWaitlistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT, "You have reached the maximum amount of mints.");
        require(msg.value >= MINT_PRICE * _quantity, "Invalid Amount.");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootWA, sender), "You are not waitlisted!");

        totalWaitlistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable correctState(SaleState.PUBLIC) {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply.");
        require(msg.value >= MINT_PRICE * _quantity, "Invalid Amount.");

        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!isRevealed){
            return placeholderTokenUri;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    // ONLY OWNER
    function foundersMint(uint256 _quantity) external onlyOwner {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply.");
        require((totalFounderMint[msg.sender] +_quantity) <= MAX_FOUNDER_MINT, "You have reached the maximum amount of mints.");

        totalFounderMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function setTokenUri(string memory _baseTokenUri) public onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri) public onlyOwner {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot, bytes32 _merkleRootOG, bytes32 _merkleRootWA) external onlyOwner {
        merkleRoot = _merkleRoot;
        merkleRootOG = _merkleRootOG;
        merkleRootWA = _merkleRootWA;
    }

    function setState(uint256 _state) external onlyOwner {
        require(_state <= uint256(SaleState.PUBLIC), "Invalid state.");

        currState = SaleState(_state);
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setMintPrice(uint256 _newPx) external onlyOwner {
        MINT_PRICE = _newPx;
    }

    function setMaxMintOG(uint256 _maxMint) external onlyOwner {
        MAX_OG_MINT = _maxMint;
    }

    function setMaxMintWL(uint256 _maxMint) external onlyOwner {
        MAX_WHITELIST_MINT = _maxMint;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdrawMoney() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(0xC434D71663372B8020B117E679191C13F2E86C4c).transfer(balance);
    }
}