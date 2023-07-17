// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract MetaBucks is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant FREE_SUPPLY = 60;
    uint256 public constant WL_SUPPLY = 2900;
    uint256 public constant RAFFLE_SUPPLY = 333;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public GIVEAWAY = 97;

    //Create Setters for price
    uint256 public WL_PRICE = 0.1 ether;
    uint256 public PUBLIC_PRICE = 0.125 ether;

    uint256 public constant FREE_LIMIT = 1;
    uint256 public constant WL_LIMIT = 2;
    uint256 public constant PUBLIC_MINT_LIMIT = 1;

    //Create Setters for status
    bool public isFreeMintActive = false;
    bool public isAllowListActive = false;
    bool public isRaffleActive = false;
    bool public isPublicSaleActive = false;

    bool _revealed = false;

    string private baseURI = "";

    //Make setters for the 3
    bytes32 freeMintRoot;
    bytes32 wlRoot;
    bytes32 raffleRoot;
    address signer;

    mapping(address => uint256) addressBlockBought;
    mapping(address => bool) public mintedPublic;

    address public constant OWNER_ADDRESS = 0x9747986296374326e892CE5dAf525ce3694d3B1b; 
    address public constant RL_ADDRESS = 0x49f8Bbf2f2576F76f2BDd1A58dc26a4258492188; 
    address public constant COMUNITY_ADDRESS = 0x4A26ad587D75656B5e1FF964cdB07cD7033aa42a; 

    uint256 public freeMintCount = 0;
    uint256 public wlMintcount = 0;
    uint256 public raffleMintCount = 0;
    
    mapping(bytes32 => bool) public usedDigests;

    constructor(
        bytes32 _wlRoot,
        bytes32 _freeMintRoot,
        bytes32 _raffleRoot,
        address _signer) ERC721A("MetaBucks", "METABUCKS",100,3333) {
            freeMintRoot = _freeMintRoot;
            wlRoot = _wlRoot;
            raffleRoot = _raffleRoot;
            signer = _signer;
        }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isFreeMintActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 2) {
            require(isAllowListActive, "WL_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 3) {
            require(isRaffleActive, "RAFFLE_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 4) {
            require(isPublicSaleActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    // DiamoRubynd Mint to owner's wallet for giveaway
    function mintForGiveaway(uint256 numberOfTokens) external onlyOwner {
        require(GIVEAWAY > 0,"EXCEED_MINT_LIMIT");
        require(numberOfTokens <= GIVEAWAY, "EXCEEDS_MAX_MINT_FOR_TEAM");
        GIVEAWAY -= numberOfTokens;
        _safeMint(COMUNITY_ADDRESS, numberOfTokens);
    }

    /**
     * Free mint function
     */
    function freeMint(bytes32[] calldata freeMintProof) external isSecured(1) {
        require(MerkleProof.verify(freeMintProof, freeMintRoot, keccak256(abi.encodePacked(msg.sender))), "YOU_ARE_NOT_WHITELISTED_TO_MINT_FREE");
        require(numberMinted(msg.sender) + 1 <=FREE_LIMIT,"CANNOT_MINT_MORE_THAN_ALLOWED");
        require(freeMintCount + 1 <= FREE_SUPPLY, "EXCEEDS_FREE_MINT_SUPPLY" );
        require(1 + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");

        addressBlockBought[msg.sender] = block.timestamp;
        freeMintCount += 1;
        _safeMint(msg.sender, 1);
    }

    function wlMint(uint256 numberOfTokens, bytes32[] memory proof, uint256 maxMint) external isSecured(2) payable{
        require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender, maxMint))),"PROOF_INVALID");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(numberOfTokens + wlMintcount <= WL_SUPPLY,"NOT_ENOUGH_PRESALE_SUPPLY");
        require(numberMinted(msg.sender) + numberOfTokens <= maxMint,"EXCEED_PRESALE_MINT_LIMIT");
        require(numberMinted(msg.sender) + numberOfTokens <= WL_LIMIT,"EXCEED_PRESALE_MINT_LIMIT");
        require(msg.value == WL_PRICE * numberOfTokens , "NOT_ENOUGH_ETH");

        addressBlockBought[msg.sender] = block.timestamp;
        wlMintcount += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function raffleMint(uint256 numberOfTokens, bytes32[] memory proof, uint256 maxMint) external isSecured(3) payable{
        require(MerkleProof.verify(proof, raffleRoot, keccak256(abi.encodePacked(msg.sender, maxMint))),"PROOF_INVALID");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(numberOfTokens + raffleMintCount + wlMintcount <= WL_SUPPLY + RAFFLE_SUPPLY,"NOT_ENOUGH_RAFFLE_SUPPLY");
        require(numberMinted(msg.sender) + numberOfTokens <= maxMint,"EXCEED_PRAFFLE_MINT_LIMIT");
        require(msg.value == WL_PRICE * numberOfTokens, "NOT_ENOUGH_ETH");

        addressBlockBought[msg.sender] = block.timestamp;
        raffleMintCount += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    //Essential
    function publicMint(uint64 expireTime, bytes memory sig) external isSecured(4) payable {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(1 + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(!mintedPublic[msg.sender],"CANNOT_MINT_MORE_THAN_ONE");
        require(msg.value == PUBLIC_PRICE * 1, "NOT_ENOUGH_ETH");

        usedDigests[digest] = true;
        mintedPublic[msg.sender] = true;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, 1);
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
    function togglePublicMintStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleRaffleMintStatus() external onlyOwner {
        isRaffleActive = !isRaffleActive;
    }

    function toggleFreeMintStatus() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }

    function toggleAllowListMintStatus() external onlyOwner {
        isAllowListActive = !isAllowListActive;
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

    function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
    }

    function setFreeRoot(bytes32 _freeRoot) external onlyOwner {
        freeMintRoot = _freeRoot;
    }

    function setRaffleRoot(bytes32 _raffleRoot) external onlyOwner {
        raffleRoot = _raffleRoot;
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