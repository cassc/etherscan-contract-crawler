// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Utils
import "@openzeppelin/contracts/utils/Strings.sol";

// Security
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Contracts extending
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract SkulltoonsGenesis is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    // CONTRACT META DATA
    string public baseTokenURI;
    string public nonRevealedURI;
    address public requiredOwnContract;

    // CONTRACT STATE INFO
    bool public revealed = false;
    enum Phase {
        NOT_ACTIVE,
        PRE_SALE,
        SKULL_TOON_HOLDERS_MINT,
        PUBLIC
    }
    Phase phase;
    Phase constant default_phase = Phase.NOT_ACTIVE;

    // CONTRACT ADDRESS INFO
    address public royaltyAddress;

    // IMMUTABLE CONSTRAINTS
    uint256 public constant MAX_SUPPLY = 1777;

    // MUTABLE  CONSTRAINTS
    uint256 public MAX_TOKEN_HOLDERS_MINT_PER_WALLET = 1;
    uint256 public MAX_PUBLIC_PER_WALLET = 1;
    uint256 public ROYALTY_PERCENT = 7;

    // PHASE Based limit
    mapping(address => bool) private preSaleClaimedList;
    mapping(address => bool) private tokenGatedClaimedList;
    mapping(address => bool) private publicClaimedList;

    // SECURITY
    bytes32 private whiteListRoot;    

    constructor(
        string memory _baseTokenURI, 
        string memory _nonRevealedURI, 
        address _requiredOwnContract,
        bytes32 _whiteListRoot        
        ) 
        ERC721A("SkulltoonsGenesis", "SKTGEN") {
        baseTokenURI = _baseTokenURI;
        nonRevealedURI = _nonRevealedURI;
        requiredOwnContract = _requiredOwnContract;
        whiteListRoot = _whiteListRoot;        

        royaltyAddress = msg.sender;
    }
    

    // Business Logic
    function getAllowedMintCount(bytes32[] calldata _wlProof) internal view returns (uint) {
        uint allowedCount = 0;

        if (IERC721A(requiredOwnContract).balanceOf(msg.sender) >= 10) {
            allowedCount = 2;
        } else if (IERC721A(requiredOwnContract).balanceOf(msg.sender) >= 5) {
            allowedCount = 1;
        } else if (verifyWhiteList(_wlProof)) {
            allowedCount = 1;
        }        

        return allowedCount;
    }

    function hasSkulltoon() internal view returns (bool) {
        return IERC721A(requiredOwnContract).balanceOf(msg.sender) > 0;
    }

    function preSaleMint(bytes32[] calldata _wlProof) external payable nonReentrant {        
        uint allowedCount = getAllowedMintCount(_wlProof);
        
        require(phase == Phase.PRE_SALE, "Phase not set to PRE_SALE phase");
        require(preSaleClaimedList[msg.sender] == false, 'wallet already minted in presale phase');
        require(allowedCount > 0, 'Cannot premint - this address is not on whitelisted or holding the required amount of skulltoons tokens');
        require(_totalMinted() + allowedCount <= MAX_SUPPLY, "Not enough NFTs left!");        

        preSaleClaimedList[msg.sender] = true;

        _safeMint(msg.sender, allowedCount);
    }

    function tokenHoldersMint() external payable nonReentrant {
        require(phase == Phase.SKULL_TOON_HOLDERS_MINT, "Phase not set to SKULL_TOON_HOLDERS_MINT");
        require(tokenGatedClaimedList[msg.sender] == false, 'wallet already minted in token gated phase');
        require(hasSkulltoon(), "this address does not contain a skulltoon");
        require(_totalMinted() + MAX_TOKEN_HOLDERS_MINT_PER_WALLET <= MAX_SUPPLY, "Not enough NFTs left!");        

        tokenGatedClaimedList[msg.sender] = true;

        _safeMint(msg.sender, MAX_TOKEN_HOLDERS_MINT_PER_WALLET);
    }

    function publicMint() external payable nonReentrant {
        require(phase == Phase.PUBLIC, "Phase not set to PUBLIC");
        require(publicClaimedList[msg.sender] == false, 'wallet already minted in public phase');
        require(_totalMinted() + MAX_PUBLIC_PER_WALLET <= MAX_SUPPLY, "Not enough NFTs left!");        

        publicClaimedList[msg.sender] = true;

        _safeMint(msg.sender, MAX_PUBLIC_PER_WALLET);
    }

    function numberMinted(address wallet) external view returns (uint256) {
        return _numberMinted(wallet);
    }

    function verifyWhiteList(bytes32[] calldata merkleProof) internal view returns (bool) {
        require(whiteListRoot.length > 0, 'special list root is empty');
        return MerkleProof.verify(merkleProof, whiteListRoot, keccak256(abi.encodePacked(msg.sender)));
    }    

    /****************************************\
    *             OWNER FUNCTIONS            *
    \****************************************/

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner nonReentrant {
        baseTokenURI = _baseTokenURI;
    }

    function setNonRevealedTokenURI(string memory _nonRevealedURI) external onlyOwner nonReentrant {
        nonRevealedURI = _nonRevealedURI;
    }

    function setRequiredOwnContract(address _contract) external onlyOwner nonReentrant {
        requiredOwnContract = _contract;
    }

    function setRevealed(bool _reveal) external onlyOwner nonReentrant {
        revealed = _reveal;
    }

    function setCurrentPhase(Phase _phase) external onlyOwner nonReentrant {
        phase = _phase;
    }

    function setTokenHoldersMintAmount(uint8 amount) external onlyOwner nonReentrant {
        MAX_TOKEN_HOLDERS_MINT_PER_WALLET = amount;
    }

    function setPublicMintAmount(uint8 amount) external onlyOwner nonReentrant {
        MAX_PUBLIC_PER_WALLET = amount;
    }

    function reserve(uint8 quant) external onlyOwner nonReentrant {
        require(_totalMinted() + quant <= MAX_SUPPLY, "Not enough NFTs left!");
        _mint(msg.sender, quant);
    }

    function bulkAirDrop(IERC721A _token, address[] calldata _to, uint256[] calldata _id) external onlyOwner nonReentrant {
        require(_to.length == _id.length, "Receivers and IDs are different lengths");
        
        for (uint256 i = 0; i < _to.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
        }
    }

    function setWlRoot(bytes32 _merkleRoot) external onlyOwner nonReentrant {
        whiteListRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner nonReentrant {        
        payable(msg.sender).transfer(address(this).balance);
    }

    /****************************************\
    *           OVERRIDES & EXTRAS           *
    \****************************************/

    function getCurrentPhase() external view returns (string memory) {
        // Error handling for input
        require(uint8(phase) <= 3);

        if (Phase.NOT_ACTIVE == phase) return "NOT_ACTIVE";
        if (Phase.PRE_SALE == phase) return "PRE_SALE";
        if (Phase.SKULL_TOON_HOLDERS_MINT == phase)
            return "SKULL_TOON_HOLDERS_MINT";
        if (Phase.PUBLIC == phase) return "PUBLIC";

        return "NOT_A_VALID_PHASE";
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        if (revealed) {
            return
                string(
                    abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
        }
        else {
            return nonRevealedURI;
        }            
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // EIP-2981: NFT Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist");        
        return (royaltyAddress, ((salePrice / 100) * ROYALTY_PERCENT));
    }    
}