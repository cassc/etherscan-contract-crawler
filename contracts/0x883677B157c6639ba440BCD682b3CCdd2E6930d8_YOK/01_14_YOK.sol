// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // solhint-disable-line

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YOK is ERC721, Ownable, ReentrancyGuard {
    // Using counters diminish gasfees consumption 👉 https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
    using Counters for Counters.Counter;

    // MerkleRoot is used in order to check the allowList
    bytes32 public merkleRoot;
    bool public isAllowListActive;

    bool public isPublicSaleActive;
    bool public reserveClaimed = false;
    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant RESERVE_SUPPLY = 294;
    uint256 public mintLimit = 5;
    uint256 public tokenPrice;
    string private _baseURIextended;
    Counters.Counter private _tokenSupply;

    constructor() ERC721("YokaiVerse", "YOK") {
    }

    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function _tokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function setMaxMintPerPerson(uint256 numberMax) public onlyOwner {
        mintLimit = numberMax;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function setAllowList(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setAllowListActive(bool isAllowListActive_) external onlyOwner {
        isAllowListActive = isAllowListActive_;
    }

    /**
     * onAllowList: Check if the 'claimer' address is present in the allow list.
     * In other words, check if a leaf with the 'claimer' value
     * is present in the stored merkle tree.
     *
     * See Open Zeppelin's 'MerkleProof' library implementation.
     */
    function onAllowList(address claimer, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function whitelistMint(bytes32[] calldata merkleProof, uint256 numberOfTokens) external payable nonReentrant {

        require(isAllowListActive, "Allow list is not active");
        require(onAllowList(msg.sender, merkleProof), "Address not in allow list");
        require(balanceOf(msg.sender) + numberOfTokens <= mintLimit, "Can't min't that much NFTs");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Bots not allowed");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, totalSupply());
        }
    }

    function reserve() external onlyOwner {
        require(!reserveClaimed, "Reserve already claimed");
        reserveClaimed = true;

        uint256 i;
        for (i = 1; i <= RESERVE_SUPPLY; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, totalSupply());
        }
    }

    function setPublicSaleActive(bool isPublicSaleActive_) external onlyOwner {
        isPublicSaleActive = isPublicSaleActive_;
    }

    function mint(uint256 numberOfTokens) external payable nonReentrant {
        require(isPublicSaleActive, "Public sale is not open yet");
        require(balanceOf(msg.sender) + numberOfTokens <= mintLimit, "Can't min't that much NFTs");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Bots not allowed");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, totalSupply());
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * Optional override for modifying the token URI before return.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, ".json")) : "";
    }

    function withdraw(address payable to) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(to, balance);
    }
}