// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


//  ::::::::  :::    :::  ::::::::   ::::::::   ::::::::    :::            :::      ::::::::  
// :+:    :+: :+:    :+: :+:    :+: :+:    :+: :+:    :+:   :+:          :+: :+:   :+:    :+: 
// +:+        +:+    +:+ +:+    +:+ +:+        +:+    +:+   +:+         +:+   +:+  +:+        
// +#+        +#++:++#++ +#+    +:+ +#+        +#+    +:+   +#+        +#++:++#++: :#:        
// +#+        +#+    +#+ +#+    +#+ +#+        +#+    +#+   +#+        +#+     +#+ +#+   +#+# 
// #+#    #+# #+#    #+# #+#    #+# #+#    #+# #+#    #+#   #+#        #+#     #+# #+#    #+# 
//  ########  ###    ###  ########   ########   ########    ########## ###     ###  ########  


/// @title: ChocoLAG
/// @author: Shunichiro
/// @dev: This contract using NFTBoil (https://github.com/syunduel/NFTBoil)

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "contract-allow-list/contracts/ERC721AntiScam/extensions/ERC721AntiScamControl.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract ChocoLAG is ERC721AntiScamControl, RevokableDefaultOperatorFilterer, EIP2981RoyaltyOverrideCore, AccessControl, Pausable  {
    using Strings for uint256;

    uint256 constant public MAX_SUPPLY = 5000;

    uint256 public salePhase = 1; // 1: Min1, 2: Mint2, 3: Mint3, 4: Public Sale
    uint256 public maxMintPerWallet = 100;
    uint256 public maxMintPerTx = 10;
    bool public mintable = false;

    string private baseURI = "";
    string constant private BASE_EXTENSION = ".json";

    bytes32 public merkleRootMint1;
    bytes32 public merkleRootMint2;
    bytes32 public merkleRootMint3;
    mapping(address => uint256) private minted;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721Psi(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(TokenRoyalty(0x7640248Ea19B09AF3bAf4fd2145dA3cc30e604c2, 1000));
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721Psi.tokenURI(tokenId), BASE_EXTENSION));
    }

    /**
     * @notice Set the merkle root for the Mint1
     */
    function setMerkleRootMint1(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRootMint1 = _merkleRoot;
    }

    /**
     * @notice Set the merkle root for the Mint2
     */
    function setMerkleRootMint2(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRootMint2 = _merkleRoot;
    }

    /**
     * @notice Set the merkle root for the Mint3
     */
    function setMerkleRootMint3(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRootMint3 = _merkleRoot;
    }

    function getCurrentCost() public pure returns (uint256) {
        return 0 ether;
    }

    function mint1(uint256 _mintAmount, uint256 _mint1Max, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
        callerIsUser
    {
        mintCheck(_mintAmount);
        require(salePhase == 1, "Mint1 is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _mint1Max));
        require(
            MerkleProof.verify(_merkleProof, merkleRootMint1, leaf),
            "Invalid Merkle Proof"
        );
        require(
            minted[msg.sender] + _mintAmount <= _mint1Max,
            "Already minted max"
        );

        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint2(uint256 _mintAmount, uint256 _mint2Max, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
        callerIsUser
    {
        mintCheck(_mintAmount);
        require(salePhase == 2, "Mint2 is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _mint2Max));
        require(
            MerkleProof.verify(_merkleProof, merkleRootMint2, leaf),
            "Invalid Merkle Proof"
        );
        require(
            minted[msg.sender] + _mintAmount <= _mint2Max,
            "Already minted max"
        );
        require(
            _mintAmount <= maxMintPerTx,
            "Mint amount over"
        );

        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint3(uint256 _mintAmount, uint256 _mint3Max, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
        callerIsUser
    {
        mintCheck(_mintAmount);
        require(salePhase == 3, "Mint3 is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _mint3Max));
        require(
            MerkleProof.verify(_merkleProof, merkleRootMint3, leaf),
            "Invalid Merkle Proof"
        );
        require(
            minted[msg.sender] + _mintAmount <= _mint3Max,
            "Already minted max"
        );
        require(
            _mintAmount <= maxMintPerTx,
            "Mint amount over"
        );

        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount)
        public
        payable
        whenNotPaused
        whenMintable
        callerIsUser
    {
        mintCheck(_mintAmount);
        require(salePhase == 4, "Public mint is not active.");
        require(
            _mintAmount <= maxMintPerTx,
            "Mint amount over"
        );

        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function adminMint(address _address, uint256 _mintAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintCheck(_mintAmount);
       _safeMint(_address, _mintAmount);
    }

    function mintCheck(uint256 _mintAmount) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        uint256 cost = getCurrentCost() * _mintAmount;
        require(msg.value >= cost, "Not enough funds");

        require(
            minted[msg.sender] + _mintAmount <= maxMintPerWallet,
            "Already minted max"
        );
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MAXSUPPLY over"
        );
    }

    function setSalePhase(uint256 _salePhase) public onlyRole(DEFAULT_ADMIN_ROLE) {
        salePhase = _salePhase;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintPerTx = _maxMintPerTx;
    }

    function setMintable(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }

    function getMintedCount() public view returns (uint256) {
        return minted[msg.sender];
    }

    function burn(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "Barn can only be NFT owned by owner");
        super._burn(_tokenId);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    //
    // AccessControl
    //

    function grantDefaultAdminRole(address candidate) external onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, candidate);
    }

    function revokeDefaultAdminRole(address candidate) external onlyOwner {
        revokeRole(DEFAULT_ADMIN_ROLE, candidate);
    }

    //
    // ContractAllowList ERC721RestrictApprove
    //

    function addLocalContractAllowList(address transferer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        override
        view
        returns(address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCAL(address calAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setCAL(calAddress);
    }

    function setCALLevel(uint256 level) external onlyRole(DEFAULT_ADMIN_ROLE) {
        CALLevel = level;
    }

    function setEnableRestrict(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        enableRestrict = value;
    }

    //
    // ContractAllowList ERC721Lockable
    //

    function setEnableLock(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        enableLock = value;
    }

    //
    // ContractAllowList ERC721AntiScamControl
    //

    function grantLockerRole(address candidate) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantLockerRole(candidate);
    }

    function revokeLockerRole(address candidate) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeLockerRole(candidate);
    }

    //
    // RevokableDefaultOperatorFilterer
    //

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    //
    // royalty-registry-solidity
    //

    /**
     * @dev See {IEIP2981RoyaltyOverride-setTokenRoyalties}.
     */
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalties(royaltyConfigs);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setDefaultRoyalty}.
     */
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(royalty);
    }

    //
    // supportsInterface
    //

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC721AntiScam, EIP2981RoyaltyOverrideCore) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Psi.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }
}