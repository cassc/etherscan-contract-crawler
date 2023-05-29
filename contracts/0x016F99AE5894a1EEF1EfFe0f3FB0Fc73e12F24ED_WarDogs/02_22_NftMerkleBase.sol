// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NftTrustedConsumer.sol";
import "./MerkleAllowList.sol";

/// @title base NFT project
contract NftMerkleBase is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    MerkleAllowList,
    NftTrustedConsumer,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    // Payable address can receive Ether
    address payable public payee;
    //Minting fee
    uint256 public fee = 0.085 ether;
    uint256 public presaleFee = 0.07 ether;
    uint256 constant public maxSupply = 10000;
    uint256 constant public maxBatchMint = 5;
    uint256 constant public maxPresaleBatchMint = 5;
    Counters.Counter public _tokenIdTracker;

    string internal baseURIString;
    string internal contractURIString;

    constructor(
        address payable payeeAddress_,
        string memory baseURI_,
        string memory contractURI_,
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot_
    ) ERC721(name_, symbol_) MerkleAllowList(merkleRoot_) {
        require(payeeAddress_ != address(0x0), "payeeAddress Need a valid address");
        payee = payeeAddress_;
        baseURIString = baseURI_;
        contractURIString = contractURI_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    // Used for next token as they are burnable
    function numTokens() external view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function setPayee(address payeeAddress) external onlyOwner {
        require(payeeAddress != address(0x0), "Need a valid address");
        payee = payable(payeeAddress);
    }

    function setFees(uint256 newNormalFee, uint256 newPresaleFee) external onlyOwner {
        fee = newNormalFee;
        presaleFee = newPresaleFee;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _setMerkleRoot(newMerkleRoot);
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURIString;
    }

    function contractURI() external view returns (string memory) {
        return contractURIString;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        require((bytes(baseURI).length > 0), "NftBakedMetadata: baseURI needs to be supplied");
        baseURIString = baseURI;
    }

    function withdrawFeesToPayee(uint256 transferAmount) external onlyOwner nonReentrant {
        require(transferAmount <= address(this).balance, "transferAmount must be less or equal to the balance");
        (bool success,) = payee.call{value: transferAmount}("");
        require(success, "Transfer failed.");
    }

    function adminMint(address to) external onlyOwner nonReentrant {
        require(_tokenIdTracker.current() < maxSupply, "Capped out supply of tokens to mint");
        _internalMint(to);
    }

    function bulkMint(address to, uint256 numberMinted) external payable virtual onlyPublicSale nonReentrant {
        require(numberMinted <= maxBatchMint, "numberMinted must be less than or equal to the maxBatchMinted");
        require(msg.value == (numberMinted * fee), "Payable must be the numberMinted * fee");
        require((_tokenIdTracker.current() + numberMinted) <= maxSupply, "Capped out supply of tokens to mint");
        for (uint256 i = 0; i < numberMinted; i++) {
            _internalMint(to);
        }
    }

    function bulkMintMerkle(address to, uint256 numberMinted, bytes32[] calldata proofs) external payable virtual canMint(proofs, _msgSender()) onlyAllowListSale nonReentrant {
        require(numberMinted <= maxBatchMint, "numberMinted must be less than or equal to the maxBatchMinted");
        require(msg.value == (numberMinted * presaleFee), "Payable must be the numberMinted * presaleFee");
        require((_tokenIdTracker.current() + numberMinted) <= maxSupply, "Capped out supply of tokens to mint");
        _setHasMinted(_msgSender());
        for (uint256 i = 0; i < numberMinted; i++) {
            _internalMint(to);
        }
    }

    // Create he box and dna that will be used in the unboxing
    function mint(address to) external payable virtual onlyPublicSale nonReentrant {
        require(msg.value == fee, "Payable must be the fee");
        require(_tokenIdTracker.current() <= maxSupply, "Capped out supply of tokens to mint");

        _internalMint(to);
    }

    function mintMerkle(address to, bytes32[] calldata proofs) external payable canMint(proofs, _msgSender()) onlyAllowListSale nonReentrant {
        require(msg.value == presaleFee, "Payable must be the presaleFee");
        require(_tokenIdTracker.current() <= maxSupply, "Capped out supply of tokens to mint");
        _setHasMinted(_msgSender());
        _internalMint(to);
    }

    function _internalMint(address to) internal {
        uint256 tokenId = _tokenIdTracker.current();
        _safeMint(to, tokenId);
        _tokenIdTracker.increment();
    }

    // Duplicate implementations from imported open zepplin contracts
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override(ERC721, NftTrustedConsumer)
        returns (bool)
    {
        return super._isApprovedOrOwner(spender, tokenId);
    }

    // Enable controlled access to imports
    function enableAllowList() external onlyOwner {
        _enableAllowList();
    }

    function disableAllowList() external onlyOwner {
        _disableAllowList();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addTrustedConsumer(address addr) external onlyOwner {
        _addTrustedConsumer(addr);
    }

    function removeTrustedConsumer(address addr) external onlyOwner {
        _removeTrustedConsumer(addr);
    }

}