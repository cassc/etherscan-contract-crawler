// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MetaBucks.sol";

contract MetaBucks2 is ERC721A, Ownable, ReentrancyGuard {
    uint256 public FREE_SUPPLY = 1112;
    uint256 public MAX_SUPPLY = 3333;
    uint256 public COMMUNITY = 120;

    //Create Setters for price
    uint256 public PUBLIC_PRICE = 0.05 ether;

    uint256 public constant FREE_LIMIT = 2;
    uint256 public constant PUBLIC_MINT_LIMIT = 5;

    //Create Setters for status
    bool public isFreeMintActive = false;
    bool public isPublicSaleActive = false;

    bool _revealed = false;

    string private baseURI = "";

    address signer;

    mapping(address => uint256) addressBlockBought;
    mapping(uint256 => uint256) public mintedFree;

    address public constant OWNER_ADDRESS = 0x9747986296374326e892CE5dAf525ce3694d3B1b; 
    address public constant RL_ADDRESS = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; 
    address public constant COMUNITY_ADDRESS = 0x4A26ad587D75656B5e1FF964cdB07cD7033aa42a; 

    uint256 public freeMintCount = 0;
    
    mapping(bytes32 => bool) public usedDigests;

    MetaBucks public metaBucksContract;

    constructor(
        address _signer,
        address metaBucksContractAddress) ERC721A("MetaBucks2", "METABUCKS2",150,3333) {
        signer = _signer;
        metaBucksContract = MetaBucks(metaBucksContractAddress);
    }   

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isFreeMintActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 2) {
            require(isPublicSaleActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function mintForGiveaway(uint256 numberOfTokens) external onlyOwner {
        require(COMMUNITY > 0,"EXCEED_MINT_LIMIT");
        require(numberOfTokens <= COMMUNITY, "EXCEEDS_MAX_MINT_FOR_TEAM");
        COMMUNITY -= numberOfTokens;
        _safeMint(COMUNITY_ADDRESS, numberOfTokens);
    }

    function freeMint(uint256 tokenId, uint256 numberOfTokens) external isSecured(1) {
        require(metaBucksContract.ownerOf(tokenId) == msg.sender,"USER_DO_NOT_OWN_ACCESS_KEY");
        require(mintedFree[tokenId] + numberOfTokens <= FREE_LIMIT, "EXCEEDS_FREE_MINT_SUPPLY" );
        require(freeMintCount + numberOfTokens <= FREE_SUPPLY, "EXCEEDS_FREE_MINT_SUPPLY" );
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");

        addressBlockBought[msg.sender] = block.timestamp;
        freeMintCount += numberOfTokens;
        mintedFree[tokenId] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function publicMint(uint64 expireTime, bytes memory sig, uint256 numberOfTokens) external isSecured(2) payable {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(numberOfTokens <= PUBLIC_MINT_LIMIT,"CANNOT_MINT_MORE_THAN_ONE");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(msg.value == PUBLIC_PRICE * numberOfTokens, "NOT_ENOUGH_ETH");

        usedDigests[digest] = true;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setFreeSupply(uint256 _supply) external onlyOwner {
        FREE_SUPPLY = _supply;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMetaBucksContract(address metaBucksContractAddress) external onlyOwner {
        metaBucksContract = MetaBucks(metaBucksContractAddress);
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    function toggleFreeMintStatus() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }

    //Essential
    function togglePublicMintStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
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
        uint256 RL_SHARES = (balance * 850) / 10000;
        uint256 COMMUNITY_WALLET_SHARES = (balance * 2500) / 10000;

        payable(RL_ADDRESS).transfer(RL_SHARES);
        payable(COMUNITY_ADDRESS).transfer(COMMUNITY_WALLET_SHARES);
        payable(OWNER_ADDRESS).transfer(address(this).balance);
    }
}