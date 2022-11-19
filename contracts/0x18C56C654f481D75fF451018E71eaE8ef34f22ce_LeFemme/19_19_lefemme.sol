// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract LeFemme is ERC721, ERC721Enumerable, Pausable, DefaultOperatorFilterer, Ownable {
    mapping (uint256 => string) private _tokenURIs;
    using Strings for uint256;

    // ===== 1. Property Variables ===== //

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public MINT_PRICE = 0.02 ether;
    uint256 public MINT_PRICE_BUNDLE = 0.05 ether;
    uint public MAX_SUPPLY = 111;
    bool public mintStarted = false;
    string private _baseURIextended;
    mapping(bytes32 => uint256) roots;
    mapping(address => uint256) public amountMinted;

    // ===== 2. Lifecycle Methods ===== //

    constructor(bytes32[] memory _roots, uint256[] memory _amounts) ERC721("Le Femme", "LFSR") {
        // Start token ID at 1. By default is starts at 0.
        _tokenIdCounter.increment();
                for (uint256 i = 0; i < _roots.length; i++) {
            roots[_roots[i]] = _amounts[i];
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _setTokenURI(uint256 tokenId, uint version) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        string memory _tokenURI = string.concat("ipfs://bafybeicmfzj4objpny6t3qyxkugubvgbl37n4owv6lqexjll6r5nenb7qu/", Strings.toString(version), ".json");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no token URI, return the base URI.
        if (bytes(_tokenURI).length == 0) {
            return base;
        }
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function withdraw() public onlyOwner() {
        require(address(this).balance > 0, "Balance is zero");
        payable(owner()).transfer(address(this).balance);
    }

    // ===== 3. Pauseable Functions ===== //

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ===== 4. Minting Functions ===== //

    function safeMint() public payable {
        require(mintStarted == true, "The mint hasn't started yet");
        require(totalSupply() < MAX_SUPPLY, "Can't mint anymore tokens.");
        require(msg.value >= MINT_PRICE, "Not enough ether sent.");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        uint randNonce = 0;
        uint version = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 3;
        _setTokenURI(tokenId,version+1);
    }

    function safeMintBundle()
        external
        payable
    {
        require(mintStarted == true, "The mint hasn't started yet");
        require(totalSupply()+2 < MAX_SUPPLY, "Can't mint anymore bundles.");
        require(msg.value >= MINT_PRICE_BUNDLE, "Not enough ether sent.");

        uint256 startId = _tokenIdCounter.current();
        for (uint i = 0; i < 3; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, startId+i);
            _setTokenURI(startId+i,i+1);
        }
    }

    function whitelistMint(bytes32[] calldata _merkleProof, bytes32 _root) public payable {
        require(mintStarted == true, "The mint hasn't started yet");
        require(totalSupply()+2 < MAX_SUPPLY, "Can't mint anymore bundles.");
        uint256 amountToMint = roots[_root];
        require(amountMinted[msg.sender] < amountToMint, "Already minted your free bundles.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _root, leaf),"Invalid Merkle Proof.");
        uint256 startId = _tokenIdCounter.current();
        for (uint i = 0; i < 3; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, startId+i);
            _setTokenURI(startId+i,i+1);
        }
        amountMinted[msg.sender] = amountMinted[msg.sender]+1;
    }


    // ===== 5. Other Functions ===== //

    function setMerkleRoot(bytes32[] memory _roots, uint256[] memory _amounts) public onlyOwner {
        for (uint256 i = 0; i < _roots.length; i++) {
            roots[_roots[i]] = _amounts[i];
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
        onlyAllowedOperator(from)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function allowMint(bool allow) public onlyOwner {
        mintStarted = allow;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}