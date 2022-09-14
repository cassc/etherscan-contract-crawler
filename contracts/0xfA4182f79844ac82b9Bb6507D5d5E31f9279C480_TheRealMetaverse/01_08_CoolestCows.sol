// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract TheRealMetaverse is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;

    uint256 public constant MAX_SUPPLY = 7200;
    
    enum MintStatus {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }
    MintStatus public mintStatus;

    uint256 private _allowlistPrice;
    uint256 private _publicPrice;

    uint256 private _maxMintPerAllowlist;
    uint256 private _maxMintPerTxn;

    bytes32 private _merkleRoot = 0x0;

    string private _baseTokenURI;

    address private _teamAddress;

    constructor() ERC721A("The Real Metaverse", "TRM") {
        _allowlistPrice = 0.08 ether;
        _publicPrice = 0.09 ether;

        _maxMintPerAllowlist = 3;
        _maxMintPerTxn = 5;

        _teamAddress = 0xbC85137E6BAF9495fB61a5E8B465D5e11ca01930;
        _baseTokenURI = "https://invisible-universe.lairlabs.workers.dev/";
    }

    function mintAllowlistTokens(bytes32[] calldata merkleProof, uint256 quantity) external payable mintGatekeeperBase(quantity) mintGatekeeperAllowlist(merkleProof, msg.sender, quantity) {
        _mint(msg.sender, quantity);
    }

    function mintTokens(uint256 quantity) external payable mintGatekeeperBase(quantity) mintGatekeeperPublic(quantity) {
        _mint(msg.sender, quantity);
    }

    modifier mintGatekeeperBase(uint256 quantity) {
        require(msg.sender == tx.origin, "No minting from a contract");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Maximum supply exceeded");
        _;
    }

    modifier mintGatekeeperAllowlist(bytes32[] calldata merkleProof, address to, uint256 quantity) {
        require(mintStatus == MintStatus.ALLOWLIST, "Allowlist minting is closed");
        require(msg.value == _allowlistPrice * quantity, "Incorrect payment");
        require(getAllowlistStatus(merkleProof, to), "You are not on the allowlist");
        require(_numberMinted(to) + quantity <= _maxMintPerAllowlist, "Maximum allowlist mints reached");
        _;
    }

    modifier mintGatekeeperPublic(uint256 quantity) {
        require(mintStatus == MintStatus.PUBLIC, "Public minting is closed");
        require(msg.value == _publicPrice * quantity, "Incorrect payment");
        require(quantity > 0 && quantity <= _maxMintPerTxn, "Invalid mint amount");
        _;
    }

    function getAllowlistStatus(bytes32[] calldata merkleProof, address to) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(to));
        return MerkleProof.verify(merkleProof, _merkleRoot, leaf);
    }

    function getAllowlistPrice() external view returns (uint256) {
        return _allowlistPrice;
    }

    function setAllowlistPrice(uint256 price) external onlyOwner {
        _allowlistPrice = price;
    }

    function getPublicPrice() external view returns (uint256) {
        return _publicPrice;
    }

    function setPublicPrice(uint256 price) external onlyOwner {
        _publicPrice = price;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setMintStatus(uint8 status) external onlyOwner {
        require(status <= uint8(MintStatus.PUBLIC), "Invalid mint status");
        mintStatus = MintStatus(status);
    }

    function mintReserveTokens(address[] calldata to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Maximum supply exceeded");
        for (uint256 i = 0; i < to.length; ++i) {
            _mint(to[i], quantity);
        }
    }

    function setTeamAddress(address teamAddress) external onlyOwner {
        _teamAddress = teamAddress;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        Address.sendValue(payable(_teamAddress), address(this).balance);
    }
}