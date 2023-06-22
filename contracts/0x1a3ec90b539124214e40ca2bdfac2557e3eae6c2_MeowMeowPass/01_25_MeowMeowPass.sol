//SPDX-License-Identifier: Unlicense
// Creator: owenyuwono.eth
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "closedsea/src/OperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract MeowMeowPass is
    ERC721A,
    ERC2981,
    ERC721ABurnable,
    ERC721AQueryable,
    PaymentSplitter,
    Ownable,
    AccessControl,
    ReentrancyGuard,
    OperatorFilterer
{
    uint private maxSupply = 1999;
    uint private maxMint = 5;
    string public baseURI;

    // Phases
    enum Phases {
        CLOSED,
        FREE,
        MEOWLIST,
        PUBLIC
    }
    mapping(Phases => bool) public phase;
    bytes32 public meowlist;
    bytes32 public freelist;

    // Pricing
    mapping(Phases => uint256) public price;
    address constant RECEIVER_ADDRESS =
        0xF8ec1fFaa6934C5FfCB383e43116239784BE9dCc;
    address[] public _payees = [RECEIVER_ADDRESS];
    uint256[] private _shares = [100];

    bool public operatorFilteringEnabled = true;

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
    )
        ERC721A("Meow Meow Pass", "MMP")
        PaymentSplitter(_payees, _shares)
        Ownable()
    {
        baseURI = uri;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, RECEIVER_ADDRESS);
        _setDefaultRoyalty(RECEIVER_ADDRESS, 690); // 1000 = 10%
        _transferOwnership(RECEIVER_ADDRESS);
        _registerForOperatorFiltering();
        price[Phases.PUBLIC] = 0.025 ether;
        price[Phases.MEOWLIST] = 0.019 ether;
        phase[Phases.CLOSED] = true;
    }

    // Metadata
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) return "";

        return
            string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json"));
    }

    function mint(
        uint64 amount
    ) external payable canMint(amount, Phases.PUBLIC) nonReentrant {
        require(phase[Phases.PUBLIC], "public mint not opened");

        _safeMint(msg.sender, amount);
    }

    function meowlistMint(
        uint64 amount,
        bytes32[] calldata proof
    )
        external
        payable
        onlyListed(proof, meowlist)
        canMint(amount, Phases.MEOWLIST)
        nonReentrant
    {
        require(phase[Phases.MEOWLIST], "meow meow list mint not opened");
        uint64 aux = _getAux(msg.sender);
        require(aux + amount <= maxMint, "quota reached");
        require(aux < 1, "already minted");

        _setAux(msg.sender, aux + amount);
        _safeMint(msg.sender, amount);
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
        uint64 aux = _getAux(msg.sender);
        require(aux + amount < maxMint, "quota reached");

        _setAux(msg.sender, aux + amount);
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

    function setMeowlistRoot(
        bytes32 root
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        meowlist = root;
    }

    function setFreelistRoot(
        bytes32 root
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        freelist = root;
    }

    // Minting fee
    function setMaxSupply(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = amount;
    }

    function setMaxMint(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMint = amount;
    }

    function claim() external {
        release(payable(msg.sender));
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
        override(ERC721A, ERC2981, IERC721A, AccessControl)
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
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}