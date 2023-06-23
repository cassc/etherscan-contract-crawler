//SPDX-License-Identifier: Unlicense
// Creator: owenyuwono.eth
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "closedsea/src/OperatorFilterer.sol";

contract AIWZKD is
    ERC721A,
    ERC2981,
    Ownable,
    AccessControl,
    ReentrancyGuard,
    OperatorFilterer
{
    uint private maxSupply = 777;
    string public baseURI;
    uint256 public maxMint = 10;
    IERC721 public constant WZKD =
        IERC721(0xa626F0c2d01281D9f82bfb47Eb39f5Ef66a92d17);

    // Phases
    enum Phases {
        CLOSED,
        HOLDER,
        GOLDLIST,
        FREE,
        PUBLIC
    }
    mapping(Phases => bool) public phase;

    // Pricing
    mapping(Phases => uint256) public price;
    address constant RECEIVER_ADDRESS =
        0x9B0C5c21BA4D452934Ad4c1cb314fbcfCA132c7A;

    bool public operatorFilteringEnabled = true;
    bool private canClaim = false;

    // canMint modifier should contain the most common usecase between mint functions
    // (e.g. public mint, private mint, free mint, airdrop)
    modifier canMint(uint amount, Phases p) {
        uint256 supply = totalSupply();
        require(msg.value == price[p] * amount, "insufficient funds");
        require(supply + amount <= maxSupply, "exceeded max supply");
        require(msg.sender == tx.origin, "invalid source");
        require(!phase[Phases.CLOSED], "not open yet");
        _;
    }

    modifier onlyListed(bytes32[] calldata proof, bytes32 root) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, root, leaf), "invalid proof");
        _;
    }

    constructor(
        string memory uri
    ) ERC721A("Ai WzKd Series 1", "AIWZKD") Ownable() {
        baseURI = uri;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(RECEIVER_ADDRESS, 777); // 1000 = 10%
        _transferOwnership(RECEIVER_ADDRESS);
        _registerForOperatorFiltering();
        price[Phases.HOLDER] = 0.077 ether;
        price[Phases.GOLDLIST] = 0.077 ether;
        price[Phases.PUBLIC] = 0.077 ether;
        phase[Phases.HOLDER] = true;
        phase[Phases.PUBLIC] = true;
    }

    // Metadata
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) return "";

        return
            string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json"));
    }

    // HOLDER MINT
    mapping(address => uint256) public holderAux;

    function holderMint(
        uint64 amount
    ) external payable canMint(amount, Phases.HOLDER) nonReentrant {
        require(phase[Phases.HOLDER], "holder mint not opened");
        require(WZKD.balanceOf(msg.sender) > 0, "not a WZKD holder");
        require(
            holderAux[msg.sender] + amount <= maxMint,
            "exceeded holder mint quota"
        );

        holderAux[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    // PUBLIC MINT
    function mint(
        uint64 amount
    ) external payable canMint(amount, Phases.PUBLIC) nonReentrant {
        require(phase[Phases.PUBLIC], "public mint not opened");

        _safeMint(msg.sender, amount);
    }

    // GOLDLIST MINT
    bytes32 public goldlist;
    mapping(address => uint256) public goldAux;

    function setGoldlist(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        goldlist = root;
    }

    function goldlistMint(
        uint64 amount,
        bytes32[] calldata proof
    )
        external
        payable
        onlyListed(proof, goldlist)
        canMint(amount, Phases.GOLDLIST)
        nonReentrant
    {
        require(phase[Phases.GOLDLIST], "gold list mint not opened");
        require(
            goldAux[msg.sender] + amount <= maxMint,
            "exceeded holder mint quota"
        );

        goldAux[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    // Free Mint
    bytes32 public freelist;
    mapping(address => uint256) public freeAux;

    function setFreelist(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        freelist = root;
    }

    function freeMint(
        uint64 amount,
        bytes32[] calldata proof
    )
        external
        payable
        onlyListed(proof, freelist)
        canMint(amount, Phases.FREE)
        nonReentrant
    {
        require(phase[Phases.FREE], "free mint not opened");
        require(
            freeAux[msg.sender] + amount <= maxMint,
            "exceeded holder mint quota"
        );

        freeAux[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function airdrop(
        address wallet,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply, "exceeded max supply");
        _safeMint(wallet, amount);
    }

    function claimed(address target) external view returns (uint256) {
        return _getAux(target);
    }

    // Minting fee
    function setPrice(
        Phases _p,
        uint amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price[_p] = amount;
    }

    // Minting fee
    function setMaxSupply(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = amount;
    }

    function claim() external onlyOwner {
        require(canClaim, "cannot claim");
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function claim(address claimant) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool sent, ) = claimant.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function setCanClaim(bool v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        canClaim = v;
    }

    function setTokenURI(
        string calldata uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    // Phases
    function setPhase(
        Phases _phase,
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_phase != Phases.CLOSED) phase[Phases.CLOSED] = false;
        phase[_phase] = _status;
    }

    // Set default royalty to be used for all token sale
    function setDefaultRoyalty(
        address _receiver,
        uint96 _fraction
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _fraction);
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _fraction
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _fraction);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // Operator Filter Registry

    function setOperatorFilteringEnabled(
        bool value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}