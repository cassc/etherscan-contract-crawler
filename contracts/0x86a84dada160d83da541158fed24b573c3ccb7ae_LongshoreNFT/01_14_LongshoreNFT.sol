// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract LongshoreNFT is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1500;
    uint256 public constant PRESALE_PRICE = 0.2 ether;
    uint256 public constant PUBLIC_PRICE = 0.25 ether;

    uint256 private constant MAX_MINT_PER_PRESALE = 3;
    uint256 private constant MAX_MINT_PER_PUBLIC_TXN = 5;

    address private constant TEAM = 0xbC85137E6BAF9495fB61a5E8B465D5e11ca01930;
    address private constant LAIR_LABS = 0x28Ce9467ffa14b2c22De5D2B30b543B18D114757;

    enum MintStatus {
        CLOSED,
        PRESALE,
        PUBLIC
    }
    MintStatus public _mintStatus;
    string public _baseTokenURI = "https://longshore-nft-base.lairlabs.workers.dev/";
    address public _xmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

    bytes32 private _merkleRoot = 0x0;

    constructor() ERC721A("Longshore NFT - Chapter 2", "AL2") {}

    function mintGatekeeperBase(uint256 quantity) private view {
        require(msg.sender == tx.origin, "No minting from a contract");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Maximum supply exceeded");
    }

    modifier mintGatekeeperPresale(bytes32[] calldata merkleProof, address to, uint256 quantity) {
        require(_mintStatus == MintStatus.PRESALE, "Rainbow List minting closed");
        mintGatekeeperBase(quantity);
        require(msg.value == PRESALE_PRICE * quantity, "Incorrect payment");
        require(getPresaleStatus(merkleProof, to), "You are not on the Rainbow List");
        require(_numberMinted(to) + quantity <= MAX_MINT_PER_PRESALE, "Maximum Rainbow List mints reached");
        _;
    }

    modifier mintGatekeeperPublic(uint256 quantity) {
        require(_mintStatus == MintStatus.PUBLIC, "Public minting closed");
        mintGatekeeperBase(quantity);
        require(msg.value == PUBLIC_PRICE * quantity, "Incorrect payment");
        require(quantity > 0 && quantity <= MAX_MINT_PER_PUBLIC_TXN, "Invalid mint amount");
        _;
    }

    function mintPresaleTokens(bytes32[] calldata merkleProof, uint256 quantity) external payable mintGatekeeperPresale(merkleProof, msg.sender, quantity) {
        _mint(msg.sender, quantity);
    }

    function mintTokens(uint256 quantity) external payable mintGatekeeperPublic(quantity) {
        _mint(msg.sender, quantity);
    }

    function mintTokensXMintPresale(bytes32[] calldata merkleProof, address to, uint256 _count) external payable mintGatekeeperPresale(merkleProof, to, _count) {
        require(msg.sender == _xmintAddress, "Invalid Crossmint address");
        _mint(to, _count);
    }

    function mintTokensXMint(address to, uint256 _count) external payable mintGatekeeperPublic(_count) {
        require(msg.sender == _xmintAddress, "Invalid Crossmint address");
        _mint(to, _count);
    }

    function mintReserveTokens(address[] calldata _users, uint256 numMint) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            _mint(_users[i], numMint);
        }
    }

    function getPresaleStatus(bytes32[] calldata merkleProof, address to) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(to));
        return MerkleProof.verify(merkleProof, _merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setMintStatus(uint8 status) external onlyOwner {
        require(status <= uint8(MintStatus.PUBLIC), "Invalid status");
        _mintStatus = MintStatus(status);
    }

    function setCrossmintAddress(address xmintAddress) external onlyOwner {
        _xmintAddress = xmintAddress;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 total = address(this).balance;
        uint256 llCut = total * 6 / 100;
        Address.sendValue(payable(LAIR_LABS), llCut);
        Address.sendValue(payable(TEAM), address(this).balance);
    }
}