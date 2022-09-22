// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract Ovr is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY = 4000;
    uint256 public WL_SUPPLY = 2500;
    uint256 public FREE_SUPPLY = 35;

    uint256 public MINT_LIMIT = 2;
    uint256 public PUBLIC_TX_LIMIT = 4;

    uint256 public PRICE = 0.029 ether;

    bool public isFreeActive = true;
    bool public isWlSaleActive = true;
    bool public isPublicActive = true;

    bool _revealed = false;

    string private baseURI = "";

    bytes32 wlRoot;
    bytes32 freeRoot;
    address signer;

    uint256 freeCount;
    uint256 wlCount;

    mapping(address => uint256) addressBlockBought;
    mapping(address => bool) public freeMinted;
    mapping(address => uint256) public wlMinted;

    address public constant RL_ADDRESS = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; 
    address public constant PROJECT_ADDRESS = 0x893A497EBC37785D862219516464Ac42beF40bb6; 
    
    mapping(bytes32 => bool) public usedDigests;

    constructor(bytes32 _wlRoot, bytes32 _freeMint, address _signer) ERC721A("Ovr", "OVR") {
        wlRoot = _wlRoot;
        freeRoot = _freeMint;
        signer = _signer;
        _safeMint(0x4d18F71B974Aa412fbF08C8A9bd708d598BFE3AA, 5);
        _safeMint(RL_ADDRESS, 10);
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 0) {
            require(isFreeActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 1) {
            require(isWlSaleActive, "WL_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 2) {
            require(isPublicActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function freeMint(bytes32[] memory proof) external isSecured(0) payable{
        require(MerkleProof.verify(proof, freeRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(freeCount + 1 <= FREE_SUPPLY,"EXCEED_FREE_SUPPLY");
        require(!freeMinted[msg.sender],"EXCEED_MINT_LIMIT");
        require(1 + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");

        addressBlockBought[msg.sender] = block.timestamp;
        freeCount += 1;
        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function allowMint(bytes32[] memory proof, uint256 numberOfTokens) external isSecured(1) payable{
        require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(wlCount + numberOfTokens <= WL_SUPPLY,"EXCEED_WL_SUPPLY");
        require(wlMinted[msg.sender] + numberOfTokens <= MINT_LIMIT,"EXCEED_MINT_LIMIT");
        require(msg.value == PRICE * numberOfTokens, "WRONG_ETH_VALUE");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");

        addressBlockBought[msg.sender] = block.timestamp;
        wlCount += numberOfTokens;
        wlMinted[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function publicMint(uint64 expireTime, bytes memory sig, uint256 numberOfTokens) external isSecured(2) payable {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(numberMinted(msg.sender) + numberOfTokens <= PUBLIC_TX_LIMIT,"ONLY_4_IS_ALLOWED");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(msg.value == PRICE * numberOfTokens, "WRONG_ETH_VALUE");

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

    function toggleWlMintStatus() external onlyOwner {
        isWlSaleActive = !isWlSaleActive;
    }

    function togglePublicMintStatus() external onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function toggleFreeMintStatus() external onlyOwner {
        isFreeActive = !isFreeActive;
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

    function setFreeSaleRoot(bytes32 _freeRoot) external onlyOwner {
        freeRoot = _freeRoot;
    }

    // LIMIT SETTERS
    function setWLMintLimit(uint256 _mintLimit) external onlyOwner {
        MINT_LIMIT = _mintLimit;
    }

    // PRICE SETTERS
    function setWlPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    // SUPPLY SETTERS
    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function isAuthorized(bytes memory sig, bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(RL_ADDRESS).transfer((balance * 2000) / 10000);
        payable(PROJECT_ADDRESS).transfer(address(this).balance);
    }
}