// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BobaInu is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant maxSupply = 3333;

    bytes32 public ogMerkleRoot;
    bytes32 public collabWlMerkleRoot;
    bytes32 public communityWlMerkleRoot;
    
    uint256 public MAX_MINT_OG = 2;
    uint256 public MAX_MINT_WL = 1;
    uint256 public MAX_MINT_PUBLIC = 2;

    uint256 public currentPhase = 0;

    uint256 constant OG_SPOTS = 374;
    uint256 constant COLLAB_WL_SPOTS = 2000;
    uint256 constant COMMUNITY_WL_SPOTS = 884;  

    uint256 totalOgMints = 0;
    uint256 totalCollabMints = 0;
    uint256 totalCommunityMints = 0;
    uint256 totalPublicMints = 0;

    mapping(address => uint256) private ogMints;
    mapping(address => uint256) private wlMints;
    mapping(address => uint256) private publicMints;

    bool public isRevealed = false;
    string private baseUri;

    constructor(string memory _baseUri) ERC721A("Boba Inu", "BOBAINU") {
        baseUri = _baseUri;
        _safeMint(msg.sender, 33);
    }

    function flipSalePhase(uint256 _phase) external onlyOwner {
        require(_phase >= 0 && _phase <= 3, "Invalid phase");
        currentPhase = _phase;
    }

    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setMaxOgMint(uint256 _quantity) external onlyOwner {
        MAX_MINT_OG = _quantity;
    }

    function setMaxWlMint(uint256 _quantity) external onlyOwner {
        MAX_MINT_WL = _quantity;
    }

    function setMaxPublicMint(uint256 _quantity) external onlyOwner {
        MAX_MINT_PUBLIC = _quantity;
    }

    function withdrawAll(address _address) external onlyOwner {
        (bool success, ) = payable(_address).call{value: address(this).balance}("");
        require(success);
    }

    function setOgMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    function setCollabWlMerkleRoot(bytes32 _collabWlMerkleRoot)
        external
        onlyOwner
    {
        collabWlMerkleRoot = _collabWlMerkleRoot;
    }

    function setCommunityWlMerkleRoot(bytes32 _communityWlMerkleRoot)
        external
        onlyOwner
    {
        communityWlMerkleRoot = _communityWlMerkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        isRevealed ? tokenId.toString() : "unrevealed",
                        ".json"
                    )
                )
                : "";
    }

    function mintOg(uint256 quantity, bytes32[] calldata merkleProof)
        external
        nonReentrant
    {
        require(currentPhase >= 1, "Sale is not open");
        require(quantity > 0, "Must mint at least one Boba Inu");
        require(quantity <= MAX_MINT_OG, "Minting too many tokens as once");
        require(
            MerkleProof.verify(
                merkleProof,
                ogMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the og list"
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Minting would exceed max supply"
        );
        require(totalOgMints + quantity <= OG_SPOTS, "Og mint sold out");
        require(
            ogMints[msg.sender] + quantity <= MAX_MINT_OG,
            "Og mint for this wallet reached"
        );

        totalOgMints += quantity;
        ogMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mintCollabWl(uint256 quantity, bytes32[] calldata merkleProof)
        external
        nonReentrant
    {
        require(currentPhase == 1, "Not currently collab WL phase");
        require(quantity > 0, "Must mint at least one Boba Inu");
        require(quantity <= MAX_MINT_WL, "Minting too many tokens as once");
        require(
            MerkleProof.verify(
                merkleProof,
                collabWlMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the collab wl"
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Minting would exceed max supply"
        );
        require(
            totalCollabMints + quantity <= COLLAB_WL_SPOTS,
            "Collab wl sold out"
        );
        require(
            wlMints[msg.sender] + quantity <= MAX_MINT_WL,
            "Wl mint for this wallet reached"
        );

        totalCollabMints += quantity;
        wlMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mintCommunityWl(uint256 quantity, bytes32[] calldata merkleProof)
        external
        nonReentrant
    {
        require(currentPhase == 2, "Not currently community WL phase");
        require(quantity > 0, "Must mint at least one Boba Inu");
        require(quantity <= MAX_MINT_WL, "Minting too many tokens as once");
        require(
            MerkleProof.verify(
                merkleProof,
                communityWlMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the community wl"
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Minting would exceed max supply"
        );
        require(
            totalCommunityMints + quantity <= COMMUNITY_WL_SPOTS,
            "Community wl sold out"
        );
        require(
            wlMints[msg.sender] + quantity <= MAX_MINT_WL,
            "Wl mint for this wallet reached"
        );

        totalCommunityMints += quantity;
        wlMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mintPublic(uint256 quantity) external nonReentrant {
        require(currentPhase == 3, "Not currently public phase");
        require(quantity > 0, "Must mint at least one Boba Inu");
        require(quantity <= MAX_MINT_PUBLIC, "Minting too many tokens as once");
        require(
            totalSupply() + quantity <= maxSupply,
            "Minting would exceed max supply"
        );
        require(
            publicMints[msg.sender] + quantity <= MAX_MINT_PUBLIC,
            "Mint for this wallet reached"
        );

        totalPublicMints += quantity;
        publicMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function ogListed(address _wallet, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                ogMerkleRoot,
                keccak256(abi.encodePacked(_wallet))
            );
    }

    function collabWhiteListed(address _wallet, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                collabWlMerkleRoot,
                keccak256(abi.encodePacked(_wallet))
            );
    }

    function communityWhiteListed(address _wallet, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                communityWlMerkleRoot,
                keccak256(abi.encodePacked(_wallet))
            );
    }

    function isPhaseSoldOut(uint256 _phase) public view returns (bool) {
        require(_phase >= 1 && _phase <= 3, "Not a valid phase");
        if (_phase == 1) {
            return totalOgMints == OG_SPOTS;
        } else if (_phase == 2) {
            return totalCollabMints == COLLAB_WL_SPOTS;
        } else if (_phase == 3) {
            return totalCommunityMints == COMMUNITY_WL_SPOTS;
        } else {
            return totalSupply() == maxSupply;
        }
    }

    function quantityMinted(address _wallet, uint256 _phase) public view returns (uint256) {
        require(_phase >= 1 && _phase <= 3, "Not a valid phase");
        if (_phase == 1 || _phase == 2) {
            return wlMints[_wallet];
        } else {
            return publicMints[_wallet];
        }
    }

    function quantityOgMinted(address _wallet) public view returns (uint256) {
        return ogMints[_wallet];
    }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}