// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DefaultOperatorFilterer.sol";
import "./Delegates.sol";

contract AhBoysvsAhGirls is
    ERC721A,
    ReentrancyGuard,
    Delegated,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(address => uint256) private whitelistMintAddresses;
    mapping(address => uint256) private publicMintAddresses;

    bytes32 constant HASH_1 = keccak256("BATCH_1");
    address public SIGNER = 0xB7eB2287bf010E7Cb0ADaF2De76e2849d4bF5E86;
    address public crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

    address public gnosisAddress;
    address public JTeamAddress = 0xa2735eFF40420FEcb6E1B659dC2624F49d85abF1;
    address public JAddress = 0xa671041Fd8058De2Cde34250dfAc7E3a858B50f1;
    address public KAddress = 0xaebf2D9D319c2C51163A75543a736372Fc4142e8;
    address public DAddress = 0x51B7848B7f2b95c514a54FbeC3Ae23D1Fa30546E;
    address public FAddress = 0x61e9948A87C865F135A9c70AC6A8e5ec5c501040;
    address public NAddress = 0x10b21B6370d551Ac3435dE758F79356996B68C8E;

    // ======== SUPPLY ========
    uint256 public MAX_SUPPLY = 1000;
    uint256 public WHITELIST_SUPPLY = 201;
    uint256 public WHITELIST_ALLOCATION = 15;
    uint256 public PUBLIC_ALLOCATION = 15;

    // ======== PRICE ========
    uint256 public whitelistPrice = 0.068 ether;
    uint256 public mintPrice = 0.088 ether;

    // ======== SALE TIME ========
    uint256 public whitelistBatchTime = 1676548800; // Date and time (GMT): Friday, 16 February 2023 12:00:00
    uint256 public publicBatchTime = 1676635200; // Date and time (GMT): Friday, 17 February 2023 12:00:00

    // ======== METADATA ========
    bool public isRevealed = false;
    string public _baseTokenURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("Ah Boys vs Ah Girls", "ABAG") {}

    // ======== MINTING ========
    function crossmintPublic(address _to, uint256 _quantity) public payable
        hasMintStarted(publicBatchTime)
        ethValueCheck(mintPrice * _quantity) {
        require(msg.sender == crossmintAddress,
        "This function is for Crossmint only."
        );
        _safeMint(_to, _quantity);
    }

    function whitelistMint(bytes memory _signature, uint256 _quantity)
        external
        payable
        withinWhitelistSupply(_quantity)
        withinIndividualAllocatedSupply(_quantity)
        hasMintStarted(whitelistBatchTime)
        signerIsValid(HASH_1, _signature)
        ethValueCheck(whitelistPrice * _quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity)
        external
        payable
        withinPublicIndividualAllocatedSupply(_quantity)
        hasMintStarted(publicBatchTime)
        ethValueCheck(mintPrice * _quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity)
        external
        onlyOwner
        withinSupply(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    // ======== SETTERS ========
    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    function setSigner(address _signer) external onlyOwner {
        SIGNER = _signer;
    }

    function setBaseURI(string calldata baseURI) external onlyDelegates {
        _baseTokenURI = baseURI;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setWhitelistSupply(uint256 _supply) external onlyDelegates {
        WHITELIST_SUPPLY = _supply;
    }

    function setPrice(uint256 _whitelist, uint256 _public)
        external
        onlyOwner
    {
        whitelistPrice = _whitelist;
        mintPrice = _public;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyDelegates {
        notRevealedURI = _notRevealedURI;
    }

    function setIsRevealed(bool _reveal) external onlyDelegates {
        isRevealed = _reveal;
    }

    function setMintTime(uint256 _whitelist, uint256 _public)
        external
        onlyDelegates
    {
        whitelistBatchTime = _whitelist;
        publicBatchTime = _public;
    }

    function setWithdrawAddresses(address _JTeamAddress, address _JAddress, address _KAddress, address _DAddress, address _FAddress, address _NAddress)
        external
        onlyDelegates
    {
        JTeamAddress = _JTeamAddress;
        JAddress = _JAddress;
        KAddress = _KAddress;
        DAddress = _DAddress;
        FAddress = _FAddress;
        NAddress = _NAddress;
    }

    function setGnosisAddress(address _gnosisAddress)
    external
    onlyDelegates
    {
        gnosisAddress = _gnosisAddress;
    }

    // ======== WITHDRAW ========

    function withdraw() external onlyOwner {
        require(gnosisAddress != address(0), "Gnosis address not set");

        // This will pay the gnosis wallet 50% of the initial sale.
        // =============================================================================
        (bool gs, ) = payable(gnosisAddress).call{
            value: (address(this).balance * 50) / 100
        }("");
        require(gs);
        // =============================================================================

        // This will payout the external members the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool jts, ) = payable(JTeamAddress).call{
            value: (address(this).balance * 25) / 100
        }("");
        require(jts);

        (bool js, ) = payable(JAddress).call{
            value: (address(this).balance * 1667/200) / 100
        }("");
        require(js);

        (bool ks, ) = payable(KAddress).call{
            value: (address(this).balance * 1667/200) / 100
        }("");
        require(ks);

        (bool ds, ) = payable(DAddress).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(ds);

        (bool fs, ) = payable(FAddress).call{
            value: (address(this).balance * 3) / 100
        }("");
        require(fs);

        (bool ns, ) = payable(NAddress).call{
            value: (address(this).balance * 33/100) / 100
        }("");
        require(ns);
    }

    // ========= GETTERS ===========
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) {
            return notRevealedURI;
        }

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    baseExtension
                )
            );
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    // ===== OPENSEA OVERRIDES =====

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) payable  onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ===== MODIFIERS =====

    modifier withinSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeded max supply");
        _;
    }

    modifier withinWhitelistSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= WHITELIST_SUPPLY,
            "Exceeded whitelist supply"
        );
        _;
    }

    modifier withinIndividualAllocatedSupply(uint256 _quantity) {
        require(
            whitelistMintAddresses[msg.sender] + _quantity <= WHITELIST_ALLOCATION,
            "Exceeded individual whitelist allocation"
        );
        whitelistMintAddresses[msg.sender] = whitelistMintAddresses[msg.sender] +
            _quantity;
        _;
    }

    modifier withinPublicIndividualAllocatedSupply(uint256 _quantity) {
        require(
            publicMintAddresses[msg.sender] + _quantity <= PUBLIC_ALLOCATION,
            "Exceeded individual public allocation"
        );
        publicMintAddresses[msg.sender] = publicMintAddresses[msg.sender] +
            _quantity;
        _;
    }

    modifier signerIsValid(bytes32 _hash, bytes memory _signature) {
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), _hash, msg.sender)
        );
        address signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );
        require(signer == SIGNER, "Signature not valid");
        _;
    }

    modifier alreadyMinted(mapping(address => bool) storage _map) {
        require(!_map[msg.sender], "Already minted");
        _map[msg.sender] = true;
        _;
    }

    modifier ethValueCheck(uint256 _price) {
        require(msg.value >= _price, "Not enough eth sent");
        _;
    }

    modifier hasMintStarted(uint256 _startTime) {
        require(block.timestamp >= _startTime, "Not yet started");
        _;
    }
}