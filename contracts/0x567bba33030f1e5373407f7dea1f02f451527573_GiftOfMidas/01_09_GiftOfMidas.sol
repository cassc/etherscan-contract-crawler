// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "@ERC721A/contracts/ERC721A.sol";
import "@ERC721A/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GiftOfMidas is ERC721A, ERC721ABurnable, Ownable {

    uint256 public constant MAX_MINT_PER_ADDRESS_PRESALE = 1;
    uint256 public constant MAX_MINT_PER_ADDRESS_PUBLIC_SALE = 20;

    mapping(address => uint256) internal preSaleUserMints;
    mapping(address => uint256) internal publicSaleUserMints;

    uint256 public preSaleMintPrice = 0.03 ether;
    uint256 public publicSaleMintPrice = 0.05 ether;

    address payable internal teamAddress;
    bytes32 internal merkleRoot;

    bool public preSaleOpen = false;
    bool public publicSaleOpen = false;

    string internal _tokenUri;

    /// Function Not open yet
    error NotOpenYet();
    /// Amount exceeds address allowance
    error AmountExceedsAllowance();
    /// msg.value too low
    error MintPayableTooLow();
    /// You are not on the whitelist
    error NotOnWhitelist();

    constructor(string memory name, string memory symbol, address _teamAddress) ERC721A(name, symbol) {
        teamAddress = payable(_teamAddress);
    }

    modifier isBelowUserAllowance(uint256 amount, mapping(address => uint256) storage userMints, uint256 maxMints) {
        if (SafeMath.add(amount, userMints[msg.sender]) > maxMints)
            revert AmountExceedsAllowance();
        _;
    }

    modifier isNotBelowMintPrice(uint256 _amount, uint256 _mintPrice) {
        if (msg.value < SafeMath.mul(_amount, _mintPrice))
            revert MintPayableTooLow();
        _;
    }

    function preSaleMint(uint256 _amount, bytes32[] calldata _merkleProof) external
    isNotBelowMintPrice(_amount, preSaleMintPrice)
    isBelowUserAllowance(_amount, preSaleUserMints, MAX_MINT_PER_ADDRESS_PRESALE)
    payable {
        if (preSaleOpen == false) revert NotOpenYet();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf) == false)
            revert NotOnWhitelist();
        safeMint(_amount, preSaleUserMints);
    }

    function publicMint(uint256 _amount) external
    isNotBelowMintPrice(_amount, publicSaleMintPrice)
    isBelowUserAllowance(_amount, publicSaleUserMints, MAX_MINT_PER_ADDRESS_PUBLIC_SALE)
    payable {
        if (publicSaleOpen == false) revert NotOpenYet();
        safeMint(_amount, publicSaleUserMints);
    }

    function safeMint(uint256 _amount, mapping(address => uint256) storage _userMints) internal
    {
        uint startId = _nextTokenId();
        _userMints[msg.sender] = SafeMath.add(_userMints[msg.sender], _amount);
        _mint(msg.sender, _amount);
        // @dev _initializeOwnershipAt every 4th token to reduce first time transfer costs
        for (uint i=startId; i < _nextTokenId(); i+=4){
            _initializeOwnershipAt(i);
        }
    }

    function withdrawFunds() external virtual onlyOwner {
        teamAddress.transfer(address(this).balance);
    }

    /**
    * views
    */

    function getPreSaleAddressRemainingMints(address _address) external view returns (uint256) {
        return MAX_MINT_PER_ADDRESS_PRESALE - preSaleUserMints[_address];
    }

    function getPublicSaleAddressRemainingMints(address _address) external view returns (uint256) {
        return MAX_MINT_PER_ADDRESS_PUBLIC_SALE - publicSaleUserMints[_address];
    }

    /**
    * Settings
    */

    function togglePreSaleOpen() external virtual onlyOwner {
        preSaleOpen = !preSaleOpen;
    }

    function togglePublicSaleOpen() external virtual onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function setURI(string memory _uri) public onlyOwner {
        _tokenUri = _uri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _tokenUri;
    }

    function setPreSaleMintPrice(uint256 _mintPrice) public onlyOwner {
        preSaleMintPrice = _mintPrice;
    }

    function setPublicSaleMintPrice(uint256 _mintPrice) public onlyOwner {
        publicSaleMintPrice = _mintPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}