// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract Yagiverse is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY = 3333;
    uint256 public TEAM_SUPPLY = 86;
    uint256 public RL_SUPPLY = 15;

    uint256 public PUBLIC_MINT_LIMIT = 10;
    uint256 public WL_MINT_LIMIT = 2;
    uint256 public WAIT_MINT_LIMIT = 5;

    uint256 public WL_PRICE = 0.049 ether;
    uint256 public WAIT_PRICE = 0.049 ether;
    uint256 public PUBLIC_PRICE = 0.049 ether;

    bool public isPublicSaleActive = false;
    bool public isWlSaleActive = false;
    bool public isWaitlistActive = false;

    bool _revealed = false;

    string private baseURI = "";

    bytes32 wlRoot;
    bytes32 waitRoot;
    address signer;

    mapping(address => uint256) addressBlockBought;
    mapping(address => bool) public mintedPublic;

    address public constant RL_ADDRESS = 0x49f8Bbf2f2576F76f2BDd1A58dc26a4258492188; 
    address public constant PROJECT_ADDRESS = 0x36Cd46fe3C2Fca98496Be8A0CFa945A19c069D5A; 
    
    mapping(bytes32 => bool) public usedDigests;

    constructor(
        bytes32 _wlRoot,
        address _signer,
        bytes32 _waitRoot) ERC721A("Yagiverse", "YAGIVERSE") {
            wlRoot = _wlRoot;
            signer = _signer;
            waitRoot = _waitRoot;
        }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isWlSaleActive, "WL_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 2) {
            require(isWaitlistActive, "WAITLIST_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 3) {
            require(isPublicSaleActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function mintForTeam(uint256 numberOfTokens) external onlyOwner {
        require(TEAM_SUPPLY > 0,"EXCEED_MINT_LIMIT");
        require(numberOfTokens <= TEAM_SUPPLY,"EXCEED_MINT_LIMIT");
        TEAM_SUPPLY -= numberOfTokens;
        _safeMint(PROJECT_ADDRESS, numberOfTokens);
    }

    function mintForRL(uint256 numberOfTokens) external onlyOwner {
        require(RL_SUPPLY > 0,"EXCEED_MINT_LIMIT");
        require(numberOfTokens <= RL_SUPPLY,"EXCEED_MINT_LIMIT");
        RL_SUPPLY -= numberOfTokens;
        _safeMint(RL_ADDRESS, numberOfTokens);
    }

    function allowMint(uint256 numberOfTokens, bytes32[] memory proof) external isSecured(1) payable{
        require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(numberMinted(msg.sender) + numberOfTokens <= WL_MINT_LIMIT,"EXCEED_PRAFFLE_MINT_LIMIT");
        require(msg.value == WL_PRICE * numberOfTokens, "WRONG_ETH_VALUE");

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    function waitMint(uint256 numberOfTokens, bytes32[] memory proof) external isSecured(2) payable{
        require(MerkleProof.verify(proof, waitRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(numberMinted(msg.sender) + numberOfTokens <= WAIT_MINT_LIMIT,"EXCEED_PRAFFLE_MINT_LIMIT");
        require(msg.value == WAIT_PRICE * numberOfTokens, "WRONG_ETH_VALUE");

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    //Essential
    function publicMint(uint64 expireTime, bytes memory sig, uint256 numberOfTokens) external isSecured(3) payable {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(numberMinted(msg.sender) + numberOfTokens <= PUBLIC_MINT_LIMIT,"ONLY_10_IS_ALLOWED");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(msg.value == PUBLIC_PRICE * numberOfTokens, "WRONG_ETH_VALUE");

        usedDigests[digest] = true;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    // URI
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    // LIVE TOGGLES
    function togglePublicMintStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleWlMintStatus() external onlyOwner {
        isWlSaleActive = !isWlSaleActive;
    }

    function toggleWaitMintStatus() external onlyOwner {
        isWaitlistActive = !isWaitlistActive;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ROOT SETTERS

    function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
    }

    function setWaitRoot(bytes32 _waitRoot) external onlyOwner {
        waitRoot = _waitRoot;
    }

    // LIMIT SETTERS
    function setPublicMintLimit(uint256 _mintLimit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _mintLimit;
    }

    function setWLMintLimit(uint256 _mintLimit) external onlyOwner {
        WL_MINT_LIMIT = _mintLimit;
    }

    function setWaitMintLimit(uint256 _mintLimit) external onlyOwner {
        WAIT_MINT_LIMIT = _mintLimit;
    }

    // PRICE SETTERS
    function setPublicPrice(uint256 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setWlPrice(uint256 _price) external onlyOwner {
        WL_PRICE = _price;
    }

    function setWaitPrice(uint256 _price) external onlyOwner {
        WAIT_PRICE = _price;
    }

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function isAuthorized(bytes memory sig, bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(RL_ADDRESS).transfer((balance * 1800) / 10000);
        payable(PROJECT_ADDRESS).transfer(address(this).balance);
    }
}