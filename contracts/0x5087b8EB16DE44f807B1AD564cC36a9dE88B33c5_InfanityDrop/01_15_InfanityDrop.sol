// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

contract InfanityDrop is ERC721A, DefaultOperatorFilterer, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string public baseURI;
    uint256 public MAX_LIMIT_PER_WHITELIST_ADDRS = 3;
    uint256 public MAX_LIMIT_PER_AIRDROP_ADDRS = 1;
    uint256 public MAX_LIMIT_PER_PUBLIC_ADDRS = 5;
    uint256 public MAX_PER_TX = 10;

    uint256 public mintPriceInWei = 0.1 ether;
    uint256 public MAX_SUPPLY = 400;

    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public whitelistMinted;

    bytes32 public airdropMerkleRoot;
    mapping(address => uint256) public airdropMinted;

    mapping(address => uint256) public publicMintMinted;

    bool public isPublicMintOpen;
    bool public isWhitelistMintOpen;
    bool public isAirdropMintOpen;

    // withdrawal variables
    address[] public wallets;
    uint256[] public walletsShares;
    uint256 public totalShares;

    modifier onlyHasRole(bytes32 _role) {
        require(hasRole(_role, msg.sender), "Caller does not have role");
        _;
    }

    constructor() ERC721A("Infanity Drop", "INF") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function whitelistMint(
        uint256 _numberOfTokenToMint,
        bytes32[] calldata _proof
    ) external payable {
        require(isWhitelistMintOpen, "Drop: Not yet open.");

        require(
            _verifySenderProof(msg.sender, whitelistMerkleRoot, _proof),
            "Drop: invalid proof"
        );

        require(
            whitelistMinted[msg.sender] + _numberOfTokenToMint <=
                MAX_LIMIT_PER_WHITELIST_ADDRS,
            "Drop: Exceed max whitelist allowance"
        );

        require(
            _totalMinted() + _numberOfTokenToMint <= MAX_SUPPLY,
            "Drop: Exceeds max supply."
        );

        require(
            _numberOfTokenToMint * mintPriceInWei == msg.value,
            "Drop: Invalid funds provided."
        );
        
        whitelistMinted[msg.sender] += _numberOfTokenToMint;
        _safeMint(msg.sender, _numberOfTokenToMint);
    }

    function publicMint(uint256 _quantity) public payable {
        require(isPublicMintOpen, "Drop: Not yet open.");

        require(
            _totalMinted() + _quantity <= MAX_SUPPLY,
            "Drop: Exceeds max supply."
        );
        require(
            publicMintMinted[msg.sender] + _quantity <= MAX_LIMIT_PER_PUBLIC_ADDRS, "Drop: max limit per address exceeded"
        );
        require(
            _quantity * mintPriceInWei == msg.value,
            "Drop: Invalid funds provided."
        );

        publicMintMinted[msg.sender] += _quantity;

        _safeMint(msg.sender, _quantity);
    }

    function publicMint(address to, uint256 _quantity) public onlyHasRole(MINTER_ROLE) {
        require(isPublicMintOpen, "Drop: Not yet open.");

        require(
            _totalMinted() + _quantity <= MAX_SUPPLY,
            "Drop: Exceeds max supply."
        );
        require(
            _quantity <= MAX_PER_TX,
            "Drop: Exceeds max per transaction."
        );

        _safeMint(to, _quantity);
    }

    function airdropMint(
        uint256 _numberOfTokenToMint,
        bytes32[] calldata _proof
    ) external payable {
        require(isAirdropMintOpen, "Drop: Not yet open.");

        require(
            _verifySenderProof(msg.sender, airdropMerkleRoot, _proof),
            "Drop: invalid proof"
        );

        require(
            airdropMinted[msg.sender] + _numberOfTokenToMint <=
                MAX_LIMIT_PER_AIRDROP_ADDRS,
            "Drop: Exceed max whitelist allowance"
        );

        require(
            _totalMinted() + _numberOfTokenToMint <= MAX_SUPPLY,
            "Drop: Exceeds max supply."
        );
        
        airdropMinted[msg.sender] += _numberOfTokenToMint;
        _safeMint(msg.sender, _numberOfTokenToMint);
    }

    function isWhitelistedAddress(address toCheck, bytes32 merkleRoot, bytes32[] calldata _proof) external pure returns (bool) {
        return _verifySenderProof(toCheck, merkleRoot, _proof);
    }

    // === Admin === //

    function toggleWhitelistMintState() external onlyHasRole(ADMIN_ROLE) {
        isWhitelistMintOpen = !isWhitelistMintOpen;
    }

    function togglePublicMintState() external onlyHasRole(ADMIN_ROLE) {
        isPublicMintOpen = !isPublicMintOpen;
    }

    function toggleAirdropMintState() external onlyHasRole(ADMIN_ROLE) {
        isAirdropMintOpen = !isAirdropMintOpen;
    }


    function updateBaseUri(string memory newURI) external onlyHasRole(ADMIN_ROLE) {
        baseURI = newURI;
    }

    function updateMintPrice(uint256 _mintPriceInWei) external onlyHasRole(ADMIN_ROLE) {
        mintPriceInWei = _mintPriceInWei;
    }

    function updateMintLimitPerAddress(uint256 _mintLimit) external onlyHasRole(ADMIN_ROLE) {
        MAX_LIMIT_PER_WHITELIST_ADDRS = _mintLimit;
    }

    function updateAirdropLimitPerAddress(uint256 _mintLimit) external onlyHasRole(ADMIN_ROLE) {
        MAX_LIMIT_PER_AIRDROP_ADDRS = _mintLimit;
    }

    function updatePublicMintLimitPerAddress(uint256 _mintLimit) external onlyHasRole(ADMIN_ROLE) {
        MAX_LIMIT_PER_PUBLIC_ADDRS = _mintLimit;
    }

    function updateMintLimitPerTx(uint256 _mintLimit) external onlyHasRole(ADMIN_ROLE) {
        MAX_PER_TX = _mintLimit;
    }

    function updateMaxSupply(uint256 _max) external onlyHasRole(ADMIN_ROLE) {
        MAX_SUPPLY = _max;
    }

     // === Withdrawal ===

    /// @dev Set wallets shares
    /// @param _wallets The wallets
    /// @param _walletsShares The wallets shares
    function setWithdrawalInfo(
        address[] memory _wallets,
        uint256[] memory _walletsShares
    ) public onlyHasRole(ADMIN_ROLE) {
        require(_wallets.length == _walletsShares.length, "not equal");
        wallets = _wallets;
        walletsShares = _walletsShares;

        totalShares = 0;
        for (uint256 i = 0; i < _walletsShares.length; i++) {
            totalShares += _walletsShares[i];
        }
    }


    /// @dev Withdraw contract native token balance
    function withdraw() external onlyHasRole(ADMIN_ROLE) {
        require(address(this).balance > 0, "no eth to withdraw");
        uint256 totalReceived = address(this).balance;
        for (uint256 i = 0; i < walletsShares.length; i++) {
            uint256 payment = (totalReceived * walletsShares[i]) / totalShares;
            Address.sendValue(payable(wallets[i]), payment);
        }
    }

    /**
     * @dev Set whitelist address
     * @param _whitelistMerkleRoot The MerkleRoot
     */
    function setWhitelistMerkleRoot (bytes32 _whitelistMerkleRoot) external onlyHasRole(ADMIN_ROLE){
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    /**
     * @dev Set whitelist airdrop address
     * @param _airdropMerkleRoot The MerkleRoot
     */
    function setAirdropMerkleRoot (bytes32 _airdropMerkleRoot) external onlyHasRole(ADMIN_ROLE){
        airdropMerkleRoot = _airdropMerkleRoot;
    }


    // === Verify MerkleProof === //

    function _verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _verifySenderProof(
        address sender,
        bytes32 merkleRoot,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return _verify(proof, merkleRoot, leaf);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }


    function setApprovalForAll(
        address operator, 
        bool approved
    ) 
    public 
    override 
    onlyAllowedOperatorApproval(
        operator
    ) {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}