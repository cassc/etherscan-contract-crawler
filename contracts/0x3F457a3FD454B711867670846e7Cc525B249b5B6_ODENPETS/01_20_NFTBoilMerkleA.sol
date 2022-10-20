// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//  ::::::::  :::::::::  :::::::::: ::::    ::: :::::::::  :::::::::: ::::::::::: ::::::::  
// :+:    :+: :+:    :+: :+:        :+:+:   :+: :+:    :+: :+:            :+:    :+:    :+: 
// +:+    +:+ +:+    +:+ +:+        :+:+:+  +:+ +:+    +:+ +:+            +:+    +:+        
// +#+    +:+ +#+    +:+ +#++:++#   +#+ +:+ +#+ +#++:++#+  +#++:++#       +#+    +#++:++#++ 
// +#+    +#+ +#+    +#+ +#+        +#+  +#+#+# +#+        +#+            +#+           +#+ 
// #+#    #+# #+#    #+# #+#        #+#   #+#+# #+#        #+#            #+#    #+#    #+# 
//  ########  #########  ########## ###    #### ###        ##########     ###     ########  

/// @title: ODENPETS
/// @author: Shunichiro
/// @dev: This contract using NFTBoil (https://github.com/syunduel/NFTBoil)


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// This NFT License is a16z Can't be Evil Lisence
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract ODENPETS is ERC721A, ERC2981 , Ownable, Pausable, CantBeEvil(LicenseVersion.CBE_NECR_HS)  {
    using Strings for uint256;

    string private baseURI = "";

    uint256 public preCost = 0.001 ether;
    uint256 public publicCost = 0.001 ether;
    bool public presale = true;
    bool public mintable = false;
    bool public publicSaleWithoutProof = false;
    uint256 public maxPerWallet = 300;
    uint256 public publicMaxPerTx = 5;

    address public royaltyAddress;
    uint96 public royaltyFee = 500;

    uint256 constant public MAX_SUPPLY = 10000;
    string constant private BASE_EXTENSION = ".json";
    address constant private DEFAULT_ROYALITY_ADDRESS = 0xA9028b1EA3A8485130eB86Dc1F26654c823D9849;
    bytes32 public merkleRootPreMint;
    bytes32 public merkleRootPublicMint;
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

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRootPreMint(bytes32 _merkleRoot) external onlyOwner {
        merkleRootPreMint = _merkleRoot;
    }

    /**
     * @notice Set the merkle root for the public mint
     */
    function setMerkleRootPublicMint(bytes32 _merkleRoot) external onlyOwner {
        merkleRootPublicMint = _merkleRoot;
    }

    function publicMint(uint256 _mintAmount, uint256 _publicMintMax, bytes32[] calldata _merkleProof) public
    payable
    whenNotPaused
    whenMintable
    callerIsUser
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(!presale, "Presale is active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _publicMintMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPublicMint, leaf),
            "Invalid Merkle Proof"
        );
        require(
            claimed[msg.sender] + _mintAmount <= _publicMintMax,
            "Already claimed max"
        );
        require(
            _mintAmount <= publicMaxPerTx,
            "Mint amount over"
        );

        _mint(msg.sender, _mintAmount);
        claimed[msg.sender] += _mintAmount;
    }

    function preMint(uint256 _mintAmount, uint256 _preMintMax, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
    {
        uint256 cost = preCost * _mintAmount;
        mintCheck(_mintAmount,  cost);
        require(presale, "Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _preMintMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPreMint, leaf),
            "Invalid Merkle Proof"
        );

        require(
            claimed[msg.sender] + _mintAmount <= _preMintMax,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
        claimed[msg.sender] += _mintAmount;
    }

    function publicMintWithoutProof(uint256 _mintAmount) public
    payable
    whenNotPaused
    whenMintable
    callerIsUser
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(!presale, "Presale is active.");
        require(publicSaleWithoutProof, "publicSaleWithoutProof is not open.");
        require(
            _mintAmount <= publicMaxPerTx,
            "Mint amount over"
        );
        require(
            claimed[msg.sender] + _mintAmount <= maxPerWallet,
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

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setPublicSaleWithoutProof(bool _state) public onlyOwner {
        publicSaleWithoutProof = _state;
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

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPublicMaxPerTx(uint256 _publicMaxPerTx) external onlyOwner {
        publicMaxPerTx = _publicMaxPerTx;
    }

    function getCurrentCost() public view returns (uint256) {
        if (presale) {
            return preCost;
        } else{
            return publicCost;
        }
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
    ) public view virtual override(ERC721A, ERC2981,CantBeEvil) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - CantBeEvil
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}