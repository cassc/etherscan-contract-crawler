// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GamePass is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 5;
    uint256 public maxPresaleMintsPerWallet = 2;

    uint256 public mintPrice = 0.1 ether;

    bool public presaleIsActive = false;
    bool public saleIsActive = false;
    bool public holderOnlyMint = false;

    bool public isLocked = false;
    string public baseURI;
    string public provenance;

    address[4] private _shareholders;
    uint[4] private _shares;

    bytes32 public merkleRoot = 0x95bb47781dc6717785223071a83860ea94a8e8165f08e287bbf3178784858008;

    mapping (address => uint256) public presaleMints;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxSupply) ERC721(name, symbol) {
        maxTokenSupply = maxSupply;

        _shareholders[0] = 0x11Ab326ef535963412E252653b843Da29d572b47; // Theori wallet
        _shareholders[1] = 0xeC9e512fE7E90134d8ca7295329Ccb0a57C91ecB; // Max
        _shareholders[2] = 0xB834A304f6baccA631a12c19c2bE8140D36DA8AA; // Angel
        _shareholders[3] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure

        _shares[0] = 6400;
        _shares[1] = 1200;
        _shares[2] = 1200;
        _shares[3] = 1200;
    }

    function setMaxTokenSupply(uint256 maxSupply) external onlyOwner {
        require(!isLocked, "Locked");
        maxTokenSupply = maxSupply;
    }

    function setMaxMintsPerWallet(uint256 newPresaleLimit) external onlyOwner {
        maxPresaleMintsPerWallet = newPresaleLimit;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    /*
    * Pause holder only mint if active, make active if paused.
    */
    function flipHolderOnlyMint() external onlyOwner {
        holderOnlyMint = !holderOnlyMint;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) external onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 4; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        _mintMultiple(reservedAmount, mintAddress);
    }

    function hashLeaf(address presaleAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            presaleAddress
        ));
    }

    /*
    * Lock provenance, supply and base URI.
    */
    function lockProvenance() external onlyOwner {
        isLocked = true;
    }

    function publicMint(uint256 numTokens) external payable {
        require(saleIsActive, "Sale not live");
        require(numTokens <= MAX_MINTS_PER_TXN, "Exceeds max per txn");
        require(mintPrice * numTokens <= msg.value, "Incorrect ether value");

        if (holderOnlyMint) {
            require(balanceOf(msg.sender) > 0, "Holder only");
        }

        _mintMultiple(numTokens, msg.sender);
    }

    function presaleMint(uint256 numTokens, bytes32[] calldata merkleProof) external payable {
        require(presaleIsActive, "Presale not live");
        require(presaleMints[msg.sender] + numTokens <= maxPresaleMintsPerWallet, "Exceeds max per wallet");
        require(mintPrice * numTokens <= msg.value, "Incorrect ether value");

        // Compute the node and verify the merkle proof
        require(MerkleProof.verify(merkleProof, merkleRoot, hashLeaf(msg.sender)), "Invalid proof");

        presaleMints[msg.sender] += numTokens;

        _mintMultiple(numTokens, msg.sender);
    }

    function _mintMultiple(uint256 numTokens, address mintAddress) internal {
        require(_tokenIdCounter.current() + numTokens <= maxTokenSupply, "Exceeds max supply");

        for (uint256 i = 0; i < numTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!isLocked, "Locked");
        baseURI = newBaseURI;
    }

    /*
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        require(!isLocked, "Locked");
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}