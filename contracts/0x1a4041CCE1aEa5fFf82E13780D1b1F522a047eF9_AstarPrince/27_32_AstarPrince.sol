// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//     :::      :::::::: ::::::::::: :::     :::::::::                 
//   :+: :+:   :+:    :+:    :+:   :+: :+:   :+:    :+:                
//  +:+   +:+  +:+           +:+  +:+   +:+  +:+    +:+                
// +#++:++#++: +#++:++#++    +#+ +#++:++#++: +#++:++#:                 
// +#+     +#+        +#+    +#+ +#+     +#+ +#+    +#+                
// #+#     #+# #+#    #+#    #+# #+#     #+# #+#    #+#                
// ###     ###  ########     ### ###     ### ###    ###                
// :::::::::  :::::::::  ::::::::::: ::::    :::  ::::::::  :::::::::: 
// :+:    :+: :+:    :+:     :+:     :+:+:   :+: :+:    :+: :+:        
// +:+    +:+ +:+    +:+     +:+     :+:+:+  +:+ +:+        +:+        
// +#++:++#+  +#++:++#:      +#+     +#+ +:+ +#+ +#+        +#++:++#   
// +#+        +#+    +#+     +#+     +#+  +#+#+# +#+        +#+        
// #+#        #+#    #+#     #+#     #+#   #+#+# #+#    #+# #+#        
// ###        ###    ### ########### ###    ####  ########  ########## 

/// @title: AstarPrince
/// @author: Shunichiro
/// @dev: This contract using NFTBoil (https://github.com/syunduel/NFTBoil)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "./libs/OpenSea/operator-filter-registry/DefaultOperatorFilterer.sol";

// This NFT License is a16z Can't be Evil Lisence
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract AstarPrince is DefaultOperatorFilterer, ERC721AntiScam, ERC2981, Pausable, CantBeEvil(LicenseVersion.PUBLIC)  {
    using Strings for uint256;

    string private baseURI = "";

    uint256 public preCost = 0.005 ether;
    uint256 public publicCost = 0.005 ether;
    uint256 public salePhase = 1; // 1: FreeMint, 2: 1st Presale, 3: 2nd Presale, 4: Public Sale
    bool public mintable = false;
    uint256 public maxMintPerWallet = 300;
    uint256 public maxMintPerTx = 5;

    address public royaltyAddress = 0x7640248Ea19B09AF3bAf4fd2145dA3cc30e604c2;
    uint96 public royaltyFee = 1000;

    uint256 constant public MAX_SUPPLY = 5555;
    string constant private BASE_EXTENSION = ".json";
    address constant private DEFAULT_ROYALITY_ADDRESS = 0x7640248Ea19B09AF3bAf4fd2145dA3cc30e604c2;

    bytes32 public merkleRootFreeMint;
    bytes32 public merkleRootPreMint1;
    bytes32 public merkleRootPreMint2;
    mapping(address => uint256) private claimed;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        _setDefaultRoyalty(DEFAULT_ROYALITY_ADDRESS, royaltyFee);
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the FreeMint
     */
    function setMerkleRootFreeMint(bytes32 _merkleRoot) external onlyOwner {
        merkleRootFreeMint = _merkleRoot;
    }

    /**
     * @notice Set the merkle root for the PreMint1
     */
    function setMerkleRootPreMint1(bytes32 _merkleRoot) external onlyOwner {
        merkleRootPreMint1 = _merkleRoot;
    }

    /**
     * @notice Set the merkle root for the PreMint2
     */
    function setMerkleRootPreMint2(bytes32 _merkleRoot) external onlyOwner {
        merkleRootPreMint2 = _merkleRoot;
    }

    function freeMint(uint256 _mintAmount, uint256 _freeMintMax, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
        callerIsUser
    {
        uint256 cost = 0;
        mintCheck(_mintAmount,  cost);
        require(salePhase == 1, "FreeMint is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _freeMintMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRootFreeMint, leaf),
            "Invalid Merkle Proof"
        );

        require(
            claimed[msg.sender] + _mintAmount <= _freeMintMax,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
        claimed[msg.sender] += _mintAmount;
    }

    function preMint1(uint256 _mintAmount, uint256 _preMint1Max, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
        callerIsUser
    {
        uint256 cost = preCost * _mintAmount;
        mintCheck(_mintAmount,  cost);
        require(salePhase == 2, "1st Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _preMint1Max));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPreMint1, leaf),
            "Invalid Merkle Proof"
        );

        require(
            claimed[msg.sender] + _mintAmount <= _preMint1Max,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
        claimed[msg.sender] += _mintAmount;
    }

    function preMint2(uint256 _mintAmount, uint256 _preMint2Max, bytes32[] calldata _merkleProof)
        public
        payable
        whenNotPaused
        whenMintable
        callerIsUser
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(salePhase == 3, "2nd Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _preMint2Max));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPreMint2, leaf),
            "Invalid Merkle Proof"
        );
        require(
            claimed[msg.sender] + _mintAmount <= _preMint2Max,
            "Already claimed max"
        );
        require(
            _mintAmount <= maxMintPerTx,
            "Mint amount over"
        );

        _mint(msg.sender, _mintAmount);
        claimed[msg.sender] += _mintAmount;
    }

    function publicMint(uint256 _mintAmount) public
        payable
        whenNotPaused
        whenMintable
        callerIsUser
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(salePhase == 4, "Public mint is not active.");
        require(
            _mintAmount <= maxMintPerTx,
            "Mint amount over"
        );
        require(
            claimed[msg.sender] + _mintAmount <= maxMintPerWallet,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
        claimed[msg.sender] += _mintAmount;
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 cost
    ) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MAXSUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
       _mint(_address, count);
    }

    function setSalePhase(uint256 _salePhase) public onlyOwner {
        salePhase = _salePhase;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function getCurrentCost() public view returns (uint256) {
        if (salePhase == 1) {
            return 0 ether;
        } else if (salePhase == 2 || salePhase == 3) {
            return preCost;
        } else {
            return publicCost;
        }
    }

    function getMintedCount() public view returns (uint256) {
        return claimed[msg.sender];
    }

    function burn(uint256 _tokenId) external onlyOwner {
        require(msg.sender == ownerOf(_tokenId), "Barn can only be NFT owned by owner");
        super._burn(_tokenId);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    //
    // OpenSea operator-filter-registry
    //

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

    //
    // ContractAllowList ERC721RestrictApprove
    //

    function addLocalContractAllowList(address transferer) external onlyOwner {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyOwner {
        _removeLocalContractAllowList(transferer);
    }

    function setCAL(address calAddress) external onlyOwner {
        _setCAL(calAddress);
    }

    function setCALLevel(uint256 level) external onlyOwner {
        CALLevel = level;
    }

    function setEnableRestrict(bool value) external onlyOwner {
        enableRestrict = value;
    }

    //
    // ContractAllowList ERC721Lockable
    //

    function setContractLock(LockStatus lockStatus) external onlyOwner {
        _setContractLock(lockStatus);
    }

    function setWalletLock(address to, LockStatus lockStatus) external {
        require(msg.sender == to, "only yourself.");
        _setWalletLock(to, lockStatus);
    }

    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(msg.sender == ownerOf(tokenIds[i]), "not owner.");
        }
        _setTokenLock(tokenIds, lockStatus);
    }

    function setEnableLock(bool value) external onlyOwner {
        enableLock = value;
    }

    //
    // IERC2981 NFT Royalty Standard
    //

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AntiScam, ERC2981, CantBeEvil) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - CantBeEvil
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId);
    }
}