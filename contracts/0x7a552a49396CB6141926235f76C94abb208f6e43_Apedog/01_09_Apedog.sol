// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract Apedog is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_MINT = 10;

    bool public isSaleActive = false;
    bool public isPublicActive = false;

    bool _revealed = false;

    string private baseURI = "";

    //Make setters for the 3
    bytes32 wlRoot;
    address signer;

    mapping(address => uint256) addressBlockBought;
    mapping(address => bool) public mintedPublic;

    address public constant LOWKEYVAULT = 0x2283eC9bE49543445F606EC2863D49F4c2213D2C; 
    address public constant TEAM_WALLET = 0x3137B627aD98651c866cc1162FC394C2D00e40b9; 

    uint256 public LOWKEY_ALLOCATION = 100;
    uint256 public LOWKEY_COLLAB = 100;
    uint256 public TEAM_WALLET_ALLOCATION = 333;
    
    mapping(bytes32 => bool) public usedDigests;

    constructor(
        bytes32 _wlRoot,
        address _signer) ERC721A("ApeDog", "APEDOG") {
            wlRoot = _wlRoot;
            signer = _signer;
        }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isSaleActive, "WL_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 2) {
            require(isPublicActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function mintVault(uint256 numberOfTokens) external onlyOwner {
        require(LOWKEY_ALLOCATION > 0,"EXCEED_MINT_LIMIT");
        require(numberOfTokens <= LOWKEY_ALLOCATION, "EXCEEDS_MAX_MINT_FOR_TEAM");
        LOWKEY_ALLOCATION -= numberOfTokens;
        _safeMint(LOWKEYVAULT, numberOfTokens);
    }

    function mintForCollab(uint256 numberOfTokens) external onlyOwner {
        require(LOWKEY_COLLAB > 0,"EXCEED_MINT_LIMIT");
        require(numberOfTokens <= LOWKEY_COLLAB, "EXCEEDS_MAX_MINT_FOR_TEAM");
        LOWKEY_COLLAB -= numberOfTokens;
        _safeMint(TEAM_WALLET, numberOfTokens);
    }

    function mintTeam(uint256 numberOfTokens) external onlyOwner {
        require(TEAM_WALLET_ALLOCATION > 0,"EXCEED_MINT_LIMIT");
        require(numberOfTokens <= TEAM_WALLET_ALLOCATION, "EXCEEDS_MAX_MINT_FOR_TEAM");
        TEAM_WALLET_ALLOCATION -= numberOfTokens;
        _safeMint(TEAM_WALLET, numberOfTokens);
    }

    function wlMint(uint256 numberOfTokens, bytes32[] memory proof, uint256 maxMint) external isSecured(1) payable{
        require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender, maxMint))),"PROOF_INVALID");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(numberMinted(msg.sender) + numberOfTokens <= maxMint,"EXCEED_PRESALE_MINT_LIMIT");

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    function publicMint(uint64 expireTime, bytes memory sig, uint256 numberOfTokens) external isSecured(2) payable {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(numberMinted(msg.sender) <= MAX_MINT,"MAX_MINT_REACHED");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");

        usedDigests[digest] = true;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    //Essential
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    //Essential
    function toggleWlMintStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function togglePublicMintStatus() external onlyOwner {
        isPublicActive = !isPublicActive;
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

    function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
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
        payable(msg.sender).transfer(address(this).balance);
    }
}