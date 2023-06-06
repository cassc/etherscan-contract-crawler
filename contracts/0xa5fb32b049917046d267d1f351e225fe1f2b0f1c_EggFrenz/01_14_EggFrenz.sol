// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "./LockRegistry.sol";

contract EggFrenz is LockRegistry, ERC721A {
    uint256 public constant MAX_SUPPLY = 6644;
    uint256 public constant MAX_DARCEL_MINT = 1;
    uint256 public constant MAX_ALLOWLIST_MINT = 1;
    uint256 public constant MAX_MINT = 5;
    uint256 public constant MAX_RESERVED_SUPPLY = 150;
    uint256 public constant PRICE_PER_TOKEN = 0.025 ether;

    string public baseURI = "";
    uint256 public reservedSupply = 0;

    bool public allowListMintActive = false;
    bool public darcelHolderMintActive = false;
    bool public publicMintActive = false;

    bytes32 public merkleRootDarcelHolders;
    bytes32 public merkleRootAllowList;

    mapping(address => bool) private _allowListMinted;
    mapping(address => bool) private _darcelHolderMinted;
    mapping(address => uint256) private _mintAmount;

    // constructor
    constructor() ERC721A("Egg Frenz", "EggFrenz") {}

    // owner
    function setDarcelHolderMintActive(bool value) external onlyOwner {
        darcelHolderMintActive = value;
    }

    function setAllowListMintActive(bool value) external onlyOwner {
        allowListMintActive = value;
    }

    function setPublicMintActive(bool value) external onlyOwner {
        publicMintActive = value;
    }

    function setDarcelHolderMerkleRoot(bytes32 value) external onlyOwner {
        merkleRootDarcelHolders = value;
    }

    function setAllowListMerkleRoot(bytes32 value) external onlyOwner {
        merkleRootAllowList = value;
    }

    function setBaseUri(string calldata value) external onlyOwner {
        baseURI = value;
    }

    function ownerMint(uint256 numberOfTokens) external onlyOwner
    {
        require(
            reservedSupply + numberOfTokens <= MAX_RESERVED_SUPPLY,
            "exceed max reserved supply"
        );

        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "exceed max supply"
        );

        reservedSupply += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function withdraw(address payable recipient) external onlyOwner
    {
        uint balance = address(this).balance;
        payable(recipient).transfer(balance);
    }

    // public
    function onAllowList(address claimer, bytes32[] calldata proof) public view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRootAllowList, leaf);
    }

    function onDarcelHolderList(address claimer, bytes32[] calldata proof) public view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRootDarcelHolders, leaf);
    }

    function getMintAmount(address from) public view returns (uint256)
    {
        return _mintAmount[from];
    }

    function allowListMinted(address from) public view returns (bool)
    {
        return _allowListMinted[from];
    }

    function darcelHolderMinted(address from) public view returns (bool)
    {
        return _darcelHolderMinted[from];
    }

    function darcelHolderMint(uint256 numberOfTokens, bytes32[] calldata proof) external payable
        isDarcelHolderMintActive
        ableToMint(msg.sender, numberOfTokens)
    {
        require(
            onDarcelHolderList(msg.sender, proof),
            "not in darcel holder list"
        );
        
        require(
            _darcelHolderMinted[msg.sender] == false,
            "darcel holder minted"
        );

        require(
            numberOfTokens <= MAX_DARCEL_MINT,
            "exceed max token per wallet for darcel holders"
        );

        _darcelHolderMinted[msg.sender] = true;
        _mintAmount[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function allowListMint(uint256 numberOfTokens, bytes32[] calldata proof) external payable
        isAllowListMintActive
        ableToMint(msg.sender, numberOfTokens)
    {
        require(
            onAllowList(msg.sender, proof),
            "not in allow list"
        );
        
        require(
            _allowListMinted[msg.sender] == false,
            "allow list minted"
        );

        require(
            numberOfTokens <= MAX_ALLOWLIST_MINT,
            "exceed max token per wallet for allow list"
        );

        _allowListMinted[msg.sender] = true;
        _mintAmount[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable
        isPublicMintActive
        ableToMint(msg.sender, numberOfTokens)
    {
        require(
            numberOfTokens * PRICE_PER_TOKEN == msg.value,
            "ether value sent is not correct"
        );

        _mintAmount[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // locking
    function _beforeTokenTransfers(
        address ,
        address ,
        uint256 startTokenId,
        uint256 
    ) internal view override(ERC721A) {
        require(isUnlocked(startTokenId), "Token locked");
    }

    // modifier
    modifier ableToMint(address claimer, uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "exceed max token supply"
        );

        require(
            _mintAmount[claimer] + numberOfTokens <= MAX_MINT,
            "exceed max token per wallet"
        );
        _;
    }

    modifier isDarcelHolderMintActive() {
        require(darcelHolderMintActive, "darcel holder mint is not active");
        _;
    }

    modifier isAllowListMintActive() {
        require(allowListMintActive, "allow list mint is not active");
        _;
    }

    modifier isPublicMintActive() {
        require(publicMintActive, "public mint is not active");
        _;
    }
}