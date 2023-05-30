// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


// MEDUSA COLLECTION
// The Medusa Collection is a set of 2,500 unique NFTs by artist Mieke Marple
// The collection is a large scale artwork + restorative history + fundraiser
// that dedicates 25% of all sales to Steven Van Zandt’s national education
// non-profit TeachRock.org
// 
// Contract written by @thauber
// Contract audited by @carlfarterson

contract MedusaToken is ERC721, ERC721Enumerable, Ownable, PaymentSplitter, Pausable, VRFConsumerBase {
    using Strings for uint256;

    // Start of regular sale
    uint256 public immutable SALE_START_TIME;
    // Time after which medusas are randomized and allotted
    uint256 public immutable REVEAL_TIME;
    // a merkle tree that stores addresses with permission to mint early
    bytes32 immutable public _earlyMintersMerkleRoot;
    // Mapping to limit early minting to one NFT
    mapping (address => bool) private _earlyMinted;
    // a merkle tree that stores addresses with permission to mint for free
    bytes32 immutable public _freeMintersMerkleRoot;
    // Mapping to limit free minting to one NFT
    mapping (address => bool) private _freeMinted;

    //Chainlink
    bytes32 immutable _hashKey;
    
    //Token Counts
    uint256 public immutable _tokenCount;
    uint256 public immutable _devReserve;
    //Number of reserved tokens left
    uint256 public reservedCount;

    // Max mintable in one transaction
    uint256 public constant MAX_MINT_AMOUNT = 20;
    // Price to mint one NFT
    uint256 public constant _price = .025 ether;

    // the starting index for random allotment
    // If 0 then reveal hasn't happened yet
    uint256 public startingIndex = 0;

    constructor(
        uint256 tokenCount,
        uint256 devReserve,
        uint256 saleStartTime,
        uint256 revealTerm,
        bytes32 freeMintersMerkleRoot,
        bytes32 earlyMintersMerkleRoot,
        address vrfCoordinator,
        address linkToken,
        bytes32 hashKey,
        address[] memory members,
        uint256[] memory shares
    ) ERC721("Medusa Collection", "MDSA") PaymentSplitter(members, shares) VRFConsumerBase(vrfCoordinator, linkToken){
        require(devReserve < tokenCount, 'Medusa: can not have more dev reserve than supply');
        _tokenCount = tokenCount;
        _devReserve = devReserve;
        reservedCount = devReserve;
        SALE_START_TIME = saleStartTime;
        REVEAL_TIME = saleStartTime + revealTerm;
        _earlyMintersMerkleRoot = earlyMintersMerkleRoot;
        _freeMintersMerkleRoot = freeMintersMerkleRoot;
        _hashKey = hashKey;
        pause();
    }

    function mintNFTs(uint amount) public payable {
        require(block.timestamp >= SALE_START_TIME, 'Medusa: sale has not started');
        _payAndMintNFTs(amount);
    }

    function earlyMintNFT(bytes32[] calldata merkleProof) public payable {
        require(_earlyMinted[_msgSender()] != true, "Medusa: only one early mint per address");
        bytes32 node = keccak256(abi.encode(_msgSender()));
        require(MerkleProof.verify(merkleProof, _earlyMintersMerkleRoot, node), 'Medusa: invalid proof for early minting');
        _payAndMintNFTs(1);
        _earlyMinted[_msgSender()] = true;
    }

    function freeMintNFT(bytes32[] calldata merkleProof) public payable {
        require(_freeMinted[_msgSender()] != true, "Medusa: only one free mint per address");
        bytes32 node = keccak256(abi.encode(_msgSender()));
        require(MerkleProof.verify(merkleProof, _freeMintersMerkleRoot, node), 'Medusa: invalid proof for free minting');
        _mintNFTs(1);
        _freeMinted[_msgSender()] = true;
        if (msg.value > 0) {
            (bool success, ) = _msgSender().call{value: msg.value}("");
            require(success, "Medusa: change sent unsuccessfully");
        }
    }

    function _payAndMintNFTs(uint amount) private {
        require(_price * amount == msg.value, "Medusa: too little eth sent");
        _mintNFTs(amount);
    }

    function _mintNFTs(uint amount) private whenNotPaused {
        require(amount <= MAX_MINT_AMOUNT, 'Medusa: mint amount exceeds maximum');
        require(totalSupply() < _tokenCount - reservedCount, "Medusa: sale has sold out");
        require(totalSupply() + amount <= _tokenCount - reservedCount, "Medusa: mint exceeds available supply");
        for (uint i = 0; i < amount; i++) {
            _mintNFT(_msgSender());
        }
    }

    function devMintNFTs(address destination, uint amount) public {
        require(_msgSender() == owner(), 'Medusa: only devs can dev mint');
        require(totalSupply() < _tokenCount, "Medusa: sale has sold out");
        require(totalSupply() + amount <= _tokenCount, "Medusa: mint exceeds available supply");
        for (uint i = 0; i < amount; i++) {
            _mintNFT(destination);
        }
        reservedCount = reservedCount - amount;
    }

    function _mintNFT(address _to) private {
      uint _tokenId = totalSupply();
      _safeMint(_to, _tokenId);
    }

    function reveal() public {
        require(_msgSender() == owner(), "Medusa: only the owner can reveal");
        require(startingIndex == 0, "Medusa: already revealed");
        require(block.timestamp >= REVEAL_TIME, "Medusa: not ready to be revealed");
        requestRandomness(_hashKey, 2000000000000000000);
    }

    function fulfillRandomness(bytes32, uint256 randomNumber) internal override {
        uint256 seed = randomNumber % _tokenCount;
        if (seed!=0) startingIndex = seed;
        else startingIndex = 1;
    }

    function hasFreeMinted() public view returns (bool) {
        return _freeMinted[_msgSender()];
    }

    function hasEarlyMinted() public view returns (bool) {
        return _earlyMinted[_msgSender()];
    }


    // Pausable Overrides
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // ERC721 Overrides
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        if (startingIndex == 0) {
            return "ipfs://QmSz2wdzPuGvBq1tQ89rR1k8n8rStFckDbzBCDA1AZrEqd";
        }
        uint256 revealedId = (tokenId + startingIndex) % _tokenCount;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, revealedId.toString(), ".json")) : "";
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmV2Dy4Mbh1VT7Z1w11VDheQLhyx8oqkgh7LmpwDNGJRPK/";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice PaymentSplitter introduces a `receive()` function that we do not need.
    receive() external payable override {
        revert();
    }
}